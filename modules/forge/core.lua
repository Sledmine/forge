------------------------------------------------------------------------------
-- Forge Core
-- Sledmine
-- Core functionality for Forge
---------------------------------------------------------------------------
-- Lua libraries
local inspect = require "inspect"
local glue = require "glue"
local json = require "json"
local ini = require "lua-ini"

-- Optimizations
local sin = math.sin
local cos = math.cos
local rad = math.rad
local sqrt = math.sqrt
local abs = math.abs
local floor = math.floor
local concat = table.concat

local core = {}

-- Halo libraries
local maeth = require "maethrillian"

--- Load Forge configuration from previous files
---@param path string Path of the configuration folder
function core.loadForgeConfiguration(path)
    if (not path) then
        path = defaultConfigurationPath
    end
    local configurationFilePath = path .. "\\" .. scriptName .. ".ini"
    local configurationFile = read_file(configurationFilePath)
    if (configurationFile) then
        local loadedConfiguration = ini.decode(configurationFile)
        if (loadedConfiguration and #glue.keys(loadedConfiguration) > 0) then
            configuration = loadedConfiguration
        else
            console_out(configurationFilePath)
            console_out("Forge ini file has a wrong format or is corrupted!")
        end
    end
end

--- Load previous Forge maps
---@param path string Path of the maps folder
function core.loadForgeMaps(path)
    if (not path) then
        path = defaultMapsPath
    end
    if (not directory_exists(path)) then
        create_directory(path)
        -- return false
    end
    local mapsFiles = list_directory(path)
    local mapsList = {}
    for fileIndex, file in pairs(mapsFiles) do
        if (not file:find("\\")) then
            local splitFileName = glue.string.split(file, ".")
            local extFile = splitFileName[#splitFileName]
            -- Only load files with extension .fmap
            if (extFile == "fmap") then
                -- local mapName = string.gsub(file, ".fmap", ""):gsub("_", " ")

                local mapName = string.gsub(" " .. file:gsub(".fmap", ""):gsub("_", " "), "%W%l",
                                            string.upper):sub(2)
                glue.append(mapsList, mapName)
            end
        end
    end
    -- Dispatch state modification!
    local data = {mapsList = mapsList}
    forgeStore:dispatch({
        type = "UPDATE_MAP_LIST",
        payload = data
    })
end

-- //TODO Refactor this to use lua blam objects
--- Check if player is looking at object main frame
---@param target number
---@param sensitivity number
---@param zOffset number
---@param maximumDistance number
-- Credits to Devieth and IceCrow14
function core.playerIsAimingAt(target, sensitivity, zOffset, maximumDistance)
    -- Minimum amount for distance scaling
    local baselineSensitivity = 0.012
    local function read_vector3d(Address)
        return read_float(Address), read_float(Address + 0x4), read_float(Address + 0x8)
    end
    local mainObject = get_dynamic_player()
    local targetObject = get_object(target)
    -- Both objects must exist
    if (targetObject and mainObject) then
        local playerX, playerY, playerZ = read_vector3d(mainObject + 0xA0)
        local cameraX, cameraY, cameraZ = read_vector3d(mainObject + 0x230)
        -- Target location 2
        local targetX, targetY, targetZ = read_vector3d(targetObject + 0x5C)
        -- 3D distance
        local distance = sqrt((targetX - playerX) ^ 2 + (targetY - playerY) ^ 2 +
                                  (targetZ - playerZ) ^ 2)
        local localX = targetX - playerX
        local localY = targetY - playerY
        local localZ = (targetZ + zOffset) - playerZ
        local pointX = 1 / distance * localX
        local pointY = 1 / distance * localY
        local pointZ = 1 / distance * localZ
        local xDiff = abs(cameraX - pointX)
        local yDiff = abs(cameraY - pointY)
        local zDiff = abs(cameraZ - pointZ)
        local average = (xDiff + yDiff + zDiff) / 3
        local scaler = 0
        if distance > 10 then
            scaler = floor(distance) / 1000
        end
        local autoAim = sensitivity - scaler
        if autoAim < baselineSensitivity then
            autoAim = baselineSensitivity
        end
        if average < autoAim and distance < (maximumDistance or 15) then
            return true
        end
    end
    return false
end

-- Old internal functions for rotation calculation
local function deprecatedRotate(x, y, alpha)
    local cosAlpha = cos(rad(alpha))
    local sinAlpha = sin(rad(alpha))
    local t1 = x[1] * sinAlpha
    local t2 = x[2] * sinAlpha
    local t3 = x[3] * sinAlpha
    x[1] = x[1] * cosAlpha + y[1] * sinAlpha
    x[2] = x[2] * cosAlpha + y[2] * sinAlpha
    x[3] = x[3] * cosAlpha + y[3] * sinAlpha
    y[1] = y[1] * cosAlpha - t1
    y[2] = y[2] * cosAlpha - t2
    y[3] = y[3] * cosAlpha - t3
end

function core.deprecatedEulerToRotation(yaw, pitch, roll)
    local F = {1, 0, 0}
    local L = {0, 1, 0}
    local T = {0, 0, 1}
    deprecatedRotate(F, L, yaw)
    deprecatedRotate(F, T, pitch)
    deprecatedRotate(T, L, roll)
    return {F[1], -L[1], -T[1], -F[3], L[3], T[3]}, {
        F,
        L,
        T
    }
end

--- Covert euler into game rotation array, optional rotation matrix
---@param yaw number
---@param pitch number
---@param roll number
---@return table<number, number>, table<number, table<number, number>>
function core.eulerToRotation(yaw, pitch, roll)
    local matrix = {
        {1, 0, 0},
        {0, 1, 0},
        {0, 0, 1}
    }

    local cosRoll = cos(rad(roll))
    local sinRoll = sin(rad(roll))
    local cosYaw = cos(rad(yaw))
    local sinYaw = sin(rad(yaw))
    local cosPitch = cos(rad(pitch))
    local sinPitch = sin(rad(pitch))
    matrix[1][1] = cosRoll * cosYaw
    matrix[1][2] = sinRoll * sinPitch - cosRoll * sinYaw * cosPitch
    matrix[1][3] = cosRoll * sinYaw * sinPitch + sinRoll * cosPitch
    matrix[2][1] = sinYaw
    matrix[2][2] = cosYaw * cosPitch
    matrix[2][3] = -cosYaw * sinPitch
    matrix[3][1] = -sinRoll * cosYaw
    matrix[3][2] = sinRoll * sinYaw * cosPitch + cosRoll * sinPitch
    matrix[3][3] = -sinRoll * sinYaw * sinPitch + cosRoll * cosPitch
    local array = {
        matrix[1][1],
        matrix[2][1],
        matrix[3][1],
        matrix[1][3],
        matrix[2][3],
        matrix[3][3]
    }
    return array, matrix
end

--- Rotate object into desired angles
---@param objectId number
---@param yaw number
---@param pitch number
---@param roll number
function core.rotateObject(objectId, yaw, pitch, roll)
    local rotation = core.eulerToRotation(yaw, pitch, roll)
    local tempObject = blam.object(get_object(objectId))
    tempObject.vX = rotation[1]
    tempObject.vY = rotation[2]
    tempObject.vZ = rotation[3]
    tempObject.v2X = rotation[4]
    tempObject.v2Y = rotation[5]
    tempObject.v2Z = rotation[6]
end

--[[function core.rotatePoint(x, y, z)
end]]

--- Check if current player is using a monitor biped
---@return boolean
function core.isPlayerMonitor(playerIndex)
    local tempObject
    if (playerIndex) then
        tempObject = blam.object(get_dynamic_player(playerIndex))
    else
        tempObject = blam.object(get_dynamic_player())
    end
    if (tempObject) then
        local tempTag = blam.getTag(constants.bipeds.monitor, tagClasses.biped)
        if (tempTag and tempObject.tagId == tempTag.id) then
            return true
        end
    end
    return false
end

--- Send a request to the server throug rcon
---@return boolean success
---@return string request
function core.sendRequest(request, playerIndex)
    dprint("-> [ Sending request ]")
    dprint("Request: " .. request)
    if (server_type == "local") then
        OnRcon(request)
        return true, request
    elseif (server_type == "dedicated") then
        -- Player is connected to a server
        local fixedRequest = "rcon forge '" .. request .. "'"
        execute_script(fixedRequest)
        return true, fixedRequest
    elseif (server_type == "sapp") then
        dprint("Server request: " .. request)
        -- We want to broadcast to every player in the server
        if (not playerIndex) then
            grprint(request)
        else
            -- We are looking to send data to a specific player
            rprint(playerIndex, request)
        end
        return true, request
    end
    return false
end

--- Create a request from a request object
---@param requestTable table
function core.createRequest(requestTable)
    local instanceObject = glue.update({}, requestTable)
    local request
    if (instanceObject) then
        -- Create an object instance to avoid wrong reference asignment
        local requestType = instanceObject.requestType
        if (requestType) then
            if (requestType == constants.requests.spawnObject.requestType) then
                if (server_type == "sapp") then
                    instanceObject.remoteId = requestTable.remoteId
                end
            elseif (requestType == constants.requests.updateObject.requestType) then
                if (server_type ~= "sapp") then
                    -- Desired object id is our remote id
                    instanceObject.objectId = requestTable.remoteId
                end
            elseif (requestType == constants.requests.deleteObject.requestType) then
                if (server_type ~= "sapp") then
                    -- Desired object id is our remote id
                    instanceObject.objectId = requestTable.remoteId
                end
            end
            local requestFormat
            for requestIndex, request in pairs(constants.requests) do
                if (requestType == request.requestType) then
                    requestFormat = request.requestFormat
                end
            end
            local encodedTable = maeth.encodeTable(instanceObject, requestFormat)
            -- print(inspect(requestTable))
            request = maeth.tableToRequest(encodedTable, requestFormat, constants.requestSeparator)
        else
            -- print(inspect(instanceObject))
            error("There is no request type in this request!")
        end
        return request
    end
    return nil
end

--- Process every request as a server
function core.processRequest(actionType, request, currentRequest, playerIndex)
    dprint("-> [ Receiving request ]")
    dprint("Incoming request: " .. request)
    dprint("Parsing incoming " .. actionType .. " ...", "warning")
    local requestTable = maeth.requestToTable(request, currentRequest.requestFormat,
                                              constants.requestSeparator)
    if (requestTable) then
        dprint("Done.", "success")
        dprint(inspect(requestTable))
    else
        dprint("Error at converting request.", "error")
        return false, nil
    end
    dprint("Decoding incoming " .. actionType .. " ...", "warning")
    local requestObject = maeth.decodeTable(requestTable, currentRequest.requestFormat)
    if (requestObject) then
        dprint("Done.", "success")
    else
        dprint("Error at decoding request.", "error")
        return false, nil
    end
    if (not ftestingMode) then
        eventsStore:dispatch({
            type = actionType,
            payload = {
                requestObject = requestObject
            },
            playerIndex = playerIndex
        })
    end
    return false, requestObject
end

function core.resetSpawnPoints()
    local scenario = blam.scenario(0)

    local mapSpawnCount = scenario.spawnLocationCount
    local vehicleLocationCount = scenario.vehicleLocationCount

    dprint("Found " .. mapSpawnCount .. " stock player starting points!")
    dprint("Found " .. vehicleLocationCount .. " stock vehicle location points!")
    local mapSpawnPoints = scenario.spawnLocationList
    -- Reset any spawn point, except the first one
    for i = 1, mapSpawnCount do
        -- Disable them by setting type to 0
        mapSpawnPoints[i].type = 0
    end
    local vehicleLocationList = scenario.vehicleLocationList
    for i = 2, vehicleLocationCount do
        -- Disable spawn and try to erase object from the map
        vehicleLocationList[i].type = 65535
        execute_script("object_destroy v" .. vehicleLocationList[i].nameIndex)
    end

    scenario.spawnLocationList = mapSpawnPoints
    scenario.vehicleLocationList = vehicleLocationList
end

function core.flushForge()
    if (eventsStore) then
        local forgeObjects = eventsStore:getState().forgeObjects
        if (#glue.keys(forgeObjects) > 0 and #blam.getObjects() > 0) then
            -- saveForgeMap('unsaved')
            -- execute_script('object_destroy_all')
            for objectId, composedObject in pairs(forgeObjects) do
                delete_object(objectId)
            end
            eventsStore:dispatch({
                type = "FLUSH_FORGE"
            })
        end
    end
end

function core.sendMapData(forgeMap, playerIndex)
    if (server_type == "sapp") then
        local mapDataResponse = {}
        local response
        -- Send main map data
        mapDataResponse.requestType = constants.requests.loadMapScreen.requestType
        mapDataResponse.objectCount = #forgeMap.objects
        mapDataResponse.mapName = forgeMap.name
        response = core.createRequest(mapDataResponse)
        core.sendRequest(response, playerIndex)
        -- Send map author
        mapDataResponse = {}
        mapDataResponse.requestType = constants.requests.setMapAuthor.requestType
        mapDataResponse.mapAuthor = forgeMap.author
        response = core.createRequest(mapDataResponse)
        core.sendRequest(response, playerIndex)
        -- Send map description
        mapDataResponse = {}
        mapDataResponse.requestType = constants.requests.setMapDescription.requestType
        mapDataResponse.mapDescription = forgeMap.description
        response = core.createRequest(mapDataResponse)
        core.sendRequest(response, playerIndex)
    end
end

-- //TODO Add unit testing for this function
--- Return if the map is forge available
---@param mapName string
---@return boolean
function core.isForgeMap(mapName)
    dprint(mapName)
    dprint(map)
    return (mapName == map .. "_dev" or mapName == map .. "_beta" or mapName == map) or
               (mapName == map:gsub("_dev", ""))
end

function core.loadForgeMap(mapName)
    if (server_type == "dedicated") then
        console_out("You can not load a map while connected to a server!'")
        return false
    end
    local fmapContent = read_file(defaultMapsPath .. "\\" .. mapName .. ".fmap")
    if (fmapContent) then
        dprint("Loading forge map...")
        local forgeMap = json.decode(fmapContent)
        if (forgeMap) then
            if (not core.isForgeMap(forgeMap.map)) then
                console_out("This forge map was not made for " .. map .. "!")
                return false
            end
            -- Load data into store
            forgeStore:dispatch({
                type = "SET_MAP_DATA",
                payload = {
                    mapName = forgeMap.name,
                    mapDescription = forgeMap.description,
                    mapAuthor = forgeMap.author
                }
            })
            core.sendMapData(forgeMap)

            -- Reset all spawn points to default
            core.resetSpawnPoints()

            -- Remove menu blur after reloading server on local mode
            if (server_type == "local") then
                execute_script("menu_blur_off")
                core.flushForge()
            end

            console_out(string.format("\nLoading Forge objects for %s...", mapName))
            local time = os.clock()
            local objectsList = {}
            for objectId, forgeObject in pairs(forgeMap.objects) do
                local spawnRequest = forgeObject
                local objectTag = blam.getTag(spawnRequest.tagPath, tagClasses.scenery)
                if (objectTag and objectTag.id) then
                    spawnRequest.requestType = constants.requests.spawnObject.requestType
                    spawnRequest.tagPath = nil
                    spawnRequest.tagId = objectTag.id
                    local dispatchObject = eventsStore:dispatch(
                                               {
                            type = constants.requests.spawnObject.actionType,
                            payload = {
                                requestObject = spawnRequest
                            }
                        })
                else
                    dprint("WARNING!! Object with path '" .. spawnRequest.tagPath ..
                               "' can't be spawn...", "warning")
                end
            end
            forgeMapFinishedLoading = true
            console_out(string.format("Done, elapsed time: %.6f\n", os.clock() - time))
            dprint("Succesfully loaded '" .. mapName .. "' fmap!")

            if (server_type == "local") then
                execute_script("sv_map_reset")
            end

            return true
        else
            console_out("Error at decoding data from '" .. mapName .. "' forge map...")
            return false
        end
    else
        dprint("Error at trying to load '" .. mapName .. "' as a forge map...", "error")
        if (server_type == "sapp") then
            grprint("Error at trying to load '" .. mapName .. "' as a forge map...")
        end
    end
    return false
end

function core.saveForgeMap()
    console_out("Saving forge map...")

    local forgeState = forgeStore:getState()

    local mapName = forgeState.currentMap.name
    local mapDescription = forgeState.currentMap.description
    local mapAuthor = blam.readUnicodeString(get_player() + 0x4, true)

    -- List used to store data of every object in the forge map
    local forgeMap = {
        name = mapName,
        author = mapAuthor,
        description = mapDescription,
        version = "",
        map = map,
        objects = {}
    }

    -- Get the state of the forge objects
    local objectsState = eventsStore:getState().forgeObjects

    -- Iterate through all the forge objects
    for objectId, forgeObject in pairs(objectsState) do
        -- Get scenery tag path to keep compatibility between versions
        local tempObject = blam.object(get_object(objectId))
        local sceneryPath = blam.getTag(tempObject.tagId).path

        -- Create a copy of the composed object in the store to avoid replacing useful values
        local fmapObject = glue.update({}, forgeObject)

        -- Remove all the unimportant data
        fmapObject.objectId = nil
        fmapObject.reflectionId = nil
        fmapObject.remoteId = nil

        -- Add tag path property
        fmapObject.tagPath = sceneryPath

        -- Add forge object to list
        glue.append(forgeMap.objects, fmapObject)
    end

    -- Encode map info as json
    local fmapContent = json.encode(forgeMap)

    -- Fix map name
    mapName = string.gsub(mapName, " ", "_"):lower()

    local forgeMapPath = defaultMapsPath .. "\\" .. mapName .. ".fmap"

    local forgeMapFile = write_file(forgeMapPath, fmapContent)

    -- Check if file was created
    if (forgeMapFile) then
        console_out("Forge map " .. mapName .. " has been succesfully saved!",
                    blam.consoleColors.success)

        -- Avoid maps reload on server due to lack of a file system on the server side
        if (server_type ~= "sapp") then
            -- Reload forge maps list
            core.loadForgeMaps()
        end

    else
        dprint("ERROR!! At saving '" .. mapName .. "' as a forge map...", "error")
    end
end

--- Super function for debug printing and non self blocking spawning
---@param type string
---@param tagPath string
---@param x number
---@param y number
---@param z number
---@return number | nil objectId
function core.spawnObject(type, tagPath, x, y, z, noLog)
    if (not noLog) then
        dprint(" -> [ Object Spawning ]")
        dprint("Type:", "category")
        dprint(type)
        dprint("Tag  Path:", "category")
        dprint(tagPath)
        dprint("Position:", "category")
        local positionString = "%s: %s: %s:"
        dprint(positionString:format(x, y, z))
        dprint("Trying to spawn object...", "warning")
    end
    -- Prevent objects from phantom spawning!
    local objectId = spawn_object(type, tagPath, x, y, z)
    if (objectId) then
        local tempObject = blam.object(get_object(objectId))
        -- Force the object to render shadow
        if (configuration.forge.objectsCastShadow) then
            tempObject.isNotCastingShadow = false
        end
        -- // FIXME Object inside bsp detection is not working in SAPP, use minimumZSpawnPoint instead!
        if (server_type == "sapp") then
            -- SAPP for some reason can not detect if an object was spawned inside the map
            -- So we need to create an instance of the object and add the flag to it
            if (z < constants.minimumZSpawnPoint) then
                tempObject = blam.dumpObject(tempObject)
                tempObject.isOutSideMap = true
            end
            if (not noLog) then
                dprint("Object is outside map: " .. tostring(tempObject.isOutSideMap))
            end
        end
        if (tempObject.isOutSideMap) then
            if (not noLog) then
                dprint("-> Object: " .. objectId .. " is INSIDE map!!!", "warning")
            end

            -- Erase object to spawn it later in a safe place
            delete_object(objectId)

            -- Create new object but now in a safe place
            objectId = spawn_object(type, tagPath, x, y, constants.minimumZSpawnPoint)

            if (objectId) then
                -- Update new object position to match the original
                local tempObject = blam.object(get_object(objectId))
                tempObject.x = x
                tempObject.y = y
                tempObject.z = z

                -- Forces the object to render shadow
                if (configuration.forge.objectsCastShadow) then
                    local tempObject = blam.object(get_object(objectId))
                    tempObject.isNotCastingShadow = false
                end
            end
        end

        if (not noLog) then
            dprint("-> \"" .. tagPath .. "\" succesfully spawned!", "success")
        end
        return objectId
    end
    dprint("Error at trying to spawn object!!!!", "error")
    return nil
end

--- Apply updates for player spawn points based on a given tag path
---@param tagPath string
---@param forgeObject table
---@param disable boolean
function core.updatePlayerSpawn(tagPath, forgeObject, disable)
    local teamIndex = 0
    local gameType = 0

    -- Get spawn info from tag name
    if (tagPath:find("ctf")) then
        dprint("CTF")
        gameType = 1
    elseif (tagPath:find("slayer")) then
        if (tagPath:find("generic")) then
            dprint("SLAYER")
        else
            dprint("TEAM_SLAYER")
        end
        gameType = 2
    elseif (tagPath:find("oddball")) then
        dprint("ODDBALL")
        gameType = 3
    elseif (tagPath:find("koth")) then
        dprint("KOTH")
        gameType = 4
    elseif (tagPath:find("race")) then
        dprint("RACE")
        gameType = 5
    end

    if (tagPath:find("red")) then
        dprint("RED TEAM SPAWN")
        teamIndex = 0
    elseif (tagPath:find("blue")) then
        dprint("BLUE TEAM SPAWN")
        teamIndex = 1
    end

    -- Get scenario data
    local scenario = blam.scenario(0)

    -- Get scenario player spawn points
    local mapSpawnPoints = scenario.spawnLocationList

    -- Object is not already reflecting a spawn point
    if (not forgeObject.reflectionId) then
        for spawnId = 1, #mapSpawnPoints do
            -- If this spawn point is disabled
            if (mapSpawnPoints[spawnId].type == 0) then
                -- Replace spawn point values
                mapSpawnPoints[spawnId].x = forgeObject.x
                mapSpawnPoints[spawnId].y = forgeObject.y
                mapSpawnPoints[spawnId].z = forgeObject.z
                mapSpawnPoints[spawnId].rotation = rad(forgeObject.yaw)
                mapSpawnPoints[spawnId].teamIndex = teamIndex
                mapSpawnPoints[spawnId].type = gameType

                -- Debug spawn index
                dprint("Creating spawn replacing index: " .. spawnId, "warning")
                forgeObject.reflectionId = spawnId
                break
            end
        end
    else
        dprint("Erasing spawn with index: " .. forgeObject.reflectionId)
        if (disable) then
            -- Disable or "delete" spawn point by setting type as 0
            mapSpawnPoints[forgeObject.reflectionId].type = 0
            -- Update spawn point list
            scenario.spawnLocationList = mapSpawnPoints
            return true
        end
        -- Replace spawn point values
        mapSpawnPoints[forgeObject.reflectionId].x = forgeObject.x
        mapSpawnPoints[forgeObject.reflectionId].y = forgeObject.y
        mapSpawnPoints[forgeObject.reflectionId].z = forgeObject.z
        mapSpawnPoints[forgeObject.reflectionId].rotation = rad(forgeObject.yaw)
        dprint(mapSpawnPoints[forgeObject.reflectionId].type)
        -- Debug spawn index
        dprint("Updating spawn replacing index: " .. forgeObject.reflectionId)
    end
    -- Update spawn point list
    scenario.spawnLocationList = mapSpawnPoints
end

--- Apply updates to netgame flags spawn points based on a tag path
---@param tagPath string
---@param forgeObject table
function core.updateNetgameFlagSpawn(tagPath, forgeObject)
    -- // TODO Review if some flags use team index as "group index"!
    local teamIndex = 0
    local flagType = 0

    -- Set flag type from tag path
    --[[
        0 = ctf - flag
        1 = ctf - vehicle
        2 = oddball - ball spawn
        3 = race - track
        4 = race - vehicle
        5 = vegas - bank (?) WHAT, I WAS NOT AWARE OF THIS THING!
        6 = teleport from
        7 = teleport to
        8 = hill flag
    ]]
    if (tagPath:find("flag stand")) then
        dprint("FLAG POINT")
        flagType = 0
        -- // TODO Check if double setting team index against default value is needed!
        if (tagPath:find("red")) then
            dprint("RED TEAM FLAG")
            teamIndex = 0
        else
            dprint("BLUE TEAM FLAG")
            teamIndex = 1
        end
    elseif (tagPath:find("weapons")) then
        -- // TODO Check and add weapon based netgame flags like oddball!
    end

    -- Get scenario data
    local scenario = blam.scenario(0)

    -- Get scenario player spawn points
    local mapNetgameFlagsPoints = scenario.netgameFlagsList

    -- Object is not already reflecting a flag point
    if (not forgeObject.reflectionId) then
        for flagId = 1, #mapNetgameFlagsPoints do
            -- // FIXME This control block is not neccessary but needs improvements!
            -- If this flag point is using the same flag type
            if (mapNetgameFlagsPoints[flagId].type == flagType and
                mapNetgameFlagsPoints[flagId].teamIndex == teamIndex) then
                -- Replace spawn point values
                mapNetgameFlagsPoints[flagId].x = forgeObject.x
                mapNetgameFlagsPoints[flagId].y = forgeObject.y
                -- Z plus an offset to prevent flag from falling in lower bsp values
                mapNetgameFlagsPoints[flagId].z = forgeObject.z + 0.15
                mapNetgameFlagsPoints[flagId].rotation = rad(forgeObject.yaw)
                mapNetgameFlagsPoints[flagId].teamIndex = teamIndex
                mapNetgameFlagsPoints[flagId].type = flagType

                -- Debug spawn index
                dprint("Creating flag replacing index: " .. flagId, "warning")
                forgeObject.reflectionId = flagId
                break
            end
        end
    else
        dprint("Erasing netgame flag with index: " .. forgeObject.reflectionId)
        -- Replace spawn point values
        mapNetgameFlagsPoints[forgeObject.reflectionId].x = forgeObject.x
        mapNetgameFlagsPoints[forgeObject.reflectionId].y = forgeObject.y
        mapNetgameFlagsPoints[forgeObject.reflectionId].z = forgeObject.z
        mapNetgameFlagsPoints[forgeObject.reflectionId].rotation = rad(forgeObject.yaw)
        -- Debug spawn index
        dprint("Updating flag replacing index: " .. forgeObject.reflectionId, "warning")
    end
    -- Update spawn point list
    scenario.netgameFlagsList = mapNetgameFlagsPoints
end

--- Apply updates to equipment netgame points based on a given tag path
---@param tagPath string
---@param forgeObject table
---@param disable boolean
function core.updateNetgameEquipmentSpawn(tagPath, forgeObject, disable)
    local itemCollectionTagId
    local tagSplitPath = glue.string.split(tagPath, "\\")
    local desiredWeapon = tagSplitPath[#tagSplitPath]:gsub(" spawn", "")
    dprint(desiredWeapon)
    -- Get equipment info from tag name
    if (desiredWeapon) then
        local itcTagPath, itcTagIndex, itcTagId = core.findTag(desiredWeapon,
                                                               tagClasses.itemCollection)
        itemCollectionTagId = itcTagId
    end
    if (not itemCollectionTagId) then
        -- // TODO This needs more review
        error("Could not find item collection tag id for desired weapon spawn: " .. tagPath)
        return false
    end

    -- Get scenario data
    local scenario = blam.scenario(0)

    -- Get scenario player spawn points
    local netgameEquipmentPoints = scenario.netgameEquipmentList

    -- Object is not already reflecting a spawn point
    if (not forgeObject.reflectionId) then
        for equipmentId = 1, #netgameEquipmentPoints do
            -- If this spawn point is disabled
            if (netgameEquipmentPoints[equipmentId].type1 == 0) then
                -- Replace spawn point values
                netgameEquipmentPoints[equipmentId].x = forgeObject.x
                netgameEquipmentPoints[equipmentId].y = forgeObject.y
                netgameEquipmentPoints[equipmentId].z = forgeObject.z + 0.2
                netgameEquipmentPoints[equipmentId].facing = rad(forgeObject.yaw)
                netgameEquipmentPoints[equipmentId].type1 = 12
                netgameEquipmentPoints[equipmentId].levitate = true
                netgameEquipmentPoints[equipmentId].itemCollection = itemCollectionTagId

                -- Debug spawn index
                dprint("Creating equipment replacing index: " .. equipmentId, "warning")
                forgeObject.reflectionId = equipmentId
                break
            end
        end
    else
        dprint("Erasing netgame equipment with index: " .. forgeObject.reflectionId)
        if (disable) then
            -- // FIXME Weapon object is not being erased in fact, find a way to delete it!
            -- Disable or "delete" equipment point by setting type as 0
            netgameEquipmentPoints[forgeObject.reflectionId].type1 = 0
            -- Update spawn point list
            scenario.netgameEquipmentList = netgameEquipmentPoints
            return true
        end
        -- Replace spawn point values
        netgameEquipmentPoints[forgeObject.reflectionId].x = forgeObject.x
        netgameEquipmentPoints[forgeObject.reflectionId].y = forgeObject.y
        netgameEquipmentPoints[forgeObject.reflectionId].z = forgeObject.z + 0.2
        netgameEquipmentPoints[forgeObject.reflectionId].facing = rad(forgeObject.yaw)
        -- Debug spawn index
        dprint("Updating equipment replacing index: " .. forgeObject.reflectionId)
    end
    -- Update equipment point list
    scenario.netgameEquipmentList = netgameEquipmentPoints
end

--- Enable, update and disable vehicle spawns
-- Must be called after adding scenery object to the store!!
---@return true if found an available spawn
function core.updateVehicleSpawn(tagPath, forgeObject, disable)
    if (server_type == "dedicated") then
        return true
    end
    local vehicleType = 0
    -- Get spawn info from tag name
    if (tagPath:find("banshee")) then
        dprint("banshee")
        vehicleType = 0
    elseif (tagPath:find("rocket warthog")) then
        dprint("rocket warthog")
        vehicleType = 5
    elseif (tagPath:find("warthog")) then
        dprint("normal warthog")
        vehicleType = 1
    elseif (tagPath:find("ghost")) then
        dprint("ghost")
        vehicleType = 2
    elseif (tagPath:find("scorpion")) then
        dprint("scorpion")
        vehicleType = 3
    elseif (tagPath:find("turret spawn")) then
        dprint("turret")
        vehicleType = 4
    end

    -- Get scenario data
    local scenario = blam.scenario(0)

    local vehicleLocationCount = scenario.vehicleLocationCount
    dprint("Maximum count of vehicle spawn points: " .. vehicleLocationCount)

    local vehicleSpawnPoints = scenario.vehicleLocationList

    -- Object exists, it's synced
    if (not forgeObject.reflectionId) then
        for spawnId = 2, #vehicleSpawnPoints do
            if (vehicleSpawnPoints[spawnId].type == 65535) then
                -- Replace spawn point values
                vehicleSpawnPoints[spawnId].x = forgeObject.x
                vehicleSpawnPoints[spawnId].y = forgeObject.y
                vehicleSpawnPoints[spawnId].z = forgeObject.z
                vehicleSpawnPoints[spawnId].yaw = rad(forgeObject.yaw)
                vehicleSpawnPoints[spawnId].pitch = rad(forgeObject.pitch)
                vehicleSpawnPoints[spawnId].roll = rad(forgeObject.roll)

                vehicleSpawnPoints[spawnId].type = vehicleType

                -- Debug spawn index
                dprint("Creating spawn replacing index: " .. spawnId)
                forgeObject.reflectionId = spawnId

                -- Update spawn point list
                scenario.vehicleLocationList = vehicleSpawnPoints

                dprint("object_create_anew v" .. vehicleSpawnPoints[spawnId].nameIndex)
                execute_script("object_create_anew v" .. vehicleSpawnPoints[spawnId].nameIndex)
                -- Stop looking for "available" spawn slots
                break
            end
        end
    else
        dprint(forgeObject.reflectionId)
        if (disable) then
            -- Disable or "delete" spawn point by setting type as 65535
            vehicleSpawnPoints[forgeObject.reflectionId].type = 65535
            -- Update spawn point list
            scenario.vehicleLocationList = vehicleSpawnPoints
            dprint("object_create_anew v" .. vehicleSpawnPoints[forgeObject.reflectionId].nameIndex)
            execute_script("object_destroy v" ..
                               vehicleSpawnPoints[forgeObject.reflectionId].nameIndex)
            return true
        end
        -- Replace spawn point values
        vehicleSpawnPoints[forgeObject.reflectionId].x = forgeObject.x
        vehicleSpawnPoints[forgeObject.reflectionId].y = forgeObject.y
        vehicleSpawnPoints[forgeObject.reflectionId].z = forgeObject.z

        -- REMINDER!!! Check vehicle rotation

        -- Debug spawn index
        dprint("Updating spawn replacing index: " .. forgeObject.reflectionId)

        -- Update spawn point list
        scenario.vehicleLocationList = vehicleSpawnPoints
    end
end

--- Find local object by server remote object id
---@param objects table
---@param remoteId number
---@return number
function core.getObjectIndexByRemoteId(objects, remoteId)
    for objectIndex, composedObject in pairs(objects) do
        if (composedObject.remoteId == remoteId) then
            return objectIndex
        end
    end
    return nil
end

--- Calculate distance between 2 objects
---@param baseObject table
---@param targetObject table
---@return number
function core.calculateDistanceFromObject(baseObject, targetObject)
    local calculatedX = (targetObject.x - baseObject.x) ^ 2
    local calculatedY = (targetObject.y - baseObject.y) ^ 2
    local calculatedZ = (targetObject.z - baseObject.z) ^ 2
    return sqrt(calculatedX + calculatedY + calculatedZ)
end

--- Find the path, index and id of a tag given partial name and tag type
---@param partialName string
---@param searchTagType string
function core.findTag(partialName, searchTagType)
    for tagIndex = 0, blam.tagDataHeader.count - 1 do
        local tempTag = blam.getTag(tagIndex)
        if (tempTag and tempTag.path:find(partialName) and tempTag.class == searchTagType) then
            return tempTag.path, tempTag.index, tempTag.id
        end
    end
    return nil
end

--- Get index value from an id value type
---@param id number
---@return number index
function core.getIndexById(id)
    local hex = glue.string.tohex(id)
    local bytes = {}
    for i = 5, #hex, 2 do
        glue.append(bytes, hex:sub(i, i + 1))
    end
    return tonumber(concat(bytes, ""), 16)
end

local function createSelector()
    local player = blam.biped(get_dynamic_player())
    if (player) then
        local selector = {
            x = player.x + player.xVel + player.cameraX * constants.forgeSelectorOffset,
            y = player.y + player.yVel + player.cameraY * constants.forgeSelectorOffset,
            z = player.z + player.zVel + player.cameraZ * constants.forgeSelectorOffset
        }
        local projectileId = core.spawnObject(tagClasses.projectile, constants.forgeProjectilePath,
                                              selector.x, selector.y, selector.z, true)
        if (projectileId) then
            local projectile = blam.projectile(get_object(projectileId))
            if (projectile) then
                projectile.xVel = player.cameraX * constants.forgeSelectorVelocity
                projectile.yVel = player.cameraY * constants.forgeSelectorVelocity
                projectile.zVel = player.cameraZ * constants.forgeSelectorVelocity
                projectile.yaw = player.cameraX * constants.forgeSelectorVelocity
                projectile.pitch = player.cameraY * constants.forgeSelectorVelocity
                projectile.roll = player.cameraZ * constants.forgeSelectorVelocity
            end
        end
    end
end

--- Return data about object that the player is looking at
---@return number, forgeObject, projectile
function core.getPlayerAimingObject()
    local forgeObjects = eventsStore:getState().forgeObjects
    for _, objectIndex in pairs(blam.getObjects()) do
        local projectile = blam.projectile(get_object(objectIndex))
        local forgeObject
        local selectedObjIndex
        if (projectile and projectile.type == objectClasses.projectile) then
            local projectileTag = blam.getTag(projectile.tagId)
            if (projectileTag and projectileTag.index == constants.forgeProjectileTagIndex) then
                if (projectile.attachedToObjectId) then
                    local selectedObject = blam.object(get_object(projectile.attachedToObjectId))
                    selectedObjIndex = core.getIndexById(projectile.attachedToObjectId)
                    forgeObject = forgeObjects[selectedObjIndex]
                    if (forgeObject and selectedObject) then
                        -- Player is looking at this object
                        delete_object(objectIndex)
                        createSelector()
                        return selectedObjIndex, forgeObject, blam.dumpObject(projectile) or nil
                    end
                end
                delete_object(objectIndex)
                return nil, nil, blam.dumpObject(projectile) or nil
            end
        elseif (forgeObjects[objectIndex]) then
            if (core.playerIsAimingAt(objectIndex, 0.0001, 0)) then
                return objectIndex, forgeObjects[objectIndex], blam.dumpObject(projectile) or nil
            end
        end
    end
    createSelector()
end

--- Return data about object that the player is looking at
---@param object blamObject
---@return boolean
function core.isObjectOutOfBounds(object)
    if (object) then
        local projectileId = spawn_object(tagClasses.projectile, constants.forgeProjectilePath,
                                          object.x, object.y, object.z)
        if (projectileId) then
            local blamObject = blam.object(get_object(projectileId))
            if (blamObject) then
                local isObjectOutOfBounds = blamObject.isOutSideMap
                delete_object(projectileId)
                return isObjectOutOfBounds
            end
        end
    end
end

--[[function core.getPlayerFragGrenade()
    for objectNumber, objectIndex in pairs(blam.getObjects()) do
        local projectile = blam.projectile(get_object(objectIndex))
        local selectedObjIndex
        if (projectile and projectile.type == objectClasses.projectile) then
            local projectileTag = blam.getTag(projectile.tagId)
            if (projectileTag and projectileTag.index == constants.fragGrenadeProjectileTagIndex) then
                local player = blam.biped(get_dynamic_player())
                if (projectile.armingTimer > 1) then
                    player.x = projectile.x
                    player.y = projectile.y
                    player.z = projectile.z
                    delete_object(objectIndex)
                end
            end
        end
    end
end]]

return core

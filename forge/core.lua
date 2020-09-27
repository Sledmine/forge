------------------------------------------------------------------------------
-- Forge Core
-- Sledmine
-- Core functionality for Forge
------------------------------------------------------------------------------
-- Lua libraries
local inspect = require "inspect"
local json = require "json"
local glue = require "glue"

-- Halo libraries
local maeth = require "maethrillian"

-- Core module
local core = {}

--- Check if player is looking at object main frame
---@param target number
---@param sensitivity number
---@param zOffset number
-- Credits to Devieth and IceCrow14
function core.playerIsLookingAt(target, sensitivity, zOffset)
    -- Minimum amount for distance scaling
    local baseline_sensitivity = 0.012
    local function read_vector3d(Address)
        return read_float(Address), read_float(Address + 0x4), read_float(Address + 0x8)
    end
    local mainObject = get_dynamic_player()
    local targetObject = get_object(target)
    -- Both objects must exist
    if targetObject and mainObject then
        local player_x, player_y, player_z = read_vector3d(mainObject + 0xA0)
        local camera_x, camera_y, camera_z = read_vector3d(mainObject + 0x230)
        -- Target location 2
        local target_x, target_y, target_z = read_vector3d(targetObject + 0x5C)
        -- 3D distance
        local distance = math.sqrt((target_x - player_x) ^ 2 + (target_y - player_y) ^ 2 +
                                       (target_z - player_z) ^ 2)
        local local_x = target_x - player_x
        local local_y = target_y - player_y
        local local_z = (target_z + zOffset) - player_z
        local point_x = 1 / distance * local_x
        local point_y = 1 / distance * local_y
        local point_z = 1 / distance * local_z
        local x_diff = math.abs(camera_x - point_x)
        local y_diff = math.abs(camera_y - point_y)
        local z_diff = math.abs(camera_z - point_z)
        local average = (x_diff + y_diff + z_diff) / 3
        local scaler = 0
        if distance > 10 then
            scaler = math.floor(distance) / 1000
        end
        local auto_aim = sensitivity - scaler
        if auto_aim < baseline_sensitivity then
            auto_aim = baseline_sensitivity
        end
        if average < auto_aim then
            return true
        end
    end
    return false
end

-- Old internal functions for rotation calculation
--[[
local function rotate(x, y, alpha)
    local cosAlpha = math.cos(math.rad(alpha))
    local sinAlpha = math.sin(math.rad(alpha))
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

function core.eulerToMatrix(yaw, pitch, roll)
    local F = {1, 0, 0}
    local L = {0, 1, 0}
    local T = {0, 0, 1}
    rotate(F, L, yaw)
    rotate(F, T, pitch)
    rotate(T, L, roll)
    return {F[1], -L[1], -T[1], -F[3], L[3], T[3]}, {
        F,
        L,
        T,
    }
end
]]

--- Covert euler into game rotation array, optional rotation matrix
---@param yaw number
---@param pitch number
---@param roll number
---@return table, table
function core.eulerToRotation(yaw, pitch, roll)
    local matrix = {
        {1, 0, 0},
        {0, 1, 0},
        {0, 0, 1}
    }

    local cosRoll = math.cos(math.rad(roll))
    local sinRoll = math.sin(math.rad(roll))
    local cosYaw = math.cos(math.rad(yaw))
    local sinYaw = math.sin(math.rad(yaw))
    local cosPitch = math.cos(math.rad(pitch))
    local sinPitch = math.sin(math.rad(pitch))
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

--- Rotate object into desired degrees
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
        local monitorBipedTagId = get_tag_id(tagClasses.biped, constants.bipeds.monitor)
        if (tempObject.tagId == monitorBipedTagId) then
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
    local requestType = glue.string.split(request, "|")[1]
    dprint("Request type: " .. requestType)
    if (requestType) then
        request = "rcon forge '" .. request .. "'"
        dprint("Request: " .. request)
        if (server_type == "local") then
            -- We need to mockup the server response in local mode
            local mockedResponse = string.gsub(string.gsub(request, "rcon forge '", ""), "'", "")
            OnRcon(mockedResponse)
            return true, mockedResponse
        elseif (server_type == "dedicated") then
            -- Player is connected to a server
            execute_script(request)
            return true, request
        elseif (server_type == "sapp") then
            local fixedRequest = string.gsub(request, "rcon forge '", "")
            dprint("Server request: " .. fixedRequest)
            -- We want to broadcast to every player in the server
            if (not playerIndex) then
                gprint(fixedRequest)
            else
                -- We are looking to send data to a specific player
                rprint(playerIndex, fixedRequest)
            end
            return true, fixedRequest
        end
    end
    dprint("Error at trying to send request!!!!", "error")
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
            print(inspect(requestTable))
            request = maeth.tableToRequest(encodedTable, requestFormat, "|")
        else
            print(inspect(instanceObject))
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
    local requestTable = maeth.requestToTable(request, currentRequest.requestFormat, "|")
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
        if (#glue.keys(forgeObjects) > 0 and #get_objects() > 0) then
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

--- Return if the map is forge available
---@param mapName string
---@return boolean
function core.isForgeMap(mapName)
    return mapName == map .. "_dev" or mapName == map .. "_beta" or mapName == map
end

function core.loadForgeMap(mapName)
    if (server_type == "dedicated") then
        console_out("You can not load a map while connected to a server!'")
        return false
    end
    local fmapContent = glue.readfile(forgeMapsFolder .. "\\" .. mapName .. ".fmap", "t")
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

            for objectId, forgeObject in pairs(forgeMap.objects) do
                local spawnRequest = glue.update({}, forgeObject)
                local objectTagId = get_tag_id(tagClasses.scenery, spawnRequest.tagPath)
                if (objectTagId) then
                    spawnRequest.requestType = constants.requests.spawnObject.requestType
                    spawnRequest.tagPath = nil
                    spawnRequest.tagId = objectTagId
                    eventsStore:dispatch({
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

            if (server_type == "local") then
                execute_script("sv_map_reset")
            end
            dprint("Succesfully loaded '" .. mapName .. "' fmap!")

            return true
        else
            console_out("Error at decoding data from '" .. mapName .. "' forge map...")
            return false
        end
    else
        dprint("ERROR!! At trying to load '" .. mapName .. "' as a forge map...", "error")
        if (server_type == "sapp") then
            gprint("ERROR!! At trying to load '" .. mapName .. "' as a forge map...")
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
        local sceneryPath = get_tag_path(tempObject.tagId)

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
    mapName = string.gsub(mapName, " ", "_")

    local forgeMapPath = forgeMapsFolder .. "\\" .. mapName .. ".fmap"
    local forgeMapFile = glue.writefile(forgeMapPath, fmapContent, "t")

    -- Check if file was created
    if (forgeMapFile) then
        console_out("Forge map " .. mapName .. " has been succesfully saved!",
                    blam.consoleColors.success)

        -- Reload forge maps list
        loadForgeMaps()

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
function core.spawnObject(type, tagPath, x, y, z)
    dprint(" -> [ Object Spawning ]")
    dprint("Type:", "category")
    dprint(type)
    dprint("Tag  Path:", "category")
    dprint(tagPath)
    dprint("Position:", "category")
    local positionString = "%s: %s: %s:"
    dprint(positionString:format(x, y, z))
    dprint("Trying to spawn object...", "warning")
    -- Prevent objects from phantom spawning!
    local objectId = spawn_object(type, tagPath, x, y, z)
    if (objectId) then
        local tempObject = blam.object(get_object(objectId))
        -- Force the object to render shadow
        if (configuration.objectsCastShadow) then
            tempObject.isNotCastingShadow = false
        end
        -- // FIXME Object inside bsp detection is not working in SAPP, use minimumZSpawnPoint instead!
        if (server_type == "sapp") then
            print("Object is outside map: " .. tostring(tempObject.isOutSideMap))
        end
        if (tempObject.isOutSideMap) then
            dprint("-> Object: " .. objectId .. " is INSIDE map!!!", "warning")

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
                if (configuration.objectsCastShadow) then
                    local tempObject = blam.object(get_object(objectId))
                    tempObject.isNotCastingShadow = false
                end
            end
        end

        dprint("-> Object: " .. objectId .. " succesfully spawned!!!", "success")
        return objectId
    end
    dprint("Error at trying to spawn object!!!!", "error")
    return nil
end

--- Apply updates to player spawn points based on a given tag path
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
                mapSpawnPoints[spawnId].rotation = math.rad(forgeObject.yaw)
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
        mapSpawnPoints[forgeObject.reflectionId].rotation = math.rad(forgeObject.yaw)
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
                mapNetgameFlagsPoints[flagId].rotation = math.rad(forgeObject.yaw)
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
        mapNetgameFlagsPoints[forgeObject.reflectionId].rotation = math.rad(forgeObject.yaw)
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
    local itemCollection
    -- Get equipment info from tag name
    if (tagPath:find("assault rifle")) then
        dprint("AR")
        local itemCollectionTagPath = core.findTag("assault rifle", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("battle rifle")) then
        dprint("BR")
        local itemCollectionTagPath = core.findTag("battle rifle", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("dmr")) then
        dprint("DMR")
        local itemCollectionTagPath = core.findTag("dmr", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("needler")) then
        dprint("DMR")
        local itemCollectionTagPath = core.findTag("needler", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("plasma pistol")) then
        dprint("DMR")
        local itemCollectionTagPath = core.findTag("plasma pistol", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("rocket launcher")) then
        dprint("DMR")
        local itemCollectionTagPath = core.findTag("rocket launcher", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("shotgun")) then
        dprint("DMR")
        local itemCollectionTagPath = core.findTag("shotgun", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("sniper rifle")) then
        dprint("DMR")
        local itemCollectionTagPath = core.findTag("sniper rifle", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("frag grenade")) then
        dprint("FRAG GRENADE")
        local itemCollectionTagPath = core.findTag("frag grenades", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("plasma grenade")) then
        dprint("PLASMA GRENADE")
        local itemCollectionTagPath = core.findTag("plasma grenades", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("random weapon spawn")) then
        dprint("RANDOM WEAPON")
        local itemCollectionTagPath = core.findTag("random weapon", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
    elseif (tagPath:find("gravity hammer spawn")) then
        dprint("GRAVITY HAMMER")
        local itemCollectionTagPath = core.findTag("gravity hammer", tagClasses.itemCollection)
        dprint(itemCollectionTagPath)
        itemCollection = get_tag_id(tagClasses.itemCollection, itemCollectionTagPath)
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
                netgameEquipmentPoints[equipmentId].facing = math.rad(forgeObject.yaw)
                netgameEquipmentPoints[equipmentId].type1 = 12
                netgameEquipmentPoints[equipmentId].levitate = true
                netgameEquipmentPoints[equipmentId].itemCollection = itemCollection

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
        netgameEquipmentPoints[forgeObject.reflectionId].facing = math.rad(forgeObject.yaw)
        -- Debug spawn index
        dprint("Updating equipment replacing index: " .. forgeObject.reflectionId)
    end
    -- Update equipment point list
    scenario.netgameEquipmentList = netgameEquipmentPoints
end

--- Enable, update and disable vehicle spawns
-- Must be called after adding scenery object to the store!!
-- @return true if found an available spawn
function core.updateVehicleSpawn(tagPath, forgeObject, disable)
    if (server_type == "dedicated") then
        return true
    end
    local vehicleType = 0
    -- Get spawn info from tag name
    if (tagPath:find("banshee")) then
        dprint("banshee")
        vehicleType = 0
    elseif (tagPath:find("hog")) then
        dprint("hog")
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
    elseif (tagPath:find("ball spawn")) then
        dprint("ball")
        vehicleType = 5
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
                vehicleSpawnPoints[spawnId].yaw = math.rad(forgeObject.yaw)
                vehicleSpawnPoints[spawnId].pitch = math.rad(forgeObject.pitch)
                vehicleSpawnPoints[spawnId].roll = math.rad(forgeObject.roll)

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

--- Find local object by server id
---@param state table
---@param remoteId number
---@return number
function core.getObjectIdByRemoteId(state, remoteId)
    for k, v in pairs(state) do
        if (v.remoteId == remoteId) then
            return k
        end
    end
    return nil
end

--- Calculate distance between 2 objects
---@param baseObject table
---@param targetObject table
---@return number
function core.calculateDistanceFromObject(baseObject, targetObject)
    local calulcatedX = (targetObject.x - baseObject.x) ^ 2
    local calculatedY = (targetObject.y - baseObject.y) ^ 2
    local calculatedZ = (targetObject.z - baseObject.z) ^ 2
    return math.sqrt(calulcatedX + calculatedY + calculatedZ)
end

function core.findTag(partialName, searchTagType)
    for tagId = 0, get_tags_count() - 1 do
        local tagPath = get_tag_path(tagId)
        local tagType = get_tag_type(tagId)
        if (tagPath and tagPath:find(partialName) and tagType == searchTagType) then
            return tagPath, tagId
        end
    end
    return nil
end

return core

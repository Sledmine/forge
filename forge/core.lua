------------------------------------------------------------------------------
-- Forge Core
-- Author: Sledmine
-- Version: 2.0
-- Core functionality for Forge
------------------------------------------------------------------------------
-- Lua libraries
local inspect = require "inspect"
local json = require "json"
local glue = require "glue"

-- Halo libraries
local maeth = require "maethrillian"

-- Forge modules
local features = require "forge.features"
local constants = require "forge.constants"

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
    local cosPitch = math.cos(math.rad(pitch))
    local sinPitch = math.sin(math.rad(pitch))
    local cosYaw = math.cos(math.rad(yaw))
    local sinYaw = math.sin(math.rad(yaw))
    local cosRoll = math.cos(math.rad(roll))
    local sinRoll = math.sin(math.rad(roll))
    matrix[1][1] = cosPitch * cosYaw
    matrix[1][2] = sinPitch * sinRoll - cosPitch * sinYaw * cosRoll
    matrix[1][3] = cosPitch * sinYaw * sinRoll + sinPitch * cosRoll
    matrix[2][1] = sinYaw
    matrix[2][2] = cosYaw * cosRoll
    matrix[2][3] = -cosYaw * sinRoll
    matrix[3][1] = -sinPitch * cosYaw
    matrix[3][2] = sinPitch * sinYaw * cosRoll + cosPitch * sinRoll
    matrix[3][3] = -sinPitch * sinYaw * sinRoll + cosPitch * cosRoll
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
    blam.object(get_object(objectId), {
        vX = rotation[1],
        vY = rotation[2],
        vZ = rotation[3],
        v2X = rotation[4],
        v2Y = rotation[5],
        v2Z = rotation[6]
    })
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
    local requestType = glue.string.split(request, ";")[1]
    dprint("Request type: " .. requestType)
    if (requestType) then
        request = "rcon forge '" .. request .. "'"

        dprint("Request: " .. request)
        if (server_type == "local") then
            -- We need to mockup the server response in local mode
            local mockedResponse = string.gsub(string.gsub(request, "rcon forge '", ""), "'", "")
            dprint("Local Request: " .. mockedResponse)
            OnRcon(mockedResponse)
            return true, mockedResponse
        elseif (server_type == "dedicated") then
            -- Player is connected to a server
            dprint("Dedicated Request: " .. request)
            execute_script(request)
            return true, request
        elseif (server_type == "sapp") then
            local fixedRequest = string.gsub(request, "rcon forge '", "")
            dprint("Server Request: " .. fixedRequest)

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
    if (instanceObject) then
        -- Create an object instance to avoid wrong reference asignment
        local requestType = instanceObject.requestType
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
        local request = maeth.tableToRequest(encodedTable, requestFormat)
        return request
    end
    return nil
end

function core.resetSpawnPoints()
    local scenarioAddress
    if (server_type ~= "sapp") then
        scenarioAddress = get_tag(0)
    else
        scenarioAddress = get_tag("scnr", constants.scenarioPath)
    end
    local scenario = blam.scenario(scenarioAddress)

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
        vehicleLocationList[i].type = 65535
        execute_script("object_destroy v" .. vehicleLocationList[i].nameIndex)
    end
    blam.scenario(scenarioAddress, {
        spawnLocationList = mapSpawnPoints,
        vehicleLocationList = vehicleLocationList
    })
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
                type = constants.actionTypes.FLUSH_FORGE
            })
        end
    end
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
        if (forgeMap and forgeMap.objects and #forgeMap.objects > 0) then
            forgeStore:dispatch({
                type = "SET_MAP_DATA",
                payload = {
                    mapName = forgeMap.name,
                    mapDescription = forgeMap.description
                }
            })
            if (server_type == "sapp") then
                local tempObject = {}
                tempObject.objectCount = #forgeMap.objects
                tempObject.mapName = forgeMap.name
                tempObject.mapDescription = forgeMap.description
                local response = core.createRequest(tempObject,
                                                    constants.requestTypes.LOAD_MAP_SCREEN)
                core.sendRequest(response)
            end

            -- Reset all spawn points to default
            core.resetSpawnPoints()

            -- Remove menu blur after reloading server on local mode
            if (server_type == "local") then
                execute_script("menu_blur_off")
                core.flushForge()
            end

            for objectId, forgeObject in pairs(forgeMap.objects) do
                local objectTagId = get_tag_id(tagClasses.scenery, forgeObject.tagPath)
                if (objectTagId) then
                    forgeObject.tagPath = nil
                    forgeObject.tagId = objectTagId
                    eventsStore:dispatch({
                        type = constants.requests.spawnObject.actionType,
                        payload = {
                            requestObject = forgeObject
                        }
                    })
                else
                    dprint("WARNING!! Object with path '" .. forgeObject.tagPath ..
                               "' can't be spawn...", "warning")
                end
            end

            if (server_type == "local") then
                execute_script("sv_map_reset")
            end
            dprint("Succesfully loaded '" .. mapName .. "' fmap!")

            return true
        else
            dprint("ERROR!! At decoding data from '" .. mapName .. "' forge map...", "error")
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
    dprint("Saving forge map...")

    local forgeState = forgeStore:getState()

    local mapName = forgeState.currentMap.name
    local mapDescription = forgeState.currentMap.description

    -- List used to store data of every object in the forge map
    local forgeMap = {
        name = mapName,
        author = "",
        description = mapDescription,
        version = "",
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
        fmapObject.object = nil
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
        dprint("Forge map '" .. mapName .. "' has been succesfully saved!", "success")

        -- Reload forge maps list
        loadForgeMaps()

        if (server_type == "local") then
            features.printHUD("Done.", "Saving " .. mapName .. "..")
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

        -- Forces the object to render shadow
        if (configuration.objectsCastShadow) then
            blam.object(get_object(objectId), {
                isNotCastingShadow = false
            })
        end
        if (tempObject.isOutSideMap) then
            dprint("-> Object: " .. objectId .. " is INSIDE map!!!", "warning")

            -- Erase object to spawn it later in a safe place
            delete_object(objectId)

            -- Create new object but now in a safe place
            objectId = spawn_object(type, tagPath, x, y, constants.minimumZSpawnPoint)

            if (objectId) then
                -- Update new object position to match the original
                blam.object(get_object(objectId), {
                    x = x,
                    y = y,
                    z = z
                })

                -- Forces the object to render shadow
                if (configuration.objectsCastShadow) then
                    blam.object(get_object(objectId), {
                        isNotCastingShadow = false
                    })
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
---@param composedObject table
---@param disable boolean
function core.updatePlayerSpawnPoint(tagPath, composedObject, disable)
    local teamIndex = 0
    local gameType = 0

    -- Get spawn info from tag name
    -- // TODO: Add comment here with all the game types index!
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

    -- SAPP and Chimera can't substract scenario tag in the same way
    local scenarioAddress
    if (server_type == "sapp") then
        scenarioAddress = get_tag("scnr", constants.scenarioPath)
    else
        scenarioAddress = get_tag(0)
    end

    -- Get scenario data
    local scenario = blam.scenario(scenarioAddress)

    -- Get scenario player spawn points
    local mapSpawnPoints = scenario.spawnLocationList

    -- Object is not already reflecting a spawn point
    if (not composedObject.reflectionId) then
        for spawnId = 1, #mapSpawnPoints do
            -- If this spawn point is disabled
            if (mapSpawnPoints[spawnId].type == 0) then
                -- Replace spawn point values
                mapSpawnPoints[spawnId].x = composedObject.x
                mapSpawnPoints[spawnId].y = composedObject.y
                mapSpawnPoints[spawnId].z = composedObject.z
                mapSpawnPoints[spawnId].rotation = math.rad(composedObject.yaw)
                mapSpawnPoints[spawnId].teamIndex = teamIndex
                mapSpawnPoints[spawnId].type = gameType

                -- Debug spawn index
                dprint("Creating spawn replacing index: " .. spawnId, "warning")
                composedObject.reflectionId = spawnId
                break
            end
        end
    else
        dprint(composedObject.reflectionId)
        if (disable) then
            -- Disable or "delete" spawn point by setting type as 0
            mapSpawnPoints[composedObject.reflectionId].type = 0
            -- Update spawn point list
            blam.scenario(scenarioAddress, {
                spawnLocationList = mapSpawnPoints
            })
            return true
        end
        -- Replace spawn point values
        mapSpawnPoints[composedObject.reflectionId].x = composedObject.x
        mapSpawnPoints[composedObject.reflectionId].y = composedObject.y
        mapSpawnPoints[composedObject.reflectionId].z = composedObject.z
        mapSpawnPoints[composedObject.reflectionId].rotation = math.rad(composedObject.yaw)
        dprint(mapSpawnPoints[composedObject.reflectionId].type)
        -- Debug spawn index
        dprint("Updating spawn replacing index: " .. composedObject.reflectionId)
    end
    -- Update spawn point list
    blam.scenario(scenarioAddress, {
        spawnLocationList = mapSpawnPoints
    })
end

--- Apply updates to netgame flags spawn points based on a tag path
---@param tagPath string
---@param composedObject table
function core.updateNetgameFlagSpawnPoint(tagPath, composedObject)
    -- // TODO: Review if some flags use team index as "group index"!
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
        -- // TODO: Check if double setting team index against default value is needed!
        if (tagPath:find("red")) then
            dprint("RED TEAM FLAG")
            teamIndex = 0
        else
            dprint("BLUE TEAM FLAG")
            teamIndex = 1
        end
    elseif (tagPath:find("weapons")) then
        -- // TODO: Check and add weapon based netgame flags like oddball!
    end

    -- SAPP and Chimera can't substract scenario tag in the same way
    local scenarioAddress
    if (server_type == "sapp") then
        scenarioAddress = get_tag("scnr", constants.scenarioPath)
    else
        scenarioAddress = get_tag(0)
    end

    -- Get scenario data
    local scenario = blam.scenario(scenarioAddress)

    -- Get scenario player spawn points
    local mapNetgameFlagsPoints = scenario.netgameFlagsList

    -- Object is not already reflecting a flag point
    if (not composedObject.reflectionId) then
        for flagId = 1, #mapNetgameFlagsPoints do
            -- // FIXME: This control block is not neccessary but needs improvements!
            -- If this flag point is using the same flag type
            if (mapNetgameFlagsPoints[flagId].type == flagType and
                mapNetgameFlagsPoints[flagId].teamIndex == teamIndex) then
                -- Replace spawn point values
                mapNetgameFlagsPoints[flagId].x = composedObject.x
                mapNetgameFlagsPoints[flagId].y = composedObject.y
                -- Z plus an offset to prevent flag from falling in lower bsp values
                mapNetgameFlagsPoints[flagId].z = composedObject.z + 0.135
                mapNetgameFlagsPoints[flagId].rotation = math.rad(composedObject.yaw)
                mapNetgameFlagsPoints[flagId].teamIndex = teamIndex
                mapNetgameFlagsPoints[flagId].type = flagType

                -- Debug spawn index
                dprint("Creating flag replacing index: " .. flagId, "warning")
                composedObject.reflectionId = flagId
                break
            end
        end
    else
        dprint("Reflection id:" .. composedObject.reflectionId)
        -- Replace spawn point values
        mapNetgameFlagsPoints[composedObject.reflectionId].x = composedObject.x
        mapNetgameFlagsPoints[composedObject.reflectionId].y = composedObject.y
        mapNetgameFlagsPoints[composedObject.reflectionId].z = composedObject.z
        mapNetgameFlagsPoints[composedObject.reflectionId].rotation = math.rad(composedObject.yaw)
        dprint(mapNetgameFlagsPoints[composedObject.reflectionId].type)
        -- Debug spawn index
        dprint("Updating flag replacing index: " .. composedObject.reflectionId)
    end
    -- Update spawn point list
    blam.scenario(scenarioAddress, {
        netgameFlagsList = mapNetgameFlagsPoints
    })
end

--- Enable, update and disable vehicle spawns
-- Must be called after adding scenery object to the store!!
-- @return true if found an available spawn
function core.updateVehicleSpawn(tagPath, composedObject, disable)
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

    -- SAPP and Chimera can't substract scenario tag in the same way
    local scenarioAddress
    if (server_type == "sapp") then
        scenarioAddress = get_tag("scnr", constants.scenarioPath)
    else
        scenarioAddress = get_tag(0)
    end

    -- Get scenario data
    local scenario = blam.scenario(scenarioAddress)

    local vehicleLocationCount = scenario.vehicleLocationCount
    dprint("Maximum count of vehicle spawn points: " .. vehicleLocationCount)

    local vehicleLocationList = scenario.vehicleLocationList

    -- Object exists, it's synced
    if (not composedObject.reflectionId) then
        for spawnId = 2, #vehicleLocationList do
            if (vehicleLocationList[spawnId].type == 65535) then
                -- Replace spawn point values
                vehicleLocationList[spawnId].x = composedObject.x
                vehicleLocationList[spawnId].y = composedObject.y
                vehicleLocationList[spawnId].z = composedObject.z
                vehicleLocationList[spawnId].yaw = math.rad(composedObject.yaw)
                vehicleLocationList[spawnId].pitch = math.rad(composedObject.pitch)
                vehicleLocationList[spawnId].roll = math.rad(composedObject.roll)

                vehicleLocationList[spawnId].type = vehicleType

                -- Debug spawn index
                dprint("Creating spawn replacing index: " .. spawnId)
                composedObject.reflectionId = spawnId

                -- Update spawn point list
                blam.scenario(scenarioAddress, {
                    vehicleLocationList = vehicleLocationList
                })
                dprint("object_create_anew v" .. vehicleLocationList[spawnId].nameIndex)
                execute_script("object_create_anew v" .. vehicleLocationList[spawnId].nameIndex)
                -- Stop looking for "available" spawn slots
                break
            end
        end
    else
        dprint(composedObject.reflectionId)
        if (disable) then
            -- Disable or "delete" spawn point by setting type as 65535
            vehicleLocationList[composedObject.reflectionId].type = 65535
            -- Update spawn point list
            blam.scenario(scenarioAddress, {
                vehicleLocationList = vehicleLocationList
            })
            dprint("object_create_anew v" ..
                       vehicleLocationList[composedObject.reflectionId].nameIndex)
            execute_script("object_destroy v" ..
                               vehicleLocationList[composedObject.reflectionId].nameIndex)
            return true
        end
        -- Replace spawn point values
        vehicleLocationList[composedObject.reflectionId].x = composedObject.x
        vehicleLocationList[composedObject.reflectionId].y = composedObject.y
        vehicleLocationList[composedObject.reflectionId].z = composedObject.z

        -- REMINDER!!! Check vehicle rotation

        -- Debug spawn index
        dprint("Updating spawn replacing index: " .. composedObject.reflectionId)

        -- Update spawn point list
        blam.scenario(scenarioAddress, {
            vehicleLocationList = vehicleLocationList
        })
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

-- Module export
return core

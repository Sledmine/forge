------------------------------------------------------------------------------
-- Forge Core
-- Author: Sledmine
-- Version: 2.0
-- Core functionality for Forge
------------------------------------------------------------------------------
-- Lua libraries
local inspect = require 'inspect'
local json = require 'json'
local glue = require 'glue'

-- Halo libraries
local blam = require 'lua-blam'
local maethrillian = require 'maethrillian'

-- Forge libraries
local features = require 'forge.features'
local constants = require 'forge.constants'

-- Core module
local core = {}

--- Rotate object into desired degrees
---@param objectId number
---@param yaw number
---@param pitch number
---@param roll number
function core.rotateObject(objectId, yaw, pitch, roll)
    local rotation = features.convertDegrees(yaw, pitch, roll)
    blam.object(get_object(objectId), {
        pitch = rotation[1],
        yaw = rotation[2],
        roll = rotation[3],
        xScale = rotation[4],
        yScale = rotation[5],
        zScale = rotation[6]
    })
end

--- Send a request to the server throug rcon
---@param data table
---@param playerIndex number
---@return boolean success
---@return string request
function core.sendRequest(data, playerIndex)
    dprint('Request data: ')
    dprint(inspect(data))
    dprint('-> [ Sending request ]')
    local requestType = constants.requestTypes[data.requestType]
    if (requestType) then
        dprint('Type: ' .. requestType, 'category')
        local compressionFormat = constants.compressionFormats[requestType]

        if (not compressionFormat) then
            dprint('There is no format compression for this request!!!!',
                   'error')
            return false
        end

        dprint('Compression: ' .. inspect(compressionFormat))

        local requestObject = maethrillian.compressObject(data,
                                                          compressionFormat,
                                                          true)

        local requestOrder = constants.requestFormats[requestType]
        local request = maethrillian.convertObjectToRequest(requestObject,
                                                            requestOrder)

        request = "rcon forge '" .. request .. "'"

        dprint('Request: ' .. request)
        if (server_type == 'local') then
            -- We need to mockup the server response in local mode
            local mockedResponse = string.gsub(
                                       string.gsub(request, "rcon forge '", ''),
                                       "'", '')
            dprint('Local Request: ' .. mockedResponse)
            onRcon(mockedResponse)
            return true, mockedResponse
        elseif (server_type == 'dedicated') then
            -- Player is connected to a server
            dprint('Dedicated Request: ' .. request)
            execute_script(request)
            return true, request
        elseif (server_type == 'sapp') then
            local fixedResponse = string.gsub(request, "rcon forge '", '')
            dprint('Server Request: ' .. fixedResponse)

            -- We want to broadcast to every player in the server
            if (not playerIndex) then
                for i = 1, 16 do
                    if (player_present(i)) then
                        rprint(i, fixedResponse)
                    end
                end
            else
                -- We are looking to send data to a specific player
                rprint(playerIndex, fixedResponse)
            end
            return true, fixedResponse
        end
    end
    dprint('Error at trying to send request!!!!', 'error')
    return false
end

--- Create a request for an object action
---@param composedObject number
---@param requestType string
function core.createRequest(composedObject, requestType)
    local objectData = {}
    if (composedObject) then
        objectData.requestType = requestType
        if (requestType == constants.requestTypes.SPAWN_OBJECT) then
            objectData.tagId = composedObject.object.tagId
            if (server_type == 'sapp') then
                objectData.remoteId = composedObject.remoteId
            end
        elseif (requestType == constants.requestTypes.UPDATE_OBJECT) then
            composedObject.object = blam.object(
                                        get_object(composedObject.objectId))
            if (server_type ~= 'sapp') then
                objectData.objectId = composedObject.remoteId
            else
                objectData.objectId = composedObject.objectId
            end
        elseif (requestType == constants.requestTypes.DELETE_OBJECT) then
            if (server_type ~= 'sapp') then
                objectData.objectId = composedObject.remoteId
            else
                objectData.objectId = composedObject.objectId
            end
            return objectData
        elseif (requestType == constants.requestTypes.LOAD_MAP_SCREEN) then
            objectData.objectCount = composedObject.objectCount
            objectData.mapName = composedObject.mapName
            return objectData
        end
        objectData.x = composedObject.object.x
        objectData.y = composedObject.object.y
        objectData.z = composedObject.object.z
        objectData.yaw = composedObject.yaw
        objectData.pitch = composedObject.pitch
        objectData.roll = composedObject.roll
        return objectData
    end
    return nil
end

function core.resetSpawnPoints()
    local scenarioAddress
    if (server_type ~= 'sapp') then
        scenarioAddress = get_tag(0)
    else
        scenarioAddress = get_tag('scnr', constants.scenarioPath)
    end
    local scenario = blam.scenario(scenarioAddress)

    local mapSpawnCount = scenario.spawnLocationCount
    local vehicleLocationCount = scenario.vehicleLocationCount

    dprint('Found ' .. mapSpawnCount .. ' stock player starting points!')
    dprint('Found ' .. vehicleLocationCount .. ' stock vehicle location points!')
    local mapSpawnPoints = scenario.spawnLocationList
    -- Reset any spawn point, except the first one
    for i = 1, mapSpawnCount do
        -- Disable them by setting type to 0
        mapSpawnPoints[i].type = 0
    end
    local vehicleLocationList = scenario.vehicleLocationList
    for i = 2, vehicleLocationCount do
        vehicleLocationList[i].type = 65535
        execute_script('object_destroy v' .. vehicleLocationList[i].nameIndex)
    end
    blam.scenario(scenarioAddress, {
        spawnLocationList = mapSpawnPoints,
        vehicleLocationList = vehicleLocationList
    })
end

function core.flushForge()
    local forgeObjects = eventsStore:getState().forgeObjects
    if (#glue.keys(forgeObjects) > 0 and #get_objects() > 0) then
        -- saveForgeMap('unsaved')
        -- execute_script('object_destroy_all')
        for objectId, composedObject in pairs(forgeObjects) do
            delete_object(objectId)
        end
        eventsStore:dispatch({type = constants.actionTypes.FLUSH_FORGE})
    end
end

function core.loadForgeMap(mapName)
    if (server_type == 'dedicated') then
        console_out("You can not load a map while connected to a server!'")
        return false
    end
    local fmapContent = glue.readfile(forgeMapsFolder .. '\\' .. mapName ..
                                          '.fmap', 't')
    if (fmapContent) then
        dprint('Loading forge map...')
        local forgeMap = json.decode(fmapContent)
        if (forgeMap and forgeMap.objects and #forgeMap.objects > 0) then
            forgeStore:dispatch({
                type = 'SET_MAP_DATA',
                payload = {mapName = forgeMap.name, mapDescription = forgeMap.description}
            })
            if (server_type == 'sapp') then
                local tempObject = {}
                tempObject.objectCount = #forgeMap.objects
                tempObject.mapName = forgeMap.name
                local response = core.createRequest(tempObject,
                                                    constants.requestTypes
                                                        .LOAD_MAP_SCREEN)
                core.sendRequest(response)
            end

            -- TO DO: Create flush system or features to load objects on map load
            core.resetSpawnPoints()

            -- Remove blur after reloading server on local mode
            if (server_type == 'local') then
                execute_script('menu_blur_off')
                core.flushForge()
            end

            for objectIndex, composedObject in pairs(forgeMap.objects) do
                composedObject.tagId =
                    get_tag_id('scen', composedObject.tagPath)
                if (composedObject.tagId) then
                    composedObject.tagPath = nil
                    eventsStore:dispatch(
                        {
                            type = constants.actionTypes.SPAWN_OBJECT,
                            payload = {requestObject = composedObject}
                        })
                else
                    dprint("WARNING!! Object with path '" ..
                               composedObject.tagPath .. "' can't be spawn...",
                           'warning')
                end
            end

            execute_script('sv_map_reset')
            dprint("Succesfully loaded '" .. mapName .. "' fmap!")

            return true
        else
            dprint("ERROR!! At decoding data from '" .. mapName ..
                       "' forge map...", 'error')
        end
    else
        dprint(
            "ERROR!! At trying to load '" .. mapName .. "' as a forge map...",
            'error')
    end
    return false
end

function core.saveForgeMap(mapName)
    dprint('Saving forge map...')

    local forgeState = forgeStore:getState()

    local mapName = forgeState.currentMap.name
    local mapDescription = forgeState.currentMap.description

    -- List used to store data of every object in the forge map
    local forgeMap = {
        name = mapName,
        author = '',
        description = mapDescription,
        version = '',
        objects = {}
    }

    -- Get the state of the forge objects
    local objectsState = eventsStore:getState().forgeObjects

    -- Iterate through all the forge objects
    for objectId, composedObject in pairs(objectsState) do
        -- Get scenery tag path to keep compatibility between versions
        local sceneryPath = get_tag_path(composedObject.object.tagId)
        dprint(sceneryPath)

        -- Create a copy of the composed object in the store to avoid replacing useful values
        local fmapComposedObject = {}
        for k, v in pairs(composedObject) do fmapComposedObject[k] = v end

        -- Remove all the unimportant data
        fmapComposedObject.object = nil
        fmapComposedObject.objectId = nil
        fmapComposedObject.reflectionId = nil
        fmapComposedObject.remoteId = nil

        -- Add tag path property
        fmapComposedObject.tagPath = sceneryPath

        -- Add forge object to list
        glue.append(forgeMap.objects, fmapComposedObject)
    end

    -- Encode map info as JSON
    local fmapContent = json.encode(forgeMap)

    -- Update map name
    mapName = string.gsub(mapName, ' ', '_')

    local forgeMapFile = glue.writefile(forgeMapsFolder .. '\\' .. mapName ..
                                            '.fmap', fmapContent, 't')

    -- Check if file was created
    if (forgeMapFile) then
        dprint("Forge map '" .. mapName .. "' has been succesfully saved!",
               'success')

        -- Reload forge maps list
        loadForgeMapsList()
    else
        dprint("ERROR!! At saving '" .. mapName .. "' as a forge map...",
               'error')
    end
end

--- Super function for debug printing and non self blocking spawning
---@param tagPath string
---@param x number @param y number @param Z number
---@return number | nil objectId
function core.cspawn_object(type, tagPath, x, y, z)
    dprint(' -> [ Object Spawning ]')
    dprint('Type:', 'category')
    dprint(type)
    dprint('Tag  Path:', 'category')
    dprint(tagPath)
    dprint('Trying to spawn object...', 'warning')
    -- Prevent objects from phantom spawning!
    -- local variables are accesed first than parameter variables
    local objectId = spawn_object(type, tagPath, x, y, z)
    if (objectId) then
        local tempObject = blam.object(get_object(objectId))
        if (tempObject.isOutSideMap) then
            dprint('-> Object: ' .. objectId .. ' is INSIDE map!!!', 'warning')
            console_out('INSIDE BSP!!!!!!!!!!!!!!!!')

            -- Erase object to spawn it later in a safe place
            delete_object(objectId)

            -- Create new object but now in a safe place
            objectId = spawn_object(type, tagPath, x, y,
                                    constants.minimumZSpawnPoint)

            if (objectId) then
                -- Update new object position to match the original
                blam.object(get_object(objectId), {x = x, y = y, z = z})
            end

        end

        dprint('-> Object: ' .. objectId .. ' succesfully spawned!!!', 'success')
        return objectId, x, y, z
    end
    dprint('Error at trying to spawn object!!!!', 'error')
    return nil
end

--- Apply needed modifications to scenario spawn points
-- It's local to the reducer to avoid outside implementation
---@param tagPath string
---@param composedObject table
---@param disable boolean
function core.modifyPlayerSpawnPoint(tagPath, composedObject, disable)
    local teamIndex = 0
    local gameType = 0

    -- Get spawn info from tag name
    if (tagPath:find('ctf')) then
        dprint('CTF')
        gameType = 1
    elseif (tagPath:find('slayer')) then
        dprint('SLAYER')
        gameType = 2
    elseif (tagPath:find('generic')) then
        dprint('GENERIC')
        gameType = 12
    end

    if (tagPath:find('red')) then
        dprint('RED TEAM')
        teamIndex = 0
    elseif (tagPath:find('blue')) then
        dprint('BLUE TEAM')
        teamIndex = 1
    end

    -- SAPP and Chimera can't substract scenario tag in the same way
    local scenarioAddress
    if (server_type == 'sapp') then
        scenarioAddress = get_tag('scnr', constants.scenarioPath)
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
                dprint('Creating spawn replacing index: ' .. spawnId, 'warning')
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
            blam.scenario(scenarioAddress, {spawnLocationList = mapSpawnPoints})
            return true
        end
        -- Replace spawn point values
        mapSpawnPoints[composedObject.reflectionId].x = composedObject.x
        mapSpawnPoints[composedObject.reflectionId].y = composedObject.y
        mapSpawnPoints[composedObject.reflectionId].z = composedObject.z
        mapSpawnPoints[composedObject.reflectionId].rotation =
            math.rad(composedObject.yaw)
        dprint(mapSpawnPoints[composedObject.reflectionId].type)
        -- Debug spawn index
        dprint('Updating spawn replacing index: ' .. composedObject.reflectionId)
    end
    -- Update spawn point list
    blam.scenario(scenarioAddress, {spawnLocationList = mapSpawnPoints})
end

--- Enable, update and disable vehicle spawns
-- Must be called after adding scenery object to the store!!
-- @return true if found an available spawn
function core.modifyVehicleSpawn(tagPath, composedObject, disable)
    if (server_type == 'dedicated') then return true end
    local vehicleType = 0
    -- Get spawn info from tag name
    if (tagPath:find('banshee')) then
        dprint('banshee')
        vehicleType = 0
    elseif (tagPath:find('hog')) then
        dprint('hog')
        vehicleType = 1
    elseif (tagPath:find('ghost')) then
        dprint('ghost')
        vehicleType = 2
    elseif (tagPath:find('scorpion')) then
        dprint('scorpion')
        vehicleType = 3
    elseif (tagPath:find('turret spawn')) then
        dprint('turret')
        vehicleType = 4
    elseif (tagPath:find('ball spawn')) then
        dprint('ball')
        vehicleType = 5
    end

    -- SAPP and Chimera can't substract scenario tag in the same way
    local scenarioAddress
    if (server_type == 'sapp') then
        scenarioAddress = get_tag('scnr', constants.scenarioPath)
    else
        scenarioAddress = get_tag(0)
    end

    -- Get scenario data
    local scenario = blam.scenario(scenarioAddress)

    local vehicleLocationCount = scenario.vehicleLocationCount
    dprint('Maximum count of vehicle spawn points: ' .. vehicleLocationCount)

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
                vehicleLocationList[spawnId].pitch =
                    math.rad(composedObject.pitch)
                vehicleLocationList[spawnId].roll =
                    math.rad(composedObject.roll)

                vehicleLocationList[spawnId].type = vehicleType

                -- Debug spawn index
                dprint('Creating spawn replacing index: ' .. spawnId)
                composedObject.reflectionId = spawnId

                -- Update spawn point list
                blam.scenario(scenarioAddress,
                              {vehicleLocationList = vehicleLocationList})
                dprint('object_create_anew v' ..
                           vehicleLocationList[spawnId].nameIndex)
                execute_script('object_create_anew v' ..
                                   vehicleLocationList[spawnId].nameIndex)
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
            blam.scenario(scenarioAddress,
                          {vehicleLocationList = vehicleLocationList})
            dprint('object_create_anew v' ..
                       vehicleLocationList[composedObject.reflectionId]
                           .nameIndex)
            execute_script('object_destroy v' ..
                               vehicleLocationList[composedObject.reflectionId]
                                   .nameIndex)
            return true
        end
        -- Replace spawn point values
        vehicleLocationList[composedObject.reflectionId].x = composedObject.x
        vehicleLocationList[composedObject.reflectionId].y = composedObject.y
        vehicleLocationList[composedObject.reflectionId].z = composedObject.z

        -- REMINDER!!! Check vehicle rotation

        -- Debug spawn index
        dprint('Updating spawn replacing index: ' .. composedObject.reflectionId)

        -- Update spawn point list
        blam.scenario(scenarioAddress,
                      {vehicleLocationList = vehicleLocationList})
    end
end


function core.getObjectIdByRemoteId(state, remoteId)
    for k, v in pairs(state) do if (v.remoteId == remoteId) then return k end end
    return nil
end

-- Module export
return core

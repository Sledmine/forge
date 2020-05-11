-- Apply needed modifications to scenario spawn points
-- It's local to the reducer to avoid outside implementation
---@param tagPath string
---@param composedObject table
---@param disable boolean
local function modifyPlayerSpawnPoint(tagPath, composedObject, disable)
    local teamIndex = 0
    local gameType = 0

    -- Get spawn info from tag name
    if (tagPath:find('ctf')) then
        cprint('CTF')
        gameType = 1
    elseif (tagPath:find('slayer')) then
        cprint('SLAYER')
        gameType = 2
    elseif (tagPath:find('generic')) then
        cprint('GENERIC')
        gameType = 12
    end

    if (tagPath:find('red')) then
        cprint('RED TEAM')
        teamIndex = 0
    elseif (tagPath:find('blue')) then
        cprint('BLUE TEAM')
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
                cprint('Creating spawn replacing index: ' .. spawnId, 'warning')
                composedObject.reflectionId = spawnId
                break
            end
        end
    else
        cprint(composedObject.reflectionId)
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
        cprint(mapSpawnPoints[composedObject.reflectionId].type)
        -- Debug spawn index
        cprint('Updating spawn replacing index: ' .. composedObject.reflectionId)
    end
    -- Update spawn point list
    blam.scenario(scenarioAddress, {spawnLocationList = mapSpawnPoints})
end

-- Must be called after adding scenery object to the store!!
-- @return true if found an available spawn
local function modifyVehicleSpawn(tagPath, composedObject, disable)
    if (server_type == 'dedicated') then return true end
    local vehicleType = 0
    -- Get spawn info from tag name
    if (tagPath:find('banshee')) then
        cprint('banshee')
        vehicleType = 0
    elseif (tagPath:find('hog')) then
        cprint('hog')
        vehicleType = 1
    elseif (tagPath:find('ghost')) then
        cprint('ghost')
        vehicleType = 2
    elseif (tagPath:find('scorpion')) then
        cprint('scorpion')
        vehicleType = 3
    elseif (tagPath:find('turret spawn')) then
        cprint('turret')
        vehicleType = 4
    elseif (tagPath:find('ball spawn')) then
        cprint('ball')
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
    cprint('Maximum count of vehicle spawn points: ' .. vehicleLocationCount)

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
                cprint('Creating spawn replacing index: ' .. spawnId)
                composedObject.reflectionId = spawnId

                -- Update spawn point list
                blam.scenario(scenarioAddress,
                              {vehicleLocationList = vehicleLocationList})
                cprint('object_create_anew v' ..
                           vehicleLocationList[spawnId].nameIndex)
                execute_script('object_create_anew v' ..
                                   vehicleLocationList[spawnId].nameIndex)
                -- Stop looking for "available" spawn slots
                break
            end
        end
    else
        cprint(composedObject.reflectionId)
        if (disable) then
            -- Disable or "delete" spawn point by setting type as 65535
            vehicleLocationList[composedObject.reflectionId].type = 65535
            -- Update spawn point list
            blam.scenario(scenarioAddress,
                          {vehicleLocationList = vehicleLocationList})
            cprint('object_create_anew v' ..
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
        cprint('Updating spawn replacing index: ' .. composedObject.reflectionId)

        -- Update spawn point list
        blam.scenario(scenarioAddress,
                      {vehicleLocationList = vehicleLocationList})
    end
end

function eventsReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then state = {forgeObjects = {}} end
    if (action.type) then
        cprint('-> [Objects Store]')
        cprint(action.type, 'category')
    end
    if (action.type == constants.actionTypes.SPAWN_OBJECT) then
        cprint('SPAWNING object to store...', 'warning')
        local requestObject = action.payload.requestObject

        local tagPath = get_tag_path(requestObject.tagId)

        -- Get all the existent objects in the game before object spawn
        local objectsBeforeSpawn = get_objects()

        -- Spawn object in the game
        local localObjectId, x, y, z = core.cspawn_object('scen', tagPath,
                                                          requestObject.x,
                                                          requestObject.y,
                                                          requestObject.z)

        -- The core.cspawn_object function returns modifications made to initial object coordinates
        requestObject.x = x
        requestObject.y = y
        requestObject.z = z

        -- Get all the existent objects in the game after object spawn
        local objectsAfterSpawn = get_objects()

        -- Tricky way to get object local id, due to Chimera 581 API returning a pointer instead of id
        -- Remember objectId is local to this server
        if (server_type ~= 'sapp') then
            localObjectId = glue.arraynv(objectsBeforeSpawn, objectsAfterSpawn)
        end

        -- Set object rotation after creating the object
        rotateObject(localObjectId, requestObject.yaw, requestObject.pitch,
                     requestObject.roll)

        -- Clean and prepare entity
        requestObject.object = luablam.object(get_object(localObjectId))
        requestObject.tagId = nil
        requestObject.requestType = nil
        requestObject.objectId = localObjectId

        -- We are the server so the remote id is the local objectId
        if (server_type == 'local' or server_type == 'sapp') then
            requestObject.remoteId = requestObject.objectId
        end

        cprint('localObjectId: ' .. requestObject.objectId)
        cprint('remoteId: ' .. requestObject.remoteId)

        -- TO DO: Create a new object rather than passing it as "reference"
        local composedObject = requestObject

        if (tagPath:find('spawning')) then
            cprint('-> [Reflecting Spawn]', 'warning')
            if (tagPath:find('players')) then
                cprint('PLAYER_SPAWN', 'category')

                -- Make needed modifications to game spawn points
                modifyPlayerSpawnPoint(tagPath, composedObject)
            elseif (tagPath:find('vehicles') or tagPath:find('objects')) then
                modifyVehicleSpawn(tagPath, composedObject)
            end
        end

        -- As a server we have to send back a response/request to every player
        if (server_type == 'sapp') then
            local response = core.createRequest(composedObject,
                                                constants.requestTypes
                                                    .SPAWN_OBJECT)
            core.sendRequest(response)
        end

        -- Store the object in our state
        state.forgeObjects[localObjectId] = composedObject

        forgeStore:dispatch({
            type = 'UPDATE_OBJECT_INFO',
            payload = {currentLoadingObjectPath = tagPath}
        })

        return state
    elseif (action.type == constants.actionTypes.UPDATE_OBJECT) then
        local requestObject = action.payload.requestObject

        local composedObject = state.forgeObjects[core.getObjectIdByRemoteId(
                                   state.forgeObjects, requestObject.objectId)]

        if (composedObject) then
            cprint('UPDATING object from store...', 'warning')
            composedObject.x = requestObject.x
            composedObject.y = requestObject.y
            composedObject.z = requestObject.z
            composedObject.yaw = requestObject.yaw
            composedObject.pitch = requestObject.pitch
            composedObject.roll = requestObject.roll
            if (composedObject.z < constants.minimumZSpawnPoint) then
                composedObject.z = constants.minimumZSpawnPoint
            end
            -- Update object rotation after creating the object
            rotateObject(composedObject.objectId, composedObject.yaw,
                         composedObject.pitch, composedObject.roll)
            blam.object(get_object(composedObject.objectId), {
                x = composedObject.x,
                y = composedObject.y,
                z = composedObject.z
            })

            if (composedObject.reflectionId) then
                local tagPath = get_tag_path(composedObject.object.tagId)
                if (tagPath:find('spawning')) then
                    cprint('-> [Reflecting Spawn]', 'warning')
                    if (tagPath:find('players')) then
                        cprint('PLAYER_SPAWN', 'category')
                        -- Make needed modifications to game spawn points
                        modifyPlayerSpawnPoint(tagPath, composedObject)
                    elseif (tagPath:find('vehicles') or tagPath:find('objects')) then
                        modifyVehicleSpawn(tagPath, composedObject)
                    end
                end
            end

            if (server_type == 'sapp') then
                local response = core.createRequest(composedObject,
                                                    constants.requestTypes
                                                        .UPDATE_OBJECT)
                core.sendRequest(response)
            end
        else
            cprint('ERROR!!! The required object with Id: ' ..
                       requestObject.objectId .. 'does not exist.', 'error')
        end
        return state
    elseif (action.type == constants.actionTypes.DELETE_OBJECT) then
        local requestObject = action.payload.requestObject

        local composedObject = state.forgeObjects[core.getObjectIdByRemoteId(
                                   state.forgeObjects, requestObject.objectId)]

        if (composedObject) then
            if (composedObject.reflectionId) then
                local tagPath = get_tag_path(composedObject.object.tagId)
                if (tagPath:find('spawning')) then
                    cprint('-> [Reflecting Spawn]', 'warning')
                    if (tagPath:find('players')) then
                        cprint('PLAYER_SPAWN', 'category')
                        -- Make needed modifications to game spawn points
                        modifyPlayerSpawnPoint(tagPath, composedObject, true)
                    elseif (tagPath:find('vehicles') or tagPath:find('objects')) then
                        modifyVehicleSpawn(tagPath, composedObject, true)
                    end
                end
            end

            cprint('Deleting object from store...', 'warning')
            delete_object(composedObject.objectId)
            state.forgeObjects[core.getObjectIdByRemoteId(state.forgeObjects,
                                                     requestObject.objectId)] =
                nil
            cprint('Done.', 'success')
            if (server_type == 'sapp') then
                local response = core.createRequest(composedObject,
                                                    constants.requestTypes
                                                        .DELETE_OBJECT)
                core.sendRequest(response)
            end
        else
            cprint('ERROR!!! The required object with Id: ' ..
                       requestObject.objectId .. 'does not exist.', 'error')
        end
        forgeStore:dispatch({type = 'UPDATE_OBJECT_INFO'})
        return state
    elseif (action.type == constants.actionTypes.LOAD_MAP_SCREEN) then
        local requestObject = action.payload.requestObject
        state.expectedObjects = requestObject.objectCount
        forgeStore:dispatch({
            type = 'UPDATE_OBJECT_INFO',
            payload = {expectedObjects = state.expectedObjects}
        })
        set_timer(140, 'forgeAnimation')
        features.openMenu(constants.widgetDefinitions.loadingMenu)
        return state
    elseif (action.type == constants.actionTypes.FLUSH_FORGE) then
        state = {forgeObjects = {}}
        return state
    else
        if (action.type == '@@lua-redux/INIT') then
            cprint('Default state has been created!')
        else
            cprint('ERROR!!! The dispatched event does not exist:', 'error')
        end
        return state
    end
end

return eventsReducer

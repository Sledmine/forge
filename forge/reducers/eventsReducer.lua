-- Lua libraries
local glue = require 'glue'
local inspect = require 'inspect'
local constants = require 'forge.constants'

-- Halo Custom Edition libraries
local blam = require 'lua-blam'

-- Forge modules
local core = require 'forge.core'
local features = require 'forge.features'

local function eventsReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        state = {forgeObjects = {}}
    end
    if (action.type) then
        dprint('-> [Objects Store]')
        dprint(action.type, 'category')
    end
    if (action.type == constants.actionTypes.SPAWN_OBJECT) then
        dprint('SPAWNING object to store...', 'warning')
        local requestObject = action.payload.requestObject

        local tagPath = get_tag_path(requestObject.tagId)

        -- Get all the existent objects in the game before object spawn
        local objectsBeforeSpawn = get_objects()
        dprint('Objects before spawn:')
        dprint(inspect(objectsBeforeSpawn))

        -- Spawn object in the game
        local localObjectId, x, y, z =
            core.cspawn_object('scen', tagPath, requestObject.x, requestObject.y, requestObject.z)

        dprint('Object id from Chimera: ' .. localObjectId)

        -- The core.cspawn_object function returns modifications made to initial object coordinates
        requestObject.x = x
        requestObject.y = y
        requestObject.z = z

        -- Get all the existent objects in the game after object spawn
        local objectsAfterSpawn = get_objects()
        dprint('Objects after spawn:')
        dprint(inspect(objectsAfterSpawn))

        -- Tricky way to get object local id, due to Chimera 581 API returning a pointer instead of id
        -- Remember objectId is local to this server
        if (server_type ~= 'sapp') then
            local newObjects = glue.arraynv(objectsBeforeSpawn, objectsAfterSpawn)
            localObjectId = newObjects[#newObjects]
        end
        dprint('Calculated new object simple id:' .. localObjectId)

        -- Set object rotation after creating the object
        core.rotateObject(localObjectId, requestObject.yaw, requestObject.pitch, requestObject.roll)

        -- Clean and prepare entity
        requestObject.object = blam.object(get_object(localObjectId))
        requestObject.tagId = nil
        requestObject.requestType = nil
        requestObject.objectId = localObjectId

        -- We are the server so the remote id is the local objectId
        if (server_type == 'local' or server_type == 'sapp') then
            requestObject.remoteId = requestObject.objectId
        end

        dprint('localObjectId: ' .. requestObject.objectId)
        dprint('remoteId: ' .. requestObject.remoteId)

        -- TO DO: Create a new object rather than passing it as "reference"
        local composedObject = requestObject

        -- TODO: Object color customization!
        --[[redA = math.random(0,1),
            greenA = math.random(0,1),
            blueA = math.random(0,1)
        ]]
        if (tagPath:find('spawning')) then
            dprint('-> [Reflecting Spawn]', 'warning')
            if (tagPath:find('players')) then
                dprint('PLAYER_SPAWN', 'category')

                -- Make needed modifications to game spawn points
                core.modifyPlayerSpawnPoint(tagPath, composedObject)
            elseif (tagPath:find('vehicles') or tagPath:find('objects')) then
                core.modifyVehicleSpawn(tagPath, composedObject)
            end
        end

        -- As a server we have to send back a response/request to every player
        if (server_type == 'sapp') then
            local response = core.createRequest(composedObject, constants.requestTypes.SPAWN_OBJECT)
            core.sendRequest(response)
        end

        -- Store the object in our state
        state.forgeObjects[localObjectId] = composedObject

        forgeStore:dispatch(
            {
                type = 'UPDATE_MAP_INFO'
            }
        )

        return state
    elseif (action.type == constants.actionTypes.UPDATE_OBJECT) then
        local requestObject = action.payload.requestObject

        local composedObject =
            state.forgeObjects[core.getObjectIdByRemoteId(state.forgeObjects, requestObject.objectId)]

        if (composedObject) then
            dprint('UPDATING object from store...', 'warning')
            composedObject.x = requestObject.x
            composedObject.y = requestObject.y
            composedObject.z = requestObject.z
            composedObject.yaw = requestObject.yaw
            composedObject.pitch = requestObject.pitch
            composedObject.roll = requestObject.roll
            -- Update object rotation after creating the object
            core.rotateObject(composedObject.objectId, composedObject.yaw, composedObject.pitch, composedObject.roll)
            blam.object(
                get_object(composedObject.objectId),
                {
                    x = composedObject.x,
                    y = composedObject.y,
                    z = composedObject.z
                }
            )

            if (composedObject.reflectionId) then
                local tagPath = get_tag_path(composedObject.object.tagId)
                if (tagPath:find('spawning')) then
                    dprint('-> [Reflecting Spawn]', 'warning')
                    if (tagPath:find('players')) then
                        dprint('PLAYER_SPAWN', 'category')
                        -- Make needed modifications to game spawn points
                        core.modifyPlayerSpawnPoint(tagPath, composedObject)
                    elseif (tagPath:find('vehicles') or tagPath:find('objects')) then
                        core.modifyVehicleSpawn(tagPath, composedObject)
                    end
                end
            end

            if (server_type == 'sapp') then
                local response = core.createRequest(composedObject, constants.requestTypes.UPDATE_OBJECT)
                core.sendRequest(response)
            end
        else
            dprint('ERROR!!! The required object with Id: ' .. requestObject.objectId .. 'does not exist.', 'error')
        end
        return state
    elseif (action.type == constants.actionTypes.DELETE_OBJECT) then
        local requestObject = action.payload.requestObject

        local composedObject =
            state.forgeObjects[core.getObjectIdByRemoteId(state.forgeObjects, requestObject.objectId)]

        if (composedObject) then
            if (composedObject.reflectionId) then
                local tagPath = get_tag_path(composedObject.object.tagId)
                if (tagPath:find('spawning')) then
                    dprint('-> [Reflecting Spawn]', 'warning')
                    if (tagPath:find('players')) then
                        dprint('PLAYER_SPAWN', 'category')
                        -- Make needed modifications to game spawn points
                        core.modifyPlayerSpawnPoint(tagPath, composedObject, true)
                    elseif (tagPath:find('vehicles') or tagPath:find('objects')) then
                        core.modifyVehicleSpawn(tagPath, composedObject, true)
                    end
                end
            end

            dprint('Deleting object from store...', 'warning')
            delete_object(composedObject.objectId)
            state.forgeObjects[core.getObjectIdByRemoteId(state.forgeObjects, requestObject.objectId)] = nil
            dprint('Done.', 'success')
            if (server_type == 'sapp') then
                local response = core.createRequest(composedObject, constants.requestTypes.DELETE_OBJECT)
                core.sendRequest(response)
            end
        else
            dprint('ERROR!!! The required object with Id: ' .. requestObject.objectId .. 'does not exist.', 'error')
        end
        forgeStore:dispatch({type = 'UPDATE_MAP_INFO'})
        return state
    elseif (action.type == constants.actionTypes.LOAD_MAP_SCREEN) then
        -- TO DO: This is not ok, this must be split in different reducers
        local requestObject = action.payload.requestObject

        local expectedObjects = requestObject.objectCount
        local mapName = requestObject.mapName
        local mapDescription = requestObject.mapDescription

        forgeStore:dispatch(
            {
                type = 'UPDATE_MAP_INFO',
                payload = {
                    expectedObjects = expectedObjects,
                    mapName = mapName,
                    mapDescription = mapDescription
                }
            }
        )

        -- TO DO: This does not end after finishing map loading
        set_timer(140, 'forgeAnimation')

        features.openMenu(constants.uiWidgetDefinitions.loadingMenu)

        return state
    elseif (action.type == constants.actionTypes.FLUSH_FORGE) then
        state = {forgeObjects = {}}
        return state
    else
        if (action.type == '@@lua-redux/INIT') then
            dprint('Default state has been created!')
        else
            dprint('ERROR!!! The dispatched event does not exist:', 'error')
        end
        return state
    end
end

return eventsReducer

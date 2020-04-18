function objectsReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        state = {}
    end
    if (action.type) then
        cprint('-> [Objects Store]')
        cprint(action.type, 'category')
    end
    if (action.type == constants.actionTypes.SPAWN_OBJECT) then
        cprint('SPAWNING object to store...', 'warning')
        local requestObject = action.payload.composedObject

        local tagPath = get_tag_path(requestObject.tagId)

        -- Get all the existent objects in the game before object spawn
        local objectsBeforeSpawn = get_objects()

        -- Spawn object in the game
        cspawn_object('scen', tagPath, requestObject.x, requestObject.y, requestObject.z)

        -- Get all the existent objects in the game after object spawn
        local objectsAfterSpawn = get_objects()

        -- Tricky way to get object local id, due to Chimera API returning a pointer instead of id
        -- Remember objectId is local to this server
        local localObjectId = glue.arraynv(objectsBeforeSpawn, objectsAfterSpawn)

        -- Set object rotation after creating the object
        rotateObject(localObjectId, requestObject.yaw, requestObject.pitch, requestObject.roll)

        -- Clean and prepare entity
        requestObject.object = luablam.object(get_object(localObjectId))
        requestObject.tagId = nil
        requestObject.requestType = nil
        requestObject.objectId = localObjectId

        -- We are the server so the remote id is the local objectId
        if (server_type == 'local') then
            requestObject.remoteId = requestObject.objectId
        end

        cprint('localObjectId: ' .. requestObject.objectId)
        cprint('remoteId: ' .. requestObject.remoteId)

        -- TODO: Create a new object rather than passing it as "reference"
        local composedObject = requestObject

        -- Store the object in our state
        state[localObjectId] = composedObject

        return state
    elseif (action.type == constants.actionTypes.UPDATE_OBJECT) then
        local requestObject = action.payload.composedObject
        cprint(inspect(requestObject))

        local composedObject = state[getObjectIdByRemoteId(state, requestObject.objectId)]

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
            rotateObject(composedObject.objectId, composedObject.yaw, composedObject.pitch, composedObject.roll)
            blam.object(
                get_object(composedObject.objectId),
                {x = composedObject.x, y = composedObject.y, z = composedObject.z}
            )
        else
            cprint('ERROR!!! The required object does not exist.', 'error')
        end
        cprint(inspect(composedObject))
        return state
    elseif (action.type == constants.actionTypes.DELETE_OBJECT) then
        local requestObject = action.payload.composedObject

        local composedObject = state[getObjectIdByRemoteId(state, requestObject.objectId)]

        if (composedObject) then
            cprint('Deleting object from store...', 'warning')
            delete_object(composedObject.objectId)
            state[getObjectIdByRemoteId(state, requestObject.objectId)] = nil
            cprint('Done.', 'success')
        else
            cprint('ERROR!!! The specified object does not exist.', 'error')
        end
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

return objectsReducer
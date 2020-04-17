local rotationList = {yaw = 0,
pitch = 1,
roll = 2}

function playerReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        state = {
            lockDistance = true,
            distance = 5,
            attachedObjectId = nil,
            xOffset = 0,
            yOffset = 0,
            zOffset = 0,
            yaw = 0,
            pitch = 0,
            roll = 0,
            rotationStep = 2,
            currentRotation = 'yaw'
        }
    end
    if (action.type == 'SET_LOCK_DISTANCE') then
        state.lockDistance = action.payload.lockDistance
        return state
    elseif (action.type == 'CREATE_AND_ATTACH_OBJECT') then
        -- TO DO: Send a request to attach this object to a player in the server side
        if (state.attachedObjectId) then
            if (get_object(state.attachedObjectId)) then
                delete_object(state.attachedObjectId)
                state.attachedObjectId =
                    cspawn_object('scen', action.payload.path, state.xOffset, state.yOffset, state.zOffset)
            else
                state.attachedObjectId =
                    cspawn_object('scen', action.payload.path, state.xOffset, state.yOffset, state.zOffset)
            end
        else
            state.attachedObjectId =
                cspawn_object('scen', action.payload.path, state.xOffset, state.yOffset, state.zOffset)
        end
        return state
    elseif (action.type == 'ATTACH_OBJECT') then
        state.attachedObjectId = action.payload.objectId
        return state
    elseif (action.type == 'DETACH_OBJECT') then -- Update request if needed
        if (state.attachedObjectId) then
            local objectsState = objectsStore:getState()
            local composedObject = objectsState[state.attachedObjectId]
            if (composedObject) then
                -- Object already exists, send update request
                composedObject.object = blam.object(get_object(state.attachedObjectId))
                sendRequest(createRequest(composedObject, constants.requestTypes.UPDATE_OBJECT))
            else
                delete_object(state.attachedObjectId)
                -- Object does not exist, create composed object and send request
                composedObject = {
                    object = blam.object(get_object(state.attachedObjectId)),
                    objectId = state.attachedObjectId,
                    yaw = state.yaw,
                    pitch = state.pitch,
                    roll = state.roll
                }
                sendRequest(createRequest(composedObject, constants.requestTypes.SPAWN_OBJECT))
            end
            state.attachedObjectId = nil
        end
        return state
    elseif (action.type == 'DESTROY_OBJECT') then -- Delete request if needed
        if (state.attachedObjectId) then
            local objectsState = objectsStore:getState()
            local composedObject = objectsState[state.attachedObjectId]
            if (composedObject) then
                sendRequest(createRequest(composedObject, constants.requestTypes.DELETE_OBJECT))
            else
                delete_object(state.attachedObjectId)
            end
        end
        state.attachedObjectId = nil
        return state
    elseif (action.type == 'UPDATE_OFFSETS') then
        local player = action.payload.player
        state.xOffset = player.x + player.cameraX * state.distance
        state.yOffset = player.y + player.cameraY * state.distance
        state.zOffset = player.z + player.cameraZ * state.distance
        return state
    elseif (action.type == 'UPDATE_DISTANCE') then
        local player = action.payload.player
        local tempObject = blam.object(get_object(state.attachedObjectId))
        if (tempObject) then
            state.distance =
                math.sqrt((tempObject.x - player.x) ^ 2 + (tempObject.y - player.y) ^ 2 + (tempObject.z - player.z) ^ 2)
        end
        return state
    elseif  (action.type == 'CHANGE_ROTATION_ANGLE')
else
        return state
    end
end

return playerReducer
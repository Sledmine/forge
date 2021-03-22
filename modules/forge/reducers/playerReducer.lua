local glue = require "glue"

-- Forge modules
local core = require "forge.core"
local features = require "forge.features"

---@class position
---@field x number
---@field y number
---@field z number

---@class playerState
---@field position position
local defaultState = {
    lockDistance = true,
    distance = 5,
    attachedObjectId = nil,
    position = nil,
    xOffset = 0,
    yOffset = 0,
    zOffset = 0,
    attachX = 0,
    attachY = 0,
    attachZ = 0,
    yaw = 0,
    pitch = 0,
    roll = 0,
    rotationStep = 5,
    currentAngle = "yaw",
    color = 1,
    teamIndex = 0
}

local function playerReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        state = glue.deepcopy(defaultState)
    end
    if (action.type == "SET_LOCK_DISTANCE") then
        state.lockDistance = action.payload.lockDistance
        return state
    elseif (action.type == "CREATE_AND_ATTACH_OBJECT") then
        state.attachX = 0
        state.attachY = 0
        state.attachZ = 0
        state.yaw = 0
        state.pitch = 0
        state.roll = 0
        state.color = 1
        state.teamIndex = 0
        if (state.attachedObjectId) then
            if (get_object(state.attachedObjectId)) then
                delete_object(state.attachedObjectId)
                state.attachedObjectId = core.spawnObject("scen", action.payload.path,
                                                          state.xOffset, state.yOffset,
                                                          state.zOffset)
            else
                state.attachedObjectId = core.spawnObject("scen", action.payload.path,
                                                          state.xOffset, state.yOffset,
                                                          state.zOffset)
            end
        else
            state.attachedObjectId = core.spawnObject("scen", action.payload.path,
                                                      state.xOffset, state.yOffset,
                                                      state.zOffset)
        end
        -- core.rotateObject(state.attachedObjectId, state.yaw, state.pitch, state.roll)
        features.highlightObject(state.attachedObjectId, 1)
        return state
    elseif (action.type == "ATTACH_OBJECT") then
        state.attachedObjectId = action.payload.objectId
        local attachObject = action.payload.attach
        state.attachX = attachObject.x
        state.attachY = attachObject.y
        state.attachZ = attachObject.z
        local fromPerspective = action.payload.fromPerspective
        if (fromPerspective) then
            local player = blam.biped(get_dynamic_player())
            local tempObject = blam.object(get_object(state.attachedObjectId))
            if (tempObject) then
                local distance = core.calculateDistanceFromObject(player, tempObject)
                if (configuration.forge.snapMode) then
                    state.distance = glue.round(distance)
                else
                    state.distance = distance
                end
            end
        end
        local forgeObjects = eventsStore:getState().forgeObjects
        local forgeObject = forgeObjects[state.attachedObjectId]
        if (forgeObject) then
            state.yaw = forgeObject.yaw
            state.pitch = forgeObject.pitch
            state.roll = forgeObject.roll
            state.teamIndex = forgeObject.teamIndex
        end
        features.highlightObject(state.attachedObjectId, 1)
        return state
    elseif (action.type == "DETACH_OBJECT") then
        if (action.payload) then
            local payload = action.payload
            if (payload.undo) then
                state.attachedObjectId = nil
                return state
            end
        end
        -- Send update request in case of needed
        if (state.attachedObjectId) then
            local tempObject = blam.object(get_object(state.attachedObjectId))
            if (tempObject) then
                ---@type eventsState
                local eventsState = eventsStore:getState()
                local forgeObjects = eventsState.forgeObjects
                local forgeObject = forgeObjects[state.attachedObjectId]
                if (not forgeObject) then
                    -- Object does not exist, create request table and send request
                    local requestTable = {}
                    requestTable.requestType = constants.requests.spawnObject.requestType
                    requestTable.tagId = tempObject.tagId
                    requestTable.x = state.xOffset
                    requestTable.y = state.yOffset
                    requestTable.z = state.zOffset
                    requestTable.yaw = state.yaw
                    requestTable.pitch = state.pitch
                    requestTable.roll = state.roll
                    requestTable.color = state.color
                    requestTable.teamIndex = state.teamIndex
                    core.sendRequest(core.createRequest(requestTable))
                    delete_object(state.attachedObjectId)
                else
                    local tempObject = blam.object(get_object(state.attachedObjectId))
                    local requestTable = {}
                    requestTable.objectId = forgeObject.remoteId
                    requestTable.requestType = constants.requests.updateObject.requestType
                    requestTable.x = tempObject.x
                    requestTable.y = tempObject.y
                    requestTable.z = tempObject.z
                    requestTable.yaw = state.yaw
                    requestTable.pitch = state.pitch
                    requestTable.roll = state.roll
                    requestTable.color = state.color
                    requestTable.teamIndex = state.teamIndex
                    -- Object already exists, send update request
                    core.sendRequest(core.createRequest(requestTable))
                end
            end
            state.attachedObjectId = nil
        end
        return state
    elseif (action.type == "ROTATE_OBJECT") then
        if (state.attachedObjectId and get_object(state.attachedObjectId)) then
            core.rotateObject(state.attachedObjectId, state.yaw, state.pitch, state.roll)
        end
        return state
    elseif (action.type == "DESTROY_OBJECT") then
        -- Delete attached object
        if (state.attachedObjectId and get_object(state.attachedObjectId)) then
            local forgeObjects = eventsStore:getState().forgeObjects
            local forgeObject = forgeObjects[state.attachedObjectId]
            if (not forgeObject) then
                delete_object(state.attachedObjectId)
            else
                local requestTable = forgeObject
                requestTable.requestType = constants.requests.deleteObject.requestType
                requestTable.remoteId = forgeObject.remoteId
                core.sendRequest(core.createRequest(requestTable))
            end
        end
        state.attachedObjectId = nil
        return state
    elseif (action.type == "UPDATE_OFFSETS") then
        local player = blam.biped(get_dynamic_player())
        local tempObject
        if (state.attachedObjectId) then
            tempObject = blam.object(get_object(state.attachedObjectId))
        end
        if (not tempObject) then
            tempObject = {x = 0, y = 0, z = 0}
        end
        local xOffset = player.x - state.attachX + player.cameraX * state.distance
        local yOffset = player.y - state.attachY + player.cameraY * state.distance
        local zOffset = player.z - state.attachZ + player.cameraZ * state.distance
        if (configuration.forge.snapMode) then
            state.xOffset = glue.round(xOffset)
            state.yOffset = glue.round(yOffset)
            state.zOffset = glue.round(zOffset)
        else
            state.xOffset = xOffset
            state.yOffset = yOffset
            state.zOffset = zOffset
        end
        -- dprint(state.xOffset .. " " ..  state.yOffset .. " " .. state.zOffset)
        return state
    elseif (action.type == "UPDATE_DISTANCE") then
        if (state.attachedObjectId) then
            local player = blam.biped(get_dynamic_player())
            local tempObject = blam.object(get_object(state.attachedObjectId))
            if (tempObject) then
                local distance = core.calculateDistanceFromObject(player, tempObject)
                if (configuration.forge.snapMode) then
                    state.distance = glue.round(distance)
                else
                    state.distance = distance
                end
            end
        end
        return state
    elseif (action.type == "SET_DISTANCE") then
        state.distance = action.payload.distance
        return state
    elseif (action.type == "CHANGE_ROTATION_ANGLE") then
        if (state.currentAngle == "yaw") then
            state.currentAngle = "pitch"
        elseif (state.currentAngle == "pitch") then
            state.currentAngle = "roll"
        else
            state.currentAngle = "yaw"
        end
        return state
    elseif (action.type == "SET_ROTATION_STEP") then
        state.rotationStep = action.payload.step
        return state
    elseif (action.type == "STEP_ROTATION_DEGREE") then
        local multiplier = 1
        state.attachX = 0
        state.attachY = 0
        state.attachZ = 0
        if (action.payload) then
            if (action.payload.substraction) then
                state.rotationStep = math.abs(state.rotationStep) * -1
            else
                state.rotationStep = math.abs(state.rotationStep)
            end
            multiplier = action.payload.multiplier or multiplier
        end
        local previousRotation = state[state.currentAngle]
        -- //TODO Add multiplier implementation
        local newRotation = previousRotation + (state.rotationStep)
        if ((newRotation) >= 360) then
            state[state.currentAngle] = newRotation - 360
        elseif ((newRotation) <= 0) then
            state[state.currentAngle] = newRotation + 360
        else
            state[state.currentAngle] = previousRotation + state.rotationStep
        end

        return state
    elseif (action.type == "SET_ROTATION_DEGREES") then
        if (action.payload.yaw) then
            state.yaw = action.payload.yaw
        end
        if (action.payload.pitch) then
            state.pitch = action.payload.pitch
        end
        if (action.payload.roll) then
            state.roll = action.payload.roll
        end
        return state
    elseif (action.type == "RESET_ROTATION") then
        state.yaw = 0
        state.pitch = 0
        state.roll = 0
        -- state.currentAngle = 'yaw'
        return state
    elseif (action.type == "SAVE_POSITION") then
        local tempObject = blam.biped(get_dynamic_player())
        state.position = {x = tempObject.x, y = tempObject.y, z = tempObject.z}
        return state
    elseif (action.type == "RESET_POSITION") then
        state.position = nil
        return state
    elseif (action.type == "SET_OBJECT_COLOR") then
        if (action.payload) then
            state.color = glue.index(constants.colorsNumber)[action.payload]
        else
            dprint("Warning, attempt set color state value to nil.")
        end
        return state
    elseif (action.type == "SET_OBJECT_CHANNEL") then
        if (action.payload) then
            state.teamIndex = action.payload.channel
            dprint("teamIndex: " .. state.teamIndex)
        else
            dprint("Warning, attempt set teamIndex state value to nil.")
        end
        return state
    else
        return state
    end
end

return playerReducer

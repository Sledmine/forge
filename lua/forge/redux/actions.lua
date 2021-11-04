------------------------------------------------------------------------------
-- Redux Actions Launchers
-- Sledmine
-- Easier and less verbose functions to dispatch redux actions
------------------------------------------------------------------------------
local actions = {}

local features = require "forge.features"

---@return forgeState
function actions.getForgeState()
    return forgeStore:getState()
end

---@return eventsState
function actions.getEventsState()
    return eventsStore:getState()
end

function actions.setObjectColor(colorValue)
    local playerState = playerStore:getState()
    local object = blam.object(get_object(playerState.attachedObjectId))
    if (object) then
        features.setObjectColor(colorValue, object)
        playerStore:dispatch({type = "SET_OBJECT_COLOR", payload = colorValue})
    else
        dprint("Warning, trying to set object color for an unexisting object!")
    end
end

function actions.setObjectChannel(channelIndex)
    playerStore:dispatch({type = "SET_OBJECT_CHANNEL", payload = {channel = channelIndex}})
end

function actions.getGeneralElements()
    ---@type generalMenuState
    local generalMenuState = generalMenuStore:getState()
    return generalMenuState.menu.currentElementsList
end

return actions

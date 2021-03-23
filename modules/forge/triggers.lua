------------------------------------------------------------------------------
-- Triggers
-- Sledmine
-- Menu triggers
------------------------------------------------------------------------------
local triggers = {}

-- TODO Add unit testing for this
---@param triggerName string
---@param triggersNumber number
---@return number
function triggers.get(triggerName, triggersNumber)
    local restoreTriggersState = (function()
        for i = 1, triggersNumber do
            -- TODO Replace this function with set global
            execute_script("set " .. triggerName .. "_trigger_" .. i .. " false")
        end
    end)
    for i = 1, triggersNumber do
        if (get_global(triggerName .. "_trigger_" .. i)) then
            restoreTriggersState()
            return i
        end
    end
    return nil
end

return triggers

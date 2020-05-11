------------------------------------------------------------------------------
-- Triggers
-- Author: Sledmine
-- Version: 1.0
-- Menu triggers
------------------------------------------------------------------------------
local triggers = {}

---@param triggerName string
---@param triggersNumber number
---@return number
function triggers.get(triggerName, triggersNumber)
    local restoreTriggersState = (function()
        for i = 1, triggersNumber do
            execute_script('set ' .. triggerName .. '_trigger_' .. i .. ' false')
        end
    end)
    for i = 1, triggersNumber do
        if (get_global(triggerName .. '_trigger_' .. i)) then
            restoreTriggersState()
            return i
        end
    end
    return nil
end

return triggers

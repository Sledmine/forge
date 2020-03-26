------------------------------------------------------------------------------
-- Forge Hook
-- Author: Sledmine
-- Version: 1.0
-- Every hook executes a function
------------------------------------------------------------------------------

local hook = {}

function hook.attach(hookName, action, param)
    if (get_global(hookName .. '_hook')) then
        execute_script('set ' .. hookName .. '_hook ' .. ' false')
        action(param)
    end
end

return hook

local triggersCount = arg[1]
local triggerName = arg[2]

local globalBlock = [[(global boolean {triggerName}_trigger_{currentTrigger} false)
]]

local triggerBlock = [[(script static void set_{triggerName}_trigger_{currentTrigger}
    (set {triggerName}_trigger_{currentTrigger} true)
)]]

for currentTrigger = 1, triggersCount do
    local finalBlock = (globalBlock .. triggerBlock):gsub("{triggerName}", triggerName)
                           :gsub("{currentTrigger}", currentTrigger)
    print(finalBlock)
end

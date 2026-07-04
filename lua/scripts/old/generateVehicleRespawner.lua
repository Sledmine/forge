local glue = require "glue"

local funcHeader = [[
(script continuous respawn_vehicles
]]

local funcFooter = [[
    (sleep_until (= 0 1))
)
]]

local objectEvaluationHeader = [[
    (if
]]

local objectEvaluationFooter = [[
    )
]]

local objectEvaluationList = ""

for i = 1, 32 do
    local vehicleName = "v" .. i
    objectEvaluationList = objectEvaluationList .. objectEvaluationHeader ..
                               "\t\t(volume_test_object \"vehicle_respawn_scan\" " .. "\"" ..
                               vehicleName .. "\")\n" .. "\t\t(object_create_anew " .. "\"" ..
                               vehicleName .. "\")\n" .. objectEvaluationFooter
end

print(funcHeader .. objectEvaluationList .. funcFooter)

glue.writefile("generated.hsc", funcHeader .. objectEvaluationList .. funcFooter, "t")

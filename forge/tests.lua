------------------------------------------------------------------------------
-- Forge Tests
-- Author: Sledmine
-- Version: 1.0
-- Couple of tests for Forge functionality
------------------------------------------------------------------------------
local lu = require "luaunit"
local glue = require "glue"

-- Forge modules
local core = require "forge.core"
local constants = require "forge.constants"
local features = require "forge.features"

-- Mocked function to redirect print calls to test print
local function tprint(message, ...)
    if (message) then
        if (message:find("Starting")) then
            console_out(message)
            return
        end
        console_out(message)
    end
end

local tests = {}

----------------- Rcon Tests -----------------------
test_Rcon = {}

function test_Rcon:setUp()
    -- Patch function if does not exist due to chimera blocking function thing
    if (not onRcon) then
        onRcon = function()
        end
    end
    self.expectedDecodeResultSpawn = {
        pitch = 360,
        requestType = "#s",
        remoteId = 1234,
        roll = 360,
        tagId = 1234,
        x = 1,
        y = 2,
        yaw = 360,
        z = 3
    }

    self.expectedDecodeResultUpdate = {
        pitch = 360,
        requestType = "#u",
        roll = 360,
        objectId = 1234,
        x = 1,
        y = 2,
        yaw = 360,
        z = 3
    }

    self.expectedDecodeResultDelete = {
        requestType = "#d",
        objectId = 1234
    }
end

function test_Rcon:test_Callback()
    local decodeResult = onRcon("I am a callback test!")
    lu.assertEquals(decodeResult, true)
end

function test_Rcon:test_Decode_Spawn()
    local decodeResult, decodeData = onRcon(
                                         "'#s,d2040000,0000803f,00000040,00004040,360,360,360,d2040000'")
    lu.assertEquals(decodeResult, false)
    lu.assertEquals(decodeData, self.expectedDecodeResultSpawn)
end

function test_Rcon:test_Decode_Update()
    local decodeResult, decodeData = onRcon("'#u,1234,0000803f,00000040,00004040,360,360,360'")
    lu.assertEquals(decodeResult, false)
    lu.assertEquals(decodeData, self.expectedDecodeResultUpdate)
end

function test_Rcon:test_Decode_Delete()
    local decodeResult, decodeData = onRcon("'#d,1234'")
    lu.assertEquals(decodeResult, false)
    lu.assertEquals(decodeData, self.expectedDecodeResultDelete)
end

----------------- Objects Tests -----------------------

test_Objects = {}

function test_Objects:test_Spawn_And_Rotate_Objects()
    for index, tagPath in pairs(forgeStore:getState().forgeMenu.objectsDatabase) do
        -- Spawn object in the game
        local objectId = core.cspawn_object("scen", tagPath, 233, 41,
                                            constants.minimumZSpawnPoint + 1)
        -- Check the object has been spawned
        lu.assertNotIsNil(objectId)
        if (objectId) then
            for i = 1, 1000 do
                core.rotateObject(objectId, math.random(1, 360), math.random(1, 360),
                                  math.random(1, 360))
            end
            delete_object(objectId)
        end
    end
end

function test_Objects:test_Get_Netgame_SpawnPoints()
    local scenario = blam.scenario(get_tag(0))
    console_out(scenario.vehicleLocationCount)
    lu.assertEquals(scenario.vehicleLocationCount, 33)
end

----------------- Request Tests -----------------------

test_Request = {}

function test_Request:setUp()
    self.expectedEncodeSpawnResult = "#s,d2040000,0000803f,00000040,00004040,360,360,360"
    self.expectedEncodeUpdateResult = "#u,1234,0000803f,00000040,00004040,360,360,360"
    self.expectedEncodeDeleteResult = "#d,1234"
end

function test_Request:test_Encode_Spawn()
    local objectExample = {
        requestType = "#s",
        tagId = "1234",
        x = "1",
        y = "2",
        z = "3",
        yaw = "360",
        pitch = "360",
        roll = "360"
    }
    local result, request = core.sendRequest(objectExample)
    lu.assertEquals(result, true)
    lu.assertEquals(request, self.expectedEncodeSpawnResult)
end

function test_Request:test_Encode_Update()
    local objectExample = {
        requestType = "#u",
        objectId = "1234",
        x = "1.0",
        y = "2.0",
        z = "3.0",
        yaw = "360",
        pitch = "360",
        roll = "360"
    }
    local result, request = core.sendRequest(objectExample)
    lu.assertEquals(result, true)
    lu.assertEquals(request, self.expectedEncodeUpdateResult)
end

function test_Request:test_Encode_Spawn()
    local objectExample = {
        requestType = "#d",
        objectId = "1234"
    }
    local result, request = core.sendRequest(objectExample)
    lu.assertEquals(result, true)
    lu.assertEquals(request, self.expectedEncodeDeleteResult)
end

----------------- Menus Tests -----------------------

test_Menus = {}

function test_Menus:setUp()
    local forgeMenuTagPath = constants.uiWidgetDefinitions.forgeMenu
    self.expectedTagId = get_simple_tag_id(tagClasses.uiWidgetDefinition, forgeMenuTagPath)
end

function test_Menus:test_Forge_Menu()
    local menuTagPath = constants.uiWidgetDefinitions.forgeMenu
    local bridgeWidget = get_tag("DeLa", constants.uiWidgetDefinitions.errorNonmodalFullscreen)
    features.openMenu(menuTagPath, true)
    local bridgeWidgetData = blam.uiWidgetDefinition(bridgeWidget)
    lu.assertEquals(bridgeWidgetData.tagReference, self.expectedTagId)
end

----------------- Core Functions Tests -----------------------

test_Core = {}

function test_Core:setUp()
    -- yaw 0, pitch 0, roll 0
    self.case1Array = {1, 0, 0, 0, 0, 1}
    self.case1Matrix = {
        {1, 0, 0},
        {0, 1, 0},
        {0, 0, 1}
    }
    -- yaw 45, pitch 0, roll 0
    self.case2Array = {
        0.70710678118655,
        0.70710678118655,
        0,
        0,
        0,
        1
    }
    self.case2Matrix = {
        {1, 0, 0},
        {0, 1, 0},
        {0, 0, 1}
    }
end

function test_Core:test_Euler_Rotation()
    local case1Array, case1Matrix = core.eulerRotation(0, 0, 0)
    lu.assertEquals(case1Array, self.case1Array, "Rotation array must match", true)
    lu.assertEquals(case1Matrix, self.case1Matrix, "Rotation matrix must match", true)

    --[[local case2Array, case2Matrix = core.eulerRotation(45, 0, 0)
    lu.assertEquals(case2Array, self.case2Array, "Rotation array must match", true)
    lu.assertEquals(case2Matrix, self.case2Matrix, "Rotation matrix must match", true)]]
end

----------------------------------

function tests.run(output)
    ftestingMode = true
    -- Disable debug printing
    debugMode = not debugMode
    local runner = lu.LuaUnit.new()
    if (output) then
        runner:setOutputType("junit", "forge_tests_results")
    end
    runner:runSuite()
    -- Restore debug printing
    debugMode = not debugMode
    ftestingMode = false
end

-- Mocked arguments and executions for standalone execution and in game execution
if (not arg) then
    arg = {"-v"}
    -- bprint = print
    print = tprint
else
    tests.run()
end

return tests

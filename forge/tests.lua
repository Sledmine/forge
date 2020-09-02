------------------------------------------------------------------------------
-- Forge Tests
-- Author: Sledmine
-- Version: 1.0
-- Couple of tests for Forge functionality
------------------------------------------------------------------------------
local lu = require "luaunit"
local inspect = require "inspect"

-- Forge modules
local core = require "forge.core"

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

local unit = {}

----------------- Rcon Tests -----------------------
testRcon = {}

function testRcon:setUp()
    -- Patch function if does not exist due to chimera blocking function thing
    if (not OnRcon) then
        OnRcon = function()
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

function testRcon:testCallback()
    local decodeResult = OnRcon("I am a callback test!")
    lu.assertEquals(decodeResult, true)
end

function testRcon:testDecodeSpawn()
    local decodeResult, decodeData = OnRcon(
                                         "'#s|d2040000|0000803f|00000040|00004040|360|360|360|d2040000'")
    lu.assertEquals(decodeResult, false)
    lu.assertEquals(decodeData, self.expectedDecodeResultSpawn)
end

function testRcon:testDecodeUpdate()
    local decodeResult, decodeData = OnRcon("'#u|1234|0000803f|00000040|00004040|360|360|360'")
    lu.assertEquals(decodeResult, false)
    lu.assertEquals(decodeData, self.expectedDecodeResultUpdate)
end

function testRcon:testDecodeDelete()
    local decodeResult, decodeData = OnRcon("'#d|1234'")
    lu.assertEquals(decodeResult, false)
    lu.assertEquals(decodeData, self.expectedDecodeResultDelete)
end

----------------- Objects Tests -----------------------

testObjects = {}

function testObjects:testSpawnAndRotateObjects()
    for index, tagPath in pairs(forgeStore:getState().forgeMenu.objectsDatabase) do
        -- Spawn object in the game
        local objectId = core.spawnObject("scen", tagPath, 233, 41,
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

function testObjects:testGetNetgameSpawnPoints()
    local scenario = blam.scenario(0)
    console_out(scenario.vehicleLocationCount)
    lu.assertEquals(scenario.vehicleLocationCount, 33)
end

----------------- Request Tests -----------------------

testRequest = {}

function testRequest:setUp()
    self.expectedEncodeSpawnResult = "#s|d2040000|0000803f|00000040|00004040|360|360|360"
    self.expectedEncodeUpdateResult = "#u|1234|0000803f|00000040|00004040|360|360|360"
    self.expectedEncodeDeleteResult = "#d|1234"
end

function testRequest:testSpawnRequestAsClient()
    local objectExample = {
        requestType = "#s",
        tagId = 1234,
        x = 1.0,
        y = 2.0,
        z = 3.0,
        yaw = 360,
        pitch = 360,
        roll = 360
    }
    local request = core.createRequest(objectExample)
    lu.assertEquals(request, self.expectedEncodeSpawnResult)
end

function testRequest:testEncodeUpdateAsClient()
    local objectExample = {
        requestType = "#u",
        x = 1.0,
        y = 2.0,
        z = 3.0,
        yaw = 360,
        pitch = 360,
        roll = 360,
        remoteId = 1234
    }
    local request = core.createRequest(objectExample)
    lu.assertEquals(request, self.expectedEncodeUpdateResult)
end

function testRequest:testEncodeDeleteAsClient()
    local objectExample = {
        requestType = "#d",
        remoteId = 1234
    }
    local request = core.createRequest(objectExample)
    lu.assertEquals(request, self.expectedEncodeDeleteResult)
end

----------------- Menus Tests -----------------------

testMenus = {}

function testMenus:setUp()
    local forgeMenuTagPath = constants.uiWidgetDefinitions.forgeMenu
    self.expectedTagId = get_simple_tag_id(tagClasses.uiWidgetDefinition, forgeMenuTagPath)
end

----------------- Core Functions Tests -----------------------

testCore = {}

function testCore:setUp()
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

function testCore:testEulerRotation()
    local case1Array, case1Matrix = core.eulerToRotation(0, 0, 0)
    lu.assertEquals(case1Array, self.case1Array, "Rotation array must match", true)
    lu.assertEquals(case1Matrix, self.case1Matrix, "Rotation matrix must match", true)

    -- local case2Array, case2Matrix = core.eulerRotation(45, 0, 0)
    -- lu.assertEquals(case2Array, self.case2Array, "Rotation array must match", true)
    -- lu.assertEquals(case2Matrix, self.case2Matrix, "Rotation matrix must match", true)
end

----------------------------------

function unit.run(output)
    ftestingMode = true
    -- Disable debug printing
    -- debugMode = not debugMode
    local runner = lu.LuaUnit.new()
    if (output) then
        runner:setOutputType("junit", "forge_tests_results")
    end
    runner:runSuite()
    -- Restore debug printing
    -- debugMode = not debugMode
    ftestingMode = false
end

-- Mocked arguments and executions for standalone execution and in game execution
if (not arg) then
    arg = {"-v"}
    -- bprint = print
    print = tprint
else
    unit.run()
end

return unit

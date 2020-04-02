------------------------------------------------------------------------------
-- Forge Tests
-- Author: Sledmine
-- Version: 1.0
-- Couple of tests for Forge functionality
------------------------------------------------------------------------------

local glue = require 'glue'
local lu = require 'luaunit'
local maethrillian = require 'maethrillian'
local constants = require 'forge.constants'

-- Mocked function to redirect print calls to test print
local function tprint(message, ...)
    if (message) then
        if (message:find('Starting')) then
            console_out_warning(message)
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
        pitch="360",
        requestType="#s",
        roll="360",
        tagId="d2040000",
        x="0000803f",
        y="00000040",
        yaw="360",
        z="00004040"
    }

    self.expectedDecodeResultUpdate = {
        pitch="360",
        requestType="#u",
        roll="360",
        serverId="1234",
        x="0000803f",
        y="00000040",
        yaw="360",
        z="00004040"
    }

    self.expectedDecodeResultDelete = {
        requestType = '#d',
        serverId = '1234'
    }
end

function test_Rcon:test_Callback()
    local decodeResult = onRcon('I am a callback test!')
    lu.assertEquals(decodeResult, true)
end

function test_Rcon:test_Decode_Spawn()
    local decodeResult, decodeData = onRcon("'#s,1234,1.0,2.0,3.0,360,360,360'")
    lu.assertEquals(decodeResult, false)
    lu.assertEquals(self.expectedDecodeResultSpawn, decodeData)
end

function test_Rcon:test_Decode_Update()
    local decodeResult, decodeData = onRcon("'#u,1234,1.0,2.0,3.0,360,360,360'")
    lu.assertEquals(decodeResult, false)
    lu.assertEquals(self.expectedDecodeResultUpdate, decodeData)
end

function test_Rcon:test_Decode_Delete()
    local decodeResult, decodeData = onRcon("'#d,1234'")
    lu.assertEquals(decodeResult, false)
    lu.assertEquals(self.expectedDecodeResultDelete, decodeData)
end

----------------- Objects Tests -----------------------

test_Objects = {}

function test_Objects:test_Objects_Spawn()
    local objectResult = false
    for k, v in pairs(forgeStore:getState().forgeMenu.objectsDatabase) do
        local objectId = cspawn_object('scen', v, 233, 41, constants.minimumZSpawnPoint)
        if (objectId) then
            delete_object(objectId)
        end
        lu.assertNotIsNil(objectId)
    end
end

----------------- Request Tests -----------------------

test_Request = {}

function test_Request:setUp()
    self.expectedEncodeSpawnResult = '#s,d2040000,0000803f,00000040,00004040,360,360,360'
    self.expectedEncodeUpdateResult = '#u,1234,0000803f,00000040,00004040,360,360,360'
    self.expectedEncodeDeleteResult = '#d,1234'
end

function test_Request:test_Encode_Spawn()
    local objectExample = {
        requestType = '#s',
        tagId = '1234',
        x = '1.0',
        y = '2.0',
        z = '3.0',
        yaw = '360',
        pitch = '360',
        roll = '360'
    }
    local result, request = sendRequest(objectExample)
    lu.assertEquals(result, true)
    lu.assertEquals(request, self.expectedEncodeSpawnResult)
end

function test_Request:test_Encode_Update()
    local objectExample = {
        requestType = '#u',
        serverId = '1234',
        x = '1.0',
        y = '2.0',
        z = '3.0',
        yaw = '360',
        pitch = '360',
        roll = '360'
    }
    local result, request = sendRequest(objectExample)
    lu.assertEquals(result, true)
    lu.assertEquals(request, self.expectedEncodeUpdateResult)
end

function test_Request:test_Encode_Spawn()
    local objectExample = {
        requestType = '#d',
        serverId = '1234'
    }
    local result, request = sendRequest(objectExample)
    lu.assertEquals(result, true)
    lu.assertEquals(request, self.expectedEncodeDeleteResult)
end

----------------------------------------------------

function tests.run()
    local runner = lu.LuaUnit.new()
    runner:setOutputType('junit', 'forge_tests_results')
    runner:runSuite()
    --[[if (bprint) then
        print = bprint
    end]]
end

-- Mocked arguments and executions for standalone execution and in game execution
if (not arg) then
    arg = {'-v'}
    --bprint = print
    print = tprint
else
    tests.run()
end

return tests

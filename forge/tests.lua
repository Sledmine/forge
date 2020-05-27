------------------------------------------------------------------------------
-- Forge Tests
-- Author: Sledmine
-- Version: 1.0
-- Couple of tests for Forge functionality
------------------------------------------------------------------------------
local lu = require 'luaunit'

local core = require 'forge.core'
local constants = require 'forge.constants'

-- Mocked function to redirect print calls to test print
local function tprint(message, ...)
    if (message) then
        if (message:find('Starting')) then
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
    if (not onRcon) then onRcon = function() end end
    self.expectedDecodeResultSpawn = {
        pitch = 360,
        requestType = '#s',
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
        requestType = '#u',
        roll = 360,
        objectId = 1234,
        x = 1,
        y = 2,
        yaw = 360,
        z = 3
    }

    self.expectedDecodeResultDelete = {requestType = '#d', objectId = 1234}
end

function test_Rcon:test_Callback()
    local decodeResult = onRcon('I am a callback test!')
    lu.assertEquals(decodeResult, true)
end

function test_Rcon:test_Decode_Spawn()
    local decodeResult, decodeData = onRcon(
                                         "'#s,d2040000,0000803f,00000040,00004040,360,360,360,d2040000'")
    lu.assertEquals(decodeResult, false)
    lu.assertEquals(decodeData, self.expectedDecodeResultSpawn)
end

function test_Rcon:test_Decode_Update()
    local decodeResult, decodeData = onRcon(
                                         "'#u,1234,0000803f,00000040,00004040,360,360,360'")
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

function test_Objects:test_Objects_Spawn()
    local objectResult = false
    for index, tagPath in pairs(forgeStore:getState().forgeMenu.objectsDatabase) do

        -- Spawn object in the game
        local objectId = core.cspawn_object('scen', tagPath, 233, 41, constants.minimumZSpawnPoint + 1)
        
        -- Check the object has been spawned
        lu.assertNotIsNil(objectId)

        -- Clean up object
        if (objectId) then 
            dprint(objectId)
            dprint('Erasing object:' .. tagPath)    
            delete_object(objectId)
        end
        --local deletionResult = get_object(objectId)
        --lu.assertIsNil(deletionResult)
    end
end

----------------- Request Tests -----------------------

test_Request = {}

function test_Request:setUp()
    self.expectedEncodeSpawnResult =
        '#s,d2040000,0000803f,00000040,00004040,360,360,360'
    self.expectedEncodeUpdateResult =
        '#u,1234,0000803f,00000040,00004040,360,360,360'
    self.expectedEncodeDeleteResult = '#d,1234'
end

function test_Request:test_Encode_Spawn()
    local objectExample = {
        requestType = '#s',
        tagId = '1234',
        x = '1',
        y = '2',
        z = '3',
        yaw = '360',
        pitch = '360',
        roll = '360'
    }
    local result, request = core.sendRequest(objectExample)
    lu.assertEquals(result, true)
    lu.assertEquals(request, self.expectedEncodeSpawnResult)
end

function test_Request:test_Encode_Update()
    local objectExample = {
        requestType = '#u',
        objectId = '1234',
        x = '1.0',
        y = '2.0',
        z = '3.0',
        yaw = '360',
        pitch = '360',
        roll = '360'
    }
    local result, request = core.sendRequest(objectExample)
    lu.assertEquals(result, true)
    lu.assertEquals(request, self.expectedEncodeUpdateResult)
end

function test_Request:test_Encode_Spawn()
    local objectExample = {requestType = '#d', objectId = '1234'}
    local result, request = core.sendRequest(objectExample)
    lu.assertEquals(result, true)
    lu.assertEquals(request, self.expectedEncodeDeleteResult)
end

----------------------------------------------------

function tests.run(output)
    ftestingMode = true
    local runner = lu.LuaUnit.new()
    if (output) then runner:setOutputType('junit', 'forge_tests_results') end
    runner:runSuite()
    --[[if (bprint) then
        print = bprint
    end]]
    ftestingMode = false
end

-- Mocked arguments and executions for standalone execution and in game execution
if (not arg) then
    arg = {'-v'}
    -- bprint = print
    print = tprint
else
    tests.run()
end

return tests

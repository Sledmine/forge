------------------------------------------------------------------------------
-- Chimera Lua API Bindings Test
-- Sledmine
-- Series of tests for the bindings from Chimera functions to SAPP functions
------------------------------------------------------------------------------
local lu = require "luaunit"
local glue = require "glue"

require "chimera-lua-api"

testChimeraLuaApi = {}

function testChimeraLuaApi:setUp()
    self.expectedFiles = {"example.map", "imafolder", "test1.txt"}
end

function testChimeraLuaApi:testListDirectory()
    local files = list_directory("server\\tests\\files")
    lu.assertEquals(files, self.expectedFiles)
end

-- TODO Add more tests

local function runTests()
    local runner = lu.LuaUnit.new()
    runner:runSuite()
end

if (not arg) then
    return runTests
else
    runTests()
end

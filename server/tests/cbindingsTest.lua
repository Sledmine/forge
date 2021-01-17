------------------------------------------------------------------------------
-- Task entity test
-- Author: Sledmine
-- Tests for task entity
------------------------------------------------------------------------------
local lu = require "luaunit"
local glue = require "glue"

require "cbindings"

testCBindings = {}

function testCBindings:setUp()
   self.expectedFiles = {
       "example.map",
       "imafolder",
       "test1.txt",
   }
end

-- Test correct entity constructor
function testCBindings:testListDirectory()
    local files = list_directory("server\\tests\\files")
    lu.assertEquals(files, self.expectedFiles)
end


local function runTests()
    local runner = lu.LuaUnit.new()
    runner:runSuite()
end

if (not arg) then
    return runTests
else
    runTests()
end

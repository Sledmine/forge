local script = require "script"
local sleep = script.sleep
local engine = Engine
local getPlayer = engine.gameState.getPlayer
local getObject = engine.gameState.getObject
local objectType = engine.tag.objectType

local forge = require "forge.forge"


local map = {}

local isGameDedicated = engine.netgame.getServerType() == "dedicated"

function map.main()
    logger:info("Welcome to Forge Island!")
end
script.startup(map.main)

function map.loop()
    forge.controls()
end
script.continuous(map.loop)

return map

local script = require "script"
local sleep = script.sleep
local engine = Engine
local getPlayer = engine.player.getPlayer
local getObject = engine.object.getObject

local forge = require "forge.forge"


local map = {}

local isGameDedicated = engine.game.getGameConnectionType() == "networkClient"

function map.main()
    Balltze.logger.info("Welcome to Forge Island!")
end
script.startup(map.main)

function map.loop()
    forge.controls()
end
script.continuous(map.loop)

return map

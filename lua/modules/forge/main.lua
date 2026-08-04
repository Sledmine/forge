local script = require "script"
local sleep = script.sleep
local engine = Engine
local constants = require "forgeIsland.constants"
local monitorMenu = require "forgeIsland.menus.monitorMenu"

local forge = require "forge.forge"

-- Configure Forge constants
forge.constants.bipeds.monitor = constants.bipeds.monitor
forge.constants.bipeds.spartan = constants.bipeds.spartan
forge.constants.weaponHudInterfaces.monitorCrosshair =
constants.weaponHudInterfaces.monitorCrosshair

forge.callbacks.launchMonitorMenu = function()
    monitorMenu:launch()
end

local map = {}

local isGameDedicated = engine.game.getGameConnectionType() == "networkClient"

function map.main()
    forge.load()
    Balltze.logger.info("Welcome to Forge Island!")
end
script.startup(map.main)

function map.loop()
    forge.controls()
end
script.continuous(map.loop)

return map

local script = require "script"
local sleep = script.sleep
local engine = Engine
local constants = require "forgeIsland.constants"
local monitorMenu = require "forgeIsland.menus.monitorMenu"

local forge = require "forge.forge"

-- Configure Forge constants
forge.constants.bipeds.monitor = constants.bipeds.monitor
forge.constants.bipeds.player = constants.bipeds.player
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
    if DebugMode then
        forge.swapPlayerBiped(0, "monitor")
        forge.callbacks.launchMonitorMenu()
        --engine.uiWidget.launchWidget(constants.menus.forge.handle.value)
    end
end
script.startup(map.main)

function map.loop()
    forge.controls()
end
script.continuous(map.loop)

function map.hotReload()
    local reloadFile = io.open("/tmp/reload", "r")
    if reloadFile then
        reloadFile:close()
        os.remove("/tmp/reload")
        Balltze.logger.info("Hot reloading Forge Island...")
        engine.script.execute("fast_setup_network_server ui ui 1")
        Balltze.logger.info("Hot reload complete!")
    end
    sleep(90)
end
script.continuous(map.hotReload)

return map

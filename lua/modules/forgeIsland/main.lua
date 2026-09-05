local script = require "script"
local sleep = script.sleep
local engine = Engine
local balltze = Balltze
local constants = require "forgeIsland.constants"
local monitorMenu = require "forgeIsland.menus.monitorMenu"
local logger = balltze.logger

local forge = require "forge.forge"

-- Configure Forge constants
local forgeConstants = forge.constants
forgeConstants.bipeds.monitor = constants.bipeds.monitor
forgeConstants.bipeds.player = constants.bipeds.player
forgeConstants.tagCollections.forgeObjects = constants.tagCollections.forgeObjects
forgeConstants.weaponHudInterfaces.monitorCrosshair = constants.weaponHudInterfaces.monitorCrosshair
forgeConstants.fonts.hud = constants.fonts.arameThin

forge.callbacks.launchMonitorMenu = function(mode)
    logger.debug("Launching monitor menu with mode={}", mode)
    monitorMenu.launch(mode)
end

local map = {}

local isGameDedicated = engine.game.getGameConnectionType() == "networkClient"

function map.main()
    forge.load()
    Balltze.logger.info("Welcome to Forge Island!")
    if DebugMode then
        forge.swapPlayerBiped(0, "monitor")
        forge.callbacks.launchMonitorMenu("place")
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
    end
    sleep(90)
end
script.continuous(map.hotReload)

balltze.addEventListener("frame", function()
    forge.onFrame()
end)

return map

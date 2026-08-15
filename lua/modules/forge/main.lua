local script = require "script"
local sleep = script.sleep
local engine = Engine
local constants = require "forgeIsland.constants"
local monitorMenu = require "forgeIsland.menus.monitorMenu"
local inspect = require "inspect"
local logger = Balltze.logger

local forge = require "forge.forge"

-- Configure Forge constants
forge.constants.bipeds.monitor = constants.bipeds.monitor
forge.constants.bipeds.player = constants.bipeds.player
forge.constants.tagCollections.forgeObjects = constants.tagCollections.forgeObjects
forge.constants.weaponHudInterfaces.monitorCrosshair =
    constants.weaponHudInterfaces.monitorCrosshair

local function sortedKeys(tbl)
    local keys = {}
    for key in pairs(tbl or {}) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b)
        return tostring(a):lower() < tostring(b):lower()
    end)
    return keys
end

---@param objectsMenu table
---@param objectsDatabase table
---@return table[]
local function buildPlaceOptions(objectsMenu, objectsDatabase)
    local options = {}
    local usedLabels = {}
    local root = (objectsMenu and objectsMenu.root) or {}

    for _, categoryName in ipairs(sortedKeys(root)) do
        local categoryNode = root[categoryName]
        if type(categoryNode) == "table" then
            for _, entryName in ipairs(sortedKeys(categoryNode)) do
                if not usedLabels[entryName] then
                    usedLabels[entryName] = true
                    local entryPath = objectsDatabase[entryName]
                    options[#options + 1] = {
                        label = entryName,
                        click = function()
                            logger.debug("Place option selected: {} ({})", entryName,
                                         entryPath or "unknown")
                        end,
                        focus = function()
                            logger.debug("Focused place option: {}", entryName)
                        end
                    }
                end
            end
        end
    end

    return options
end

forge.callbacks.launchMonitorMenu = function(mode)
    logger.debug("Launching monitor menu with mode={}", mode)

    if mode == "place" then
        local objectsMenu, objectsDatabase = forge.getAvailableForgeObjectsMenu()
        local placeOptions = buildPlaceOptions(objectsMenu, objectsDatabase)
        monitorMenu.setOptions(placeOptions)
        monitorMenu:launch()
        return
    end

    monitorMenu.setOptions()
    monitorMenu:launch()
end

local map = {}

local isGameDedicated = engine.game.getGameConnectionType() == "networkClient"

function map.main()
    forge.load()
    Balltze.logger.info("Welcome to Forge Island!")
    if DebugMode then
        forge.swapPlayerBiped(0, "monitor")
        forge.callbacks.launchMonitorMenu("place")
        --engine.uiWidget.launchWidget(constants.menus.forge.handle.value)
        Balltze.logger.debug("{}", inspect(forge.getAvailableForgeObjectsMenu()))
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

return map

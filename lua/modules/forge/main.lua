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

local function isMirroredLeaf(node, label)
    if type(node) ~= "table" then
        return false
    end
    local keys = sortedKeys(node)
    if #keys ~= 1 or keys[1] ~= label then
        return false
    end
    local child = node[label]
    return type(child) == "table" and next(child) == nil
end

local function placeSelectedObject(itemLabel, tagHandle, playerIndex)
    if not tagHandle then
        logger.debug("Place object: missing tag handle for {}", itemLabel)
        return false
    end

    local player = engine.player.getPlayer(playerIndex or 0)
    local playerBiped = nil
    if player and player.unitHandle and player.unitHandle.value then
        playerBiped = engine.object.getObject(player.unitHandle.value, "biped")
    end

    local position = {x = 0, y = 0, z = 0}
    if playerBiped then
        position = {
            x = playerBiped.position.x,
            y = playerBiped.position.y,
            z = playerBiped.position.z
        }
    end

    local objectHandle = engine.object.createObject(tagHandle, nil, position)
    if not objectHandle then
        logger.debug("Place object: unable to spawn {}", itemLabel)
        return false
    end

    local objectHandleValue = objectHandle.value or objectHandle
    if playerBiped and playerBiped.handle and playerBiped.handle.value then
        local ok, err = pcall(function()
            engine.gameState.attachObject(objectHandleValue, nil, playerBiped.handle.value, nil)
        end)
        if not ok then
            logger.debug("Place object attach failed for {}: {}", itemLabel, err)
        end
    end

    forge.setAttachedObject(playerIndex or 0, objectHandleValue)
    logger.debug("Place object selected: {} ({})", itemLabel,
                 objectHandleValue or "unknown")

    engine.uiWidget.closeWidget()

    return true
end

---@param objectsMenu table
---@param objectsDatabase table
---@return fun(): table[] buildOptions
local function createPlaceMenuNavigator(objectsMenu, objectsDatabase)
    local rootNode = (objectsMenu and objectsMenu.root) or {}
    local pathStack = {rootNode}
    local labelStack = {}

    local function currentNode()
        return pathStack[#pathStack] or rootNode
    end

    local function goBack()
        if #pathStack > 1 then
            table.remove(pathStack)
            table.remove(labelStack)
        end
    end

    local function tryEnter(label)
        local node = currentNode()[label]
        if type(node) ~= "table" then
            return false
        end
        if next(node) == nil or isMirroredLeaf(node, label) then
            return false
        end
        pathStack[#pathStack + 1] = node
        labelStack[#labelStack + 1] = label
        return true
    end

    local function buildOptions()
        local options = {}
        local node = currentNode()

        if #pathStack > 1 then
            options[#options + 1] = {
                label = "< BACK",
                click = function()
                    goBack()
                    monitorMenu.setOptions(buildOptions())
                end,
                focus = function()
                    logger.debug("Place menu: go back")
                end
            }
        end

        for _, label in ipairs(sortedKeys(node)) do
            local entryNode = node[label]
            local canEnter = type(entryNode) == "table" and next(entryNode) ~= nil and
                not isMirroredLeaf(entryNode, label)
            local entryPath = objectsDatabase[label]
            local itemLabel = label
            local itemDisplayLabel = tostring(label):upper()
            local itemCanEnter = canEnter
            local itemEntryPath = entryPath

            options[#options + 1] = {
                label = itemDisplayLabel,
                click = function()
                    if itemCanEnter then
                        tryEnter(itemLabel)
                        monitorMenu.setOptions(buildOptions())
                        return
                    end

                    local tagHandle = itemEntryPath
                    local selectedPlayerIndex = engine.player.getPlayer() and
                        engine.player.getPlayer().localPlayerIndex or 0

                    if not placeSelectedObject(itemLabel, tagHandle, selectedPlayerIndex) then
                        logger.debug("Place option selected: {} ({})", itemLabel,
                                     tagHandle or "unknown")
                    end
                end,
                focus = function()
                    if itemCanEnter then
                        logger.debug("Place category: {}", itemLabel)
                    else
                        logger.debug("Place object: {}", itemLabel)
                    end
                end
            }
        end

        return options
    end

    return buildOptions
end

forge.callbacks.launchMonitorMenu = function(mode)
    logger.debug("Launching monitor menu with mode={}", mode)

    if mode == "place" then
        local objectsMenu, objectsDatabase = forge.getAvailableForgeObjectsMenu()
        local buildPlaceOptions = createPlaceMenuNavigator(objectsMenu, objectsDatabase)
        local placeOptions = buildPlaceOptions()
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

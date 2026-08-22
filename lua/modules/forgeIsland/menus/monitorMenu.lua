---@diagnostic disable: inject-field
local forge = require "forge.forge"
local constants = require "forgeIsland.constants"
local engine = Engine
local balltze = Balltze
local logger = balltze.logger
local component = require "ui.component"
local spinner = require "ui.spinner"
local list = require "ui.list"
local bar = require "ui.bar"

local monitorMenuComponent = component.new(constants.menus.monitor.handle.value)
local menuTitle = component.new(monitorMenuComponent:get("monitor_menu_title"))
local scrollBar = bar.new(monitorMenuComponent:get("scroll"), "scroll")
local optionsList = list.new(monitorMenuComponent:get("options"))
optionsList:scrollable(false)
optionsList:setScrollBar(scrollBar)
local budgetBackground = component.new(monitorMenuComponent:get("budget_background"))
local budgetBar = bar.new(budgetBackground:get("budget_bar"), "progress")
local description = component.new(monitorMenuComponent:get("description"))

local defaultOptionsData = {
    {
        label = "ROTATION SNAP",
        -- values = {"OFF", "5°", "15°", "30°", "45°", "90°"},
        values = {"OFF", "5", "15", "30", "45", "90"},
        value = "OFF",
        change = function(value)
            logger.debug("Rotation snap set to {}", value)
        end,
        focus = function()
            description:setText("CAUSES ALL OBJECT ROTATION TO SNAP TO\r\nMULTIPLES OF THIS ANGLE.")
        end
    },
    {
        label = "DELETE BY PALETTE",
        click = function(value)
            logger.debug("Delete by palette clicked")
        end,
        focus = function()
            description:setText("SELECT A PALETTE TO DELETE.")
        end
    },
    {
        label = "UNLOCK ALL",
        click = function(value)
            logger.debug("Unlock all clicked")
        end,
        focus = function()
            description:setText("UNLOCK ALL OBJECTS THAT ARE CURRENTLY\r\nLOCKED.")
        end
    }
}

local optionsData = defaultOptionsData

---@param optionData table
---@param optionIndex number
---@return uiComponentListItem
local function toListItem(optionData, optionIndex)
    local hideArrows = not optionData.values or #optionData.values <= 1
    local item = {
        label = optionData.label,
        component = spinner,
        values = optionData.values,
        value = optionData.value,
        onScroll = function(value)
            optionData.value = value
            if optionData.change then
                optionData.change(value)
            end
        end,
        onFocus = function()
            if optionData.focus then
                optionData.focus()
            end
        end,
        onClick = function()
            if optionData.click then
                optionData.click()
            end
        end,
        onRender = function(uiComponent, item)
            if uiComponent.type == "spinner" then
                ---@cast uiComponent uiComponentSpinner
                uiComponent:hideArrows(hideArrows)
            end
        end
    }
    if hideArrows then
        item.onScroll = nil
    end
    return item
end

local monitorMenu = {component = monitorMenuComponent}

---@param nextOptionsData? table[]
function monitorMenu.setOptions(nextOptionsData)
    optionsData = nextOptionsData or defaultOptionsData
    local listItems = {}
    for optionIndex, optionData in ipairs(optionsData) do
        listItems[optionIndex] = toListItem(optionData, optionIndex)
    end
    optionsList:setItems(listItems)
end

monitorMenuComponent:onOpen(function()
    logger.debug("Monitor menu opened")
    monitorMenu.setOptions(optionsData)
    description:setText("WELCOME TO FORGE!")
    budgetBar:setValue(0.2)
end)

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

        monitorMenu.component:onClose(function()
            if #pathStack > 1 then
                goBack()
                monitorMenu.setOptions(buildOptions())
                return false
            end
        end)
        -- if #pathStack > 1 then
        --    options[#options + 1] = {
        --        label = "< BACK",
        --        click = function()
        --            goBack()
        --            monitorMenu.setOptions(buildOptions())
        --        end,
        --        focus = function()
        --            logger.debug("Place menu: go back")
        --        end
        --    }
        -- end

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
                    local selectedPlayerIndex = engine.player.getLocalPlayerHandle(engine.player
                                                                                       .getPlayer()
                                                                                       .localPlayerIndex)
                                                    .index

                    if not forge.placeObject(itemLabel, tagHandle, selectedPlayerIndex) then
                        logger.debug("Place option selected: {} ({})", itemLabel,
                                     tagHandle or "unknown")
                    else
                        engine.uiWidget.closeWidget()
                    end
                end,
                focus = function()
                    if itemCanEnter then
                       description:setText "SELECT AN OBJECT FROM THIS GROUP."
                    else
                       description:setText "PLACE THIS OBJECT."
                    end
                end
            }
        end

        return options
    end

    return buildOptions
end

function monitorMenu.launch(mode)
    if mode == "place" then
        menuTitle:setText("PLACE OBJECT")
        local objectsMenu, objectsDatabase = forge.getAvailableForgeObjectsMenu()
        local buildPlaceOptions = createPlaceMenuNavigator(objectsMenu, objectsDatabase)
        local placeOptions = buildPlaceOptions()
        monitorMenu.setOptions(placeOptions)
        monitorMenu.component:launch()
        return
    end

    menuTitle:setText("SPECIAL TOOLS")
    monitorMenu.setOptions()
    monitorMenu.component:launch()
    monitorMenu.component:onClose(function()
    end)
end

return monitorMenu

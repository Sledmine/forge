---@diagnostic disable: inject-field
local constants = require "forgeIsland.constants"
local component = require "ui.component"
local spinner = require "ui.spinner"
local list = require "ui.list"
local bar = require "ui.bar"

local monitorMenu = component.new(constants.menus.monitor.handle.value)
local scrollBar = bar.new(monitorMenu:get("scroll"), "scroll")
local optionsList = list.new(monitorMenu:get("options"))
optionsList:scrollable(false)
optionsList:setScrollBar(scrollBar)
local budgetBackground = component.new(monitorMenu:get("budget_background"))
local budgetBar = bar.new(budgetBackground:get("budget_bar"), "progress")
local description = component.new(monitorMenu:get("description"))

local defaultOptionsData = {
    {
        label = "ROTATION SNAP",
        --values = {"OFF", "5°", "15°", "30°", "45°", "90°"},
        values = {"OFF", "5", "15", "30", "45", "90"},
        value = "OFF",
        change = function(value)
            Balltze.logger.debug("Rotation snap set to {}", value)
        end,
        focus = function()
            description:setText("CAUSES ALL OBJECT ROTATION TO SNAP TO\r\nMULTIPLES OF THIS ANGLE.")
        end
    },
    {
        label = "DELETE BY PALETTE",
        click = function(value)
            Balltze.logger.debug("Delete by palette clicked")
        end,
        focus = function()
            description:setText("SELECT A PALETTE TO DELETE.")
        end
    },
    {
        label = "UNLOCK ALL",
        click = function(value)
            Balltze.logger.debug("Unlock all clicked")
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

---@param nextOptionsData? table[]
function monitorMenu.setOptions(nextOptionsData)
    optionsData = nextOptionsData or defaultOptionsData
    local listItems = {}
    for optionIndex, optionData in ipairs(optionsData) do
        listItems[optionIndex] = toListItem(optionData, optionIndex)
    end
    optionsList:setItems(listItems)
end

monitorMenu:onOpen(function()
    Balltze.logger.debug("Monitor menu opened")
    monitorMenu.setOptions(optionsData)
    description:setText("WELCOME TO FORGE!")
    budgetBar:setValue(0.2)
end)

return monitorMenu

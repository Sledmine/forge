local constants = require "forgeIsland.constants"
local component = require "ui.component"
local spinner = require "ui.spinner"
local bar = require "ui.bar"

local monitorMenu = component.new(constants.menus.monitor.handle.value)
local options = component.new(monitorMenu:get("options"))
local budgetBackground = component.new(monitorMenu:get("budget_background"))
local budgetBar = bar.new(budgetBackground:get("budget_bar"), "progress")
local description = component.new(monitorMenu:get("description"))

local elements = {}
local elementsData = {
    option_1 = {
        label = "ROTATION SNAP",
        values = {"OFF", "5", "15", "30", "45", "90"},
        value = "OFF",
        change = function(value)
            Balltze.logger.debug("Rotation snap set to {}", value)
        end,
        focus = function()
            description:setText("Sets monitor object rotation snap step.")
        end
    },
    option_2 = {
        label = "DELETE BY PALETTE",
        values = {"OFF", "ON"},
        value = "OFF",
        change = function(value)
            Balltze.logger.debug("Delete by palette set to {}", value)
        end,
        focus = function()
            description:setText("Deletes every spawned object from the current palette selection.")
        end
    },
    option_3 = {
        label = "UNLOCK ALL",
        values = {"NO", "YES"},
        value = "NO",
        change = function(value)
            Balltze.logger.debug("Unlock all set to {}", value)
        end,
        focus = function()
            description:setText("Unlocks every Forge object in the palette.")
        end
    }
}

monitorMenu:onOpen(function()
    Balltze.logger.debug("Monitor menu opened")

    for index = 1, 7 do
        local optionKey = "option_" .. index
        local optionHandle = options:get(optionKey)
        if optionHandle then
            local optionData = elementsData[optionKey]
            if optionData then
                local spin = spinner.new(optionHandle)
                spin:setText(optionData.label)
                spin:onScroll(function(value)
                    optionData.change(value)
                end)
                spin:onFocus(function()
                    optionData.focus()
                end)
                spin:onClick(function()
                    Balltze.logger.debug("Clicked on option {}", optionKey)
                end)
                elements[optionKey] = spin
            else
                local optionComponent = component.new(optionHandle)
                optionComponent:hide(true)
            end
        end
    end

    for optionKey, spin in pairs(elements) do
        local optionData = elementsData[optionKey]
        spin:setValues(optionData.values)
        spin:setValue(optionData.value)
    end

    description:setText("WELCOME TO FORGE!")
    budgetBar:setValue(0.2)
end)

return monitorMenu

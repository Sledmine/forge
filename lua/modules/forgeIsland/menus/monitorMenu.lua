local constants = require "forgeIsland.constants"
local component = require "ui.component"
local list = require "ui.list"
local button = require "ui.button"
local bar = require "ui.bar"

local monitorMenu = component.new(constants.menus.monitor.handle.value)
local options = list.new(monitorMenu:get("options"))
options:scrollable(false)
local budgetBackground = component.new(monitorMenu:get("budget_background"))
local budgetBar = bar.new(budgetBackground:get("budget_bar"), "progress")

monitorMenu:onOpen(function()
    Balltze.logger.debug("Monitor menu opened")
    options:setItems({
        {label = "ROTATION SNAP", value = 1},
        {label = "DELETE BY PALETTE", value = 2},
        {label = "UNLOCK ALL", value = 3}
    })
    budgetBar:setValue(0.2)
end)

return monitorMenu

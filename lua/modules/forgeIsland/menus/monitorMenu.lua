local component = require "ui.component"
local list = require "ui.list"
local button = require "ui.button"
local constants = require "forgeIsland.constants"

local monitorMenu = component.new(constants.menus.monitor.handle.value)
local options = list.new(monitorMenu:get("options"))
options:scrollable(false)

monitorMenu:onOpen(function()
    Balltze.logger.debug("Monitor menu opened")
    options:setItems({
        {label = "ROTATION SNAP", value = 1},
        {label = "DELETE BY PALETTE", value = 2},
        {label = "UNLOCK ALL", value = 3},
        {label = "CHINGUE A SU MADRE EL AMERICA", value = 3}
    })
end)

return monitorMenu

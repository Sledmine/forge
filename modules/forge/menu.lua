------------------------------------------------------------------------------
-- Forge Menus
-- Sledmine
-- Menus handler
------------------------------------------------------------------------------
local triggers = require "forge.triggers"

local menu = {}

--- Perform a child widget update on the specified widget
---@param widget tag
---@param widgetCount number
function menu.update(widget, widgetCount)
    local uiWidget = blam.uiWidgetDefinition(widget.id)
    if (uiWidget) then
        -- Update child widgets count
        uiWidget.childWidgetsCount = widgetCount
        -- Send new event type to force render
        uiWidget.eventType = 33
    end
end

--- Perform a close event on the specified widget
---@param widget tag
function menu.close(widget)
    -- Send new event type to force close
    local uiWidget = blam.uiWidgetDefinition(widget.id)
    if (uiWidget) then
        uiWidget.eventType = 33
    else
        error("UI Widget " .. tostring(widget.path) .. " was not able to be modified.")
    end
end

--- Stop the execution of a forced event
---@param widget tag
function menu.stop(widget)
    -- Send new event type to stop event
    local uiWidget = blam.uiWidgetDefinition(widget.id)
    if (uiWidget) then
        uiWidget.eventType = 32
    else
        error("UI Widget " .. tostring(widget.path) .. " was not able to be modified.")
    end
end

--- Get selected text from unicode string list
---@param triggersName string
---@param triggersCount number
---@param unicodeStringList tag
function menu.get(triggersName, triggersCount, unicodeStringList)
    local menuPressedButton = triggers.get(triggersName, triggersCount)
    local elementsList = blam.unicodeStringList(unicodeStringList.id)
    return elementsList.stringList[menuPressedButton]
end

return menu

------------------------------------------------------------------------------
-- Forge Menus
-- Sledmine
-- Menus handler
------------------------------------------------------------------------------
local triggers = require "forge.triggers"

local menu = {}

--- Perform a child widget update on the specified widget
---@param widgetPath string
---@param widgetCount number
function menu.update(widgetPath, widgetCount)
    local uiWidget = blam.uiWidgetDefinition(widgetPath)
    if (uiWidget) then
        -- Update child widgets count
        uiWidget.childWidgetsCount = widgetCount
        -- Send new event type to force render
        uiWidget.eventType = 33
    end
end

--- Perform a close event on the specified widget
---@param widgetPath string
function menu.close(widgetPath)
    -- Send new event type to force close
    local uiWidget = blam.uiWidgetDefinition(widgetPath)
    if (uiWidget) then
        uiWidget.eventType = 33
    else
        error("UI Widget " .. tostring(widgetPath) .. " was not able to be modified.")
    end
end

--- Stop the execution of a forced event
---@param widgetPath string
function menu.stop(widgetPath)
    -- Send new event type to stop event
    local uiWidget = blam.uiWidgetDefinition(widgetPath)
    if (uiWidget) then
        uiWidget.eventType = 32
    else
        error("UI Widget " .. tostring(widgetPath) .. " was not able to be modified.")
    end
end

function menu.get(triggersName, triggersCount, unicodeStringListPath)
    local menuPressedButton = triggers.get(triggersName, triggersCount)
    local elementsList = blam.unicodeStringList(unicodeStringListPath)
    return elementsList.stringList[menuPressedButton]
end

return menu

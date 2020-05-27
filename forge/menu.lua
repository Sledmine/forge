------------------------------------------------------------------------------
-- Forge Menus
-- Author: Sledmine
-- Version: 1.0
-- Menus handler
------------------------------------------------------------------------------

local blam = require 'lua-blam'

local menu = {}

---@param widgetPath string
---@param widgetCount number
function menu.update(widgetPath, widgetCount)
    blam.uiWidgetDefinition(
        get_tag('ui_widget_definition', widgetPath),
        {
            childWidgetsCount = widgetCount + 2,
            -- Send new event type to force re render
            eventType = 33
        }
    )
end

---@param widgetPath string
function menu.close(widgetPath)
    blam.uiWidgetDefinition(
        get_tag('ui_widget_definition', widgetPath),
        {
            -- Send new event type to force close
            eventType = 33
        }
    )
end

---@param widgetPath string
function menu.stopClose(widgetPath)
    blam.uiWidgetDefinition(
        get_tag('ui_widget_definition', widgetPath),
        {
            -- Send new event type to stop close
            eventType = 32
        }
    )
end

---@param widgetPath string
function menu.stopUpdate(widgetPath)
    blam.uiWidgetDefinition(
        get_tag('ui_widget_definition', widgetPath),
        {
            -- Stop forced re-render
            eventType = 32
        }
    )
end

return menu

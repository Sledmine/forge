------------------------------------------------------------------------------
-- Forge Menus
-- Author: Sledmine
-- Version: 1.0
-- Menus handler
------------------------------------------------------------------------------

local blam = require 'luablam'

local menu = {}

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

function menu.close(widgetPath, widgetCount)
    blam.uiWidgetDefinition(
        get_tag('ui_widget_definition', widgetPath),
        {
            -- Send new event type to force close
            eventType = 33
        }
    )
end

function menu.stopClose(widgetPath, widgetCount)
    blam.uiWidgetDefinition(
        get_tag('ui_widget_definition', widgetPath),
        {
            -- Send new event type to stop close
            eventType = 32
        }
    )
end

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

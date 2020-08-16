------------------------------------------------------------------------------
-- Forge Menus
-- Author: Sledmine
-- Version: 1.0
-- Menus handler
------------------------------------------------------------------------------

local menu = {}

---@param widgetPath string
---@param widgetCount number
function menu.update(widgetPath, widgetCount)
    blam.uiWidgetDefinition(
        get_tag('ui_widget_definition', widgetPath),
        {
            childWidgetsCount = widgetCount,
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

--- Stop the execution of a forced event
---@param widgetPath string
function menu.stop(widgetPath)
    blam.uiWidgetDefinition(
        get_tag('ui_widget_definition', widgetPath),
        {
            -- Send new event type to stop close
            eventType = 32
        }
    )
end


return menu

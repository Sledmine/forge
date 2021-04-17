------------------------------------------------------------------------------
-- Interface
-- Author: Sledmine
-- Interface handler for UI Widgets
------------------------------------------------------------------------------

local interface = {}

-- TODO Add unit testing for this
---@param triggerName string
---@param triggersNumber number
---@return number
function interface.triggers(triggerName, triggersNumber)
    local restoreTriggersState = (function()
        for triggerIndex = 1, triggersNumber do
            -- TODO Replace this function with set global
            execute_script("set " .. triggerName .. "_trigger_" .. triggerIndex .. " false")
        end
    end)
    for i = 1, triggersNumber do
        if (get_global(triggerName .. "_trigger_" .. i)) then
            restoreTriggersState()
            return i
        end
    end
    return nil
end

--- Perform a child widget update on the specified widget
---@param widget tag
---@param widgetCount number
function interface.update(widget, widgetCount)
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
function interface.close(widget)
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
function interface.stop(widget)
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
function interface.get(triggersName, triggersCount, unicodeStringList)
    local menuPressedButton = interface.triggers(triggersName, triggersCount)
    local elementsList = blam.unicodeStringList(unicodeStringList.id)
    return elementsList.stringList[menuPressedButton]
end

-- Every hook executes a callback
function interface.hook(variable, callback, ...)
    if (get_global(variable)) then
        execute_script("set " .. variable .. " false")
        callback(...)
    end
end

return interface

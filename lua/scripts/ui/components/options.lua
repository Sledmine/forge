local widget = require "lua.scripts.widget"
local constants = require "lua.scripts.ui.components.constants"

---@class optionsProps
---@field name string
---@field alignment? "vertical" | "horizontal"
---@field [1]? invaderWidgetChildWidget[]
---@field childs? invaderWidgetChildWidget[]
---@field description? string Tag path for description to display
---@field func? string
---@field branch? boolean
---@field conditionalWidgets? invaderWidgetConditionalWidget[]
---@field dataInput? string
---@field eventsToChildren? boolean
---@field useItems? boolean
---@field width? number
---@field height? number
---@field bitmap? string
---@field isDebug? boolean

---Options list component, scroll trough elements using dpad, etc
---@param props optionsProps
---@return string
return function(props)
    local name = props.name
    local alignment = props.alignment or "vertical"
    local childWidgets = props[1] or props.childs
    local description = props.description
    local isDebug = props.isDebug == nil and false or props.isDebug

    local widgetPath = widget.path .. name .. "_options.ui_widget_definition"
    local bounds
    if props.width or props.height then
        bounds = widget.bounds(0, 0, props.height or 0, props.width or 0)
    end
    local isHorizontal = alignment == "horizontal"
    ---@type invaderWidget
    local wid = {
        widget_type = "column_list",
        -- For debug purposes
        background_bitmap = isDebug and "insurrection/ui/bitmaps/solid_green.bitmap" or props.bitmap,
        bounds = bounds or constants.getScreenBounds(),
        flags = {
            pass_unhandled_events_to_focused_child = true,
            dpad_up_down_tabs_thru_children = not isHorizontal,
            dpad_left_right_tabs_thru_children = isHorizontal,
            pass_handled_events_to_all_children = props.eventsToChildren or false
        },
        child_widgets = childWidgets or {},
        event_handlers = {
            {
                event_type = "dpad_left"
            },
            {
                event_type = "dpad_right"
            },
            {
                event_type = "dpad_up"
            },
            {
                event_type = "dpad_down"
            }
        },
        extended_description_widget = description or ".ui_widget_definition",
        conditional_widgets = props.conditionalWidgets
    }
    if props.useItems then
        wid.flags.dpad_up_down_tabs_thru_children = false
        wid.flags.dpad_left_right_tabs_thru_children = false
        wid.flags.dpad_up_down_tabs_thru_list_items = not isHorizontal
        wid.flags.dpad_left_right_tabs_thru_list_items = isHorizontal
    end
    if props.dataInput then
        wid.game_data_inputs = {{["function"] = props.dataInput}}
    end
    if props.func or props.branch then
        wid.event_handlers = {
            {
                event_type = "created",
                flags = {run_function = true, try_to_branch_on_failure = props.branch ~= nil},
                ["function"] = props.func
            }
        }
    end
    widget.createV2(widgetPath, wid)
    return widgetPath
end

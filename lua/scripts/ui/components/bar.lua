local widget = require "lua.scripts.widget"
local constants = require "lua.scripts.ui.components.constants"

---@class barProps
---@field name string
---@field orientation "horizontal" | "vertical
---@field type "scroll" | "progress"
---@field size number
---@field thickness? number
---@field color? string

---Bar component
---@param props barProps
---@return string
return function(props)
    local name = props.name
    local orientation = props.orientation or "horizontal"
    local size = props.size or 100
    local type = props.type or "progress"
    local thickness = props.thickness or 3
    if type == "scroll" then
        thickness = 1
    end
    local color = widget.color(props.color or constants.color.palette.contrast)

    local widgetValuePath = widget.path .. name .. "_bar_value.ui_widget_definition"
    ---@type invaderWidget
    local value = {
        widget_type = "container",
        bounds = widget.bounds(0, 0, thickness, size),
        background_bitmap = [[[shm]/halo_4/ui/shell/forge_menu/bitmaps/menu/progress_bar_color.bitmap]],
    }
    if orientation == "vertical" then
        value.bounds = widget.bounds(0, 0, size, thickness)
    end
    widget.createV2(widgetValuePath, value)

    local widgetPath = widget.path .. name .. "_bar.ui_widget_definition"
    ---@type invaderWidget
    local bar = {
        widget_type = "container",
        bounds = widget.bounds(0, 0, type == "scroll" and 1 or thickness, size),
        background_bitmap = color,
        child_widgets = {
            {
                widget_tag = widgetValuePath,
                vertical_offset = 0,
                horizontal_offset = 0,
            }
        }
    }
    if type == "scroll" then
        bar.child_widgets[1].vertical_offset = orientation == "horizontal" and -1 or 0
        bar.child_widgets[1].horizontal_offset = orientation == "vertical" and -1 or 0
    end
    if orientation == "vertical" then
        bar.bounds = widget.bounds(0, 0, size, type == "scroll" and thickness or size)
    end
    widget.createV2(widgetPath, bar)
    return widgetPath
end

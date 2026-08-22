local widget = require "lua.scripts.widget"
local constants = require "lua.scripts.ui.components.constants"

---@class barProps
---@field name string
---@field orientation "horizontal" | "vertical
---@field type "scroll" | "progress"
---@field size number
---@field thickness? number
---@field color? string
---@field barColor? string

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
        thickness = props.thickness or 1
    end
    
    local color = widget.color(props.color or constants.color.palette.contrast)
    local width = orientation == "horizontal" and size or thickness
    local height = orientation == "horizontal" and thickness or size
    local valueBitmap = [[[shm]/halo_4/ui/shell/forge_menu/bitmaps/menu/progress_bar_color.bitmap]]
    if props.barColor then
        valueBitmap = widget.color(props.barColor)
    end

    local widgetValuePath = widget.path .. name .. "_bar_value.ui_widget_definition"
    ---@type invaderWidget
    local value = {
        widget_type = "container",
        bounds = widget.bounds(0, 0, height, width),
        background_bitmap = valueBitmap,
    }
    widget.createV2(widgetValuePath, value)

    local widgetPath = widget.path .. name .. "_bar.ui_widget_definition"
    ---@type invaderWidget
    local bar = {
        widget_type = "container",
        bounds = widget.bounds(0, 0, height, width),
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
        --bar.child_widgets[1].vertical_offset = orientation == "horizontal" and -1 or 0
        --bar.child_widgets[1].horizontal_offset = orientation == "vertical" and -1 or 0
    end

    widget.createV2(widgetPath, bar)
    return widgetPath
end

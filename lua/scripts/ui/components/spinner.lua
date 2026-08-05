local widget = require "lua.scripts.widget"
local button = require "lua.scripts.ui.components.button"
local ustr = require "lua.scripts.modules.ustr"
local constants = require "lua.scripts.ui.components.constants"

---@class spinnerProps
---@field name string
---@field text string
---@field value string
---@field variant? "normal" | "large" | "forge"
---@field length? number
---@field back? boolean
---@field opens? string
---@field script? string
---@field branch? boolean
---@field func? string | string[]
---@field select? boolean
---@field justification? "left_justify" | "center_justify" | "right_justify"
---@field close? boolean
---@field order? "top" | "mid" | "bottom"
---@field transparent? boolean
---@field textOffset? number
---@field childs? invaderWidgetChildWidget[]
---@field width? number
---@field height? number
---@field noHandlers? boolean

---Spinner component
---@param props spinnerProps
---@return string
return function(props)
    local name = props.name
    local text = props.text
    local value = props.value
    local variant = props.variant or "normal"
    local width = props.width or constants.components.button[variant].width
    local height = props.height or constants.components.button[variant].height
    --local sizeFactor = variant == "large" and 4 or 3
    local sizeFactor = 4
    local length = props.length or #value * sizeFactor

    local arrowLeftPath = widget.path .. "buttons/" .. name ..
                              "_spinner_arrow_left.ui_widget_definition"
    ---@type invaderWidget
    local arrowWidget = {
        widget_type = "text_box",
        background_bitmap = constants.components.arrow.left.bitmap,
        bounds = widget.bounds(0, 0, constants.components.arrow.left.height,
                               constants.components.arrow.left.width),
        event_handlers = {
            {event_type = "a_button"},
            {
                event_type = "left_mouse",
                ["function"] = "mouse_emit_accept_event",
                flags = {run_function = true}
            }
        }
    }
    widget.createV2(arrowLeftPath, arrowWidget)
    local arrowRightPath = widget.path .. "buttons/" .. name ..
                               "_spinner_arrow_right.ui_widget_definition"
    arrowWidget.background_bitmap = constants.components.arrow.right.bitmap
    arrowWidget.bounds = widget.bounds(0, 0, constants.components.arrow.right.height,
                                       constants.components.arrow.right.width)
    widget.createV2(arrowRightPath, arrowWidget)

    local stringsTagPath = widget.path .. "strings/" .. name .. "_spinner.unicode_string_list"
    ustr(stringsTagPath, {value})

    local rightArrowX = width - 20
    local valueX = rightArrowX - length - 64
    local leftArrowX = valueX - 1

    -- Generate label
    local labelPath = widget.path .. "buttons/" .. name .. "_spinner_label.ui_widget_definition"
    ---@type invaderWidget
    local labelWidget = {
        widget_type = "text_box",
        bounds = widget.bounds(0, 0, height, width),
        text_label_unicode_strings_list = stringsTagPath,
        string_list_index = 0,
        justification = "center_justify",
        text_color = constants.color.text,
        text_font = constants.fonts.button,
        vert_offset = 5,
        horiz_offset = valueX - 4
    }
    widget.createV2(labelPath, labelWidget)

    local childWidgets = props.childs and {table.unpack(props.childs)} or {}
    childWidgets[#childWidgets + 1] = {widget_tag = arrowLeftPath, horizontal_offset = leftArrowX, vertical_offset = 4}
    childWidgets[#childWidgets + 1] = {widget_tag = arrowRightPath, horizontal_offset = rightArrowX, vertical_offset = 4}
    childWidgets[#childWidgets + 1] = {widget_tag = labelPath}

    local widgetPath = button {
        name = name .. "_spinner",
        text = text,
        back = props.back,
        opens = props.opens,
        script = props.script,
        branch = props.branch,
        func = props.func,
        select = props.select,
        justification = props.justification,
        close = props.close,
        variant = variant,
        order = props.order,
        transparent = props.transparent,
        textOffset = props.textOffset,
        width = width,
        height = height,
        noHandlers = props.noHandlers,
        childs = childWidgets
    }

    return widgetPath
end

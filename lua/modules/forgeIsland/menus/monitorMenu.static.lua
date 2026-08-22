local widget = require "lua.scripts.widget"
local strmem = widget.strmem
local container = require "lua.scripts.ui.components.container"
local header = require "lua.scripts.ui.components.header"
local constants = require "lua.scripts.ui.components.constants"
local options = require "lua.scripts.ui.components.options"
local button = require "lua.scripts.ui.components.button"
local pos = constants.position
local label = require "lua.scripts.ui.components.label"
local wrapper = require "lua.scripts.ui.components.wrapper"
local bar = require "lua.scripts.ui.components.bar"
-- local image = require "lua.scripts.ui.components.image"
local spinner = require "lua.scripts.ui.components.spinner"

widget.init [[[shm]/halo_4/ui/menus/monitor/]]

local layout = widget.align("vertical", 26, 0, 28, 1)

local menuName = "monitor_menu"

local posY = 133

local buttonOptions = {}

for index = 1, 7 do
    buttonOptions[index] = {
        spinner {
            name = menuName .. "_option_" .. index,
            text = strmem(32, "OPTION " .. index),
            value = strmem(16, "OFF", "left"),
            variant = "forge",
            length = 32
        },
        layout()
    }
end

local monitorMenuPath = container {
    name = menuName,
    childs = {
        {
            wrapper {
                name = menuName .. "_budget_background",
                bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_budget_background.bitmap]],
                width = 179,
                height = 33,
                childs = {
                    {
                        label {
                            name = menuName .. "_budget_title",
                            text = strmem(64, "BUDGET"),
                            -- variant = "title"
                            color = "white"
                        },
                        5,
                        -3
                    },
                    {
                        label {
                            name = menuName .. "_budget_value",
                            text = strmem(32, "00000 / 00000", "left"),
                            width = 171,
                            justify = "right",
                            color = "white"
                        },
                        0,
                        -3
                    },
                    {
                        bar {
                            name = menuName .. "_budget",
                            orientation = "horizontal",
                            type = "progress",
                            size = 171,
                            thickness = 9,
                            color = "#05050596"
                        },
                        4,
                        19
                    }
                }
            },
            628,
            posY
        },
        {
            wrapper {
                name = menuName .. "_background",
                bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_background.bitmap]],
                width = 261,
                height = 257
            },
            546,
            posY + 36
        },
        {label {name = menuName .. "_title", text = strmem(64, "SPECIAL TOOLS")}, 575, 168},
        {
            bar {
                name = menuName .. "_scroll",
                orientation = "vertical",
                type = "scroll",
                size = 186,
                thickness = 2,
                barColor = "#b0d9ffff"
            },
            810,
            posY + 64
        },
        {
            options {
                name = menuName,
                layout = "vertical",
                width = 261,
                height = 257,
                childs = buttonOptions
            },
            546,
            posY + 36
        },
        {
            label {
                name = menuName .. "_description",
                text = strmem(128, "WELCOME TO FORGE!"),
                height = 32
            },
            577,
            posY + 252
        }
    }
}

widget.global(monitorMenuPath, "ui/shell/multiplayer.ui_widget_collection")

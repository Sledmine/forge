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

widget.init [[[shm]/halo_4/ui/menus/monitor/]]

local layout = widget.align("vertical", 26, 0, 28, 1)

local menuName = "monitor_menu"

local monitorMenuPath = container {
    name = menuName,
    childs = {
        {
            wrapper {
                name = menuName .. "_background",
                bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_background.bitmap]],
                width = 261,
                height = 257
            },
            546,
            169
        },
        {label {name = menuName .. "_title", text = strmem(64, "SPECIAL TOOLS")}, 575, 168},
        {
            options {
                name = menuName,
                layout = "vertical",
                -- bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_background.bitmap]],
                width = 261,
                height = 257,
                childs = {
                    {
                        button {name = "option_1", text = strmem(64, "Option 1"), variant = "forge"},
                        layout()
                    },
                    {
                        button {name = "option_2", text = strmem(64, "Option 2"), variant = "forge"},
                        layout()
                    },
                    {
                        button {name = "option_3", text = strmem(64, "Option 3"), variant = "forge"},
                        layout()
                    },
                    {
                        button {name = "option_4", text = strmem(64, "Option 4"), variant = "forge"},
                        layout()
                    },
                    {
                        button {name = "option_5", text = strmem(64, "Option 5"), variant = "forge"},
                        layout()
                    },
                    {
                        button {name = "option_6", text = strmem(64, "Option 6"), variant = "forge"},
                        layout()
                    },
                    {
                        button {name = "option_7", text = strmem(64, "Option 7"), variant = "forge"},
                        layout()
                    }
                }
            },
            546,
            169
        },
        {
            label {name = menuName .. "description", text = strmem(128, "Welcome to Forge!")},
            577,
            385
        }
    }
}

widget.global(monitorMenuPath, "ui/shell/multiplayer.ui_widget_collection")

local widget = require "lua.scripts.widget"
local strmem = widget.strmem
local container = require "lua.scripts.ui.components.container"
local header = require "lua.scripts.ui.components.header"
local constants = require "lua.scripts.ui.components.constants"
local options = require "lua.scripts.ui.components.options"
local button = require "lua.scripts.ui.components.button"
local pos = constants.position

widget.init [[[shm]/halo_4/ui/menus/forge/]]

local layout = widget.align("vertical", 21, pos.options.x, pos.options.y, 1)

local menuName = "forge_menu"

local pauseMenuPath = container {
    name = menuName,
    background = "transparent",
    childs = {
        {
            header {
                name = menuName,
                title = "FORGE",
                subtitle = "LOAD A FORGE MAP OR CONFIGURE SETTINGS"
            },
            pos.header.x,
            pos.header.y
        },
        {constants.components.mapInfo.path, 541, 117},
        {
            options {
                name = menuName,
                layout = "vertical",
                func = "mp_pause_menu_open",
                description = nil,
                childs = {
                    {button {name = "map_1", text = strmem(64), order = "top"}, layout()},
                    {button {name = "map_2", text = strmem(64), order = "mid"}, layout()},
                    {button {name = "map_3", text = strmem(64), order = "mid"}, layout()},
                    {button {name = "map_4", text = strmem(64), order = "mid"}, layout()},
                    {button {name = "map_5", text = strmem(64), order = "mid"}, layout()},
                    {button {name = "map_6", text = strmem(64), order = "mid"}, layout()},
                    {button {name = "map_7", text = strmem(64), order = "mid"}, layout()},
                    {button {name = "map_8", text = strmem(64), order = "bottom"}, layout()}
                }
            }
        }
    }
}

widget.global(pauseMenuPath, "ui/shell/multiplayer.ui_widget_collection")

local widget = require "lua.scripts.widget"
local strmem = widget.strmem
local container = require "lua.scripts.ui.components.container"
local header = require "lua.scripts.ui.components.header"
local constants = require "lua.scripts.ui.components.constants"
local options = require "lua.scripts.ui.components.options"
local button = require "lua.scripts.ui.components.button"
local pos = constants.position
local label = require "lua.scripts.ui.components.label"


widget.init [[[shm]/halo_4/ui/menus/pause/]]

local layout = widget.align("vertical", 21, pos.options.x, pos.options.y, 1)

local pauseMenuPath = container {
    name = "pause_menu",
    background = "transparent",
    childs = {
        {
            header {
                name = "pause_menu",
                title = "PAUSE MENU",
                subtitle = "GAME PAUSED"
            },
            pos.header.x,
            pos.header.y
        },
        {
            options {
                name = "pause_menu_options",
                layout = "vertical",
                func = "mp_pause_menu_open",
                description = nil,
                childs = {
                    {
                        button {
                            name = "resume_game",
                            text = "Resume game",
                            order = "top",
                            close = true
                        },
                        layout()
                    },
                    -- {
                    --    button {
                    --        name = "game_options",
                    --        order = "mid",
                    --        text = "Game options"
                    --    },
                    --    layout()
                    -- },
                    -- {
                    --    button {
                    --        name = "settings",
                    --        order = "mid",
                    --        text = "Settings"
                    --    },
                    --    layout()
                    -- },
                    {
                        button {
                            name = "exit",
                            order = "bottom",
                            text = "Leave game",
                            func = "mp_game_player_quit"
                        },
                        layout()
                    },
                    {
                        button {
                            name = "forge_mode",
                            text = strmem(64, "Go To Edit mode"),
                            order = "top"
                        },
                        layout(6)
                    },
                    {
                        button {
                            name = "forge",
                            text = "Forge",
                            opens = [[[shm]/halo_4/ui/menus/forge/forge_menu.ui_widget_definition]],
                            order = "bottom"
                        },
                        layout(6)
                    }
                }
            }
        },
        {
            label {
                name = "description",
                text = strmem(128, "Welcome to Forge!")
            }
        }
    }
}

os.execute("cp -f tags/" .. pauseMenuPath .. " tags/ui/shell/multiplayer_game/pause_game/1p_pause_game.ui_widget_definition")

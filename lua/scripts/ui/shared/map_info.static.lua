local widget = require "lua.scripts.widget"
local strmem = widget.strmem
local image = require "lua.scripts.ui.components.image"
local wrapper = require "lua.scripts.ui.components.wrapper"
local label = require "lua.scripts.ui.components.label"

widget.init [[[shm]/halo_4/ui/menus/shared/]]

return wrapper {
    name = "map_info",
    width = 283,
    height = 153,
    childs = {
        {
            image {
                name = "forge_preview",
                bitmap = [[[shm]/halo_4/ui/shell/pause_game/current_map_information/bitmaps/forge_preview.bitmap]],
                width = 283,
                height = 153
            },
            0,
            0
        },
        {label {name = "map_name", text = strmem(64, "MAP NAME"), variant = "title"}, 10, 100},
        {label {name = "author", text = strmem(64, "AUTHOR"), variant = "subtitle"}, 10, 120},
        {
            label {
                name = "version",
                text = strmem(64, "VERSION", "left"),
                justify = "right",
                width = 274
            },
            0,
            120
        },
        {
            label {name = "description", text = strmem(64, "DESCRIPTION"), variant = "subtitle"},
            10,
            140
        }
    }
}

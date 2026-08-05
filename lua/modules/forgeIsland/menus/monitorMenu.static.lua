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
local image = require "lua.scripts.ui.components.image"

widget.init [[[shm]/halo_4/ui/menus/monitor/]]

local layout = widget.align("vertical", 26, 0, 28, 1)

local menuName = "monitor_menu"

local posY = 133

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
            options {
                name = menuName,
                layout = "vertical",
                -- bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_background.bitmap]],
                width = 261,
                height = 257,
                childs = {
                    {
                        button {
                            name = "option_1",
                            text = strmem(64, "Option 1"),
                            variant = "forge",
                            childs = {
                                {
                                    label {
                                        name = "option_1_value",
                                        text = strmem(16, "Value", "left"),
                                        width = 70,
                                        justify = "right"
                                    },
                                    160,
                                    -1
                                },
                                {
                                    image {
                                        name = "option_1_arrow_left",
                                        bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_button_arrow_left.bitmap]],
                                        width = 16,
                                        height = 16
                                    },
                                    234,
                                    5
                                },
                                {
                                    image {
                                        name = "option_1_arrow_right",
                                        bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_button_arrow_right.bitmap]],
                                        width = 16,
                                        height = 16
                                    },
                                    244,
                                    5
                                }
                            }
                        },
                        layout()
                    },
                    {
                        button {
                            name = "option_2",
                            text = strmem(64, "Option 2"),
                            variant = "forge",
                            childs = {
                                {
                                    label {
                                        name = "option_2_value",
                                        text = strmem(16, "Value", "left"),
                                        width = 70,
                                        justify = "right"
                                    },
                                    160,
                                    -1
                                },
                                {
                                    image {
                                        name = "option_2_arrow_left",
                                        bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_button_arrow_left.bitmap]],
                                        width = 16,
                                        height = 16
                                    },
                                    234,
                                    5
                                },
                                {
                                    image {
                                        name = "option_2_arrow_right",
                                        bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_button_arrow_right.bitmap]],
                                        width = 16,
                                        height = 16
                                    },
                                    244,
                                    5
                                }
                            }
                        },
                        layout()
                    },
                    {
                        button {
                            name = "option_3",
                            text = strmem(64, "Option 3"),
                            variant = "forge",
                            childs = {
                                {
                                    label {
                                        name = "option_3_value",
                                        text = strmem(16, "Value", "left"),
                                        width = 70,
                                        justify = "right"
                                    },
                                    160,
                                    -1
                                },
                                {
                                    image {
                                        name = "option_3_arrow_left",
                                        bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_button_arrow_left.bitmap]],
                                        width = 16,
                                        height = 16
                                    },
                                    234,
                                    5
                                },
                                {
                                    image {
                                        name = "option_3_arrow_right",
                                        bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_button_arrow_right.bitmap]],
                                        width = 16,
                                        height = 16
                                    },
                                    244,
                                    5
                                }
                            }
                        },
                        layout()
                    },
                    {
                        button {
                            name = "option_4",
                            text = strmem(64, "Option 4"),
                            variant = "forge",
                            childs = {
                                {
                                    label {
                                        name = "option_4_value",
                                        text = strmem(16, "Value", "left"),
                                        width = 70,
                                        justify = "right"
                                    },
                                    160,
                                    -1
                                },
                                {
                                    image {
                                        name = "option_4_arrow_left",
                                        bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_button_arrow_left.bitmap]],
                                        width = 16,
                                        height = 16
                                    },
                                    234,
                                    5
                                },
                                {
                                    image {
                                        name = "option_4_arrow_right",
                                        bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_button_arrow_right.bitmap]],
                                        width = 16,
                                        height = 16
                                    },
                                    244,
                                    5
                                }
                            }
                        },
                        layout()
                    },
                    {
                        button {
                            name = "option_5",
                            text = strmem(64, "Option 5"),
                            variant = "forge",
                            childs = {
                                {
                                    label {
                                        name = "option_5_value",
                                        text = strmem(16, "Value", "left"),
                                        width = 70,
                                        justify = "right"
                                    },
                                    160,
                                    -1
                                },
                                {
                                    image {
                                        name = "option_5_arrow_left",
                                        bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_button_arrow_left.bitmap]],
                                        width = 16,
                                        height = 16
                                    },
                                    234,
                                    5
                                },
                                {
                                    image {
                                        name = "option_5_arrow_right",
                                        bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_button_arrow_right.bitmap]],
                                        width = 16,
                                        height = 16
                                    },
                                    244,
                                    5
                                }
                            }
                        },
                        layout()
                    },
                    {
                        button {
                            name = "option_6",
                            text = strmem(64, "Option 6"),
                            variant = "forge",
                            childs = {
                                {
                                    label {
                                        name = "option_6_value",
                                        text = strmem(16, "Value", "left"),
                                        width = 70,
                                        justify = "right"
                                    },
                                    160,
                                    -1
                                },
                                {
                                    image {
                                        name = "option_6_arrow_left",
                                        bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_button_arrow_left.bitmap]],
                                        width = 16,
                                        height = 16
                                    },
                                    234,
                                    5
                                },
                                {
                                    image {
                                        name = "option_6_arrow_right",
                                        bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_button_arrow_right.bitmap]],
                                        width = 16,
                                        height = 16
                                    },
                                    244,
                                    5
                                }
                            }
                        },
                        layout()
                    },
                    {
                        button {
                            name = "option_7",
                            text = strmem(64, "Option 7"),
                            variant = "forge",
                            childs = {
                                {
                                    label {
                                        name = "option_7_value",
                                        text = strmem(16, "Value", "left"),
                                        width = 70,
                                        justify = "right"
                                    },
                                    160,
                                    -1
                                },
                                {
                                    image {
                                        name = "option_7_arrow_left",
                                        bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_button_arrow_left.bitmap]],
                                        width = 16,
                                        height = 16
                                    },
                                    234,
                                    5
                                },
                                {
                                    image {
                                        name = "option_7_arrow_right",
                                        bitmap = [[[shm]/halo_4/ui/bitmaps/monitor_menu_button_arrow_right.bitmap]],
                                        width = 16,
                                        height = 16
                                    },
                                    244,
                                    5
                                }
                            }
                        },
                        layout()
                    }
                }
            },
            546,
            posY + 36
        },
        {
            label {name = menuName .. "_description", text = strmem(128, "WELCOME TO FORGE!")},
            577,
            posY + 252
        }
    }
}

widget.global(monitorMenuPath, "ui/shell/multiplayer.ui_widget_collection")

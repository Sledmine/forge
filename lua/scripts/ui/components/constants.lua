local width = 854
local height = 480

return {
    color = {
        text = "1, 0.576471, 0.788235, 1",
        title = "1, 0.8, 0.9, 1",
        placeholder = "1, 0.5, 0.5, 0.5",
        subtitle = "1, 0.576471, 0.788235, 1",
        selected = "1, 0.55, 0.55, 0.55",
        nameplate = "1, 0.8, 0.8, 0.8",
        info = "1, 0.427451, 0.564706, 0.803922",
        focus = "1, 0.592157, 0.698039, 0.878431",
        warning = "1, 1, 0.756863, 0.027451",
        error = "1, 0.8, 0, 0",
        palette = {
            primary = "#3d6cc1",
            secondary = "#6d90cd",
            primaryHighlight = "#97b2e0",
            secondaryHighlight = "#2996ff",
            contrast = "##4a6f98"
        }
    },
    opacity = {primary = 12.5, secondary = 34.5},
    fonts = {
        text = [[[shm]/halo_4/ui/blender_pro_12.font]], -- small
        title = [[[shm]/halo_4/ui/fonts/blender_pro_medium_20.font]], -- ticker
        subtitle = [[[shm]/halo_4/ui/blender_pro_15.font]], -- gamespy/subtitle
        button = [[[shm]/halo_4/ui/blender_pro_12.font]], -- large
        shadow = [[[shm]/halo_4/ui/blender_pro_15.font]]
    },
    screen = {width = width, height = height},
    getScreenBounds = function()
        return "0, 0, " .. height .. ", " .. width
    end,
    position = {
        header = {x = 47, y = 50},
        options = {x = 30, y = 117},
        back = {x = 685, y = 416},
        backLeft = {x = 20, y = 416},
        action = {x = 444, y = 416},
        footer = {x = 20, y = 330},
        logo = {x = 202, y = 105},
        nameplate = {x = 641, y = 20},
        version = {x = 0, y = 460},
    },
    components = {
        mapInfo = {
            path = [[[shm]/halo_4/ui/menus/shared/map_info_wrapper.ui_widget_definition]]
        },
        version = {
            path = [[insurrection/ui/shared/version/insurrection_version_footer.ui_widget_definition]]
        },
        button = {
            normal = {
                width = 238,
                height = 21,
                top = {
                    bitmap = [[[shm]/halo_4/ui/shell/bitmaps/top_button.bitmap]]
                },
                bitmap = [[[shm]/halo_4/ui/shell/bitmaps/normal_button.bitmap]],
                mid = {
                    bitmap = [[[shm]/halo_4/ui/shell/bitmaps/mid_button.bitmap]]
                },
                bottom = {
                    bitmap = [[[shm]/halo_4/ui/shell/bitmaps/bot_button.bitmap]]
                }
            },
            large = {
                width = 389,
                height = 24,
                bitmap = [[insurrection/ui/bitmaps/large_button.bitmap]]
            }
        },
        arrow = {
            left = {width = 16, height = 16, bitmap = [[insurrection/ui/bitmaps/arrow_left.bitmap]]},
            right = {
                width = 16,
                height = 16,
                bitmap = [[insurrection/ui/bitmaps/arrow_right.bitmap]]
            },
            up = {width = 10, height = 8, bitmap = [[insurrection/ui/bitmaps/arrow_up.bitmap]]},
            down = {width = 10, height = 8, bitmap = [[insurrection/ui/bitmaps/arrow_down.bitmap]]}
        },
        complexButton = {
            normal = {
                width = 120,
                height = 110,
                bitmap = [[insurrection/ui/bitmaps/complex_button.bitmap]]
            },
            vertical = {
                width = 144,
                height = 158,
                bitmap = [[insurrection/ui/bitmaps/vertical_complex_button.bitmap]]
            },
            horizontal = {
                width = 149,
                height = 36,
                bitmap = [[insurrection/ui/bitmaps/horizontal_complex_button.bitmap]]
            },
            horizontal_small = {
                width = 103,
                height = 36,
                bitmap = [[insurrection/ui/bitmaps/horizontal_complex_small_button.bitmap]]
            }
        },
        input = {
            small = {
                width = 184,
                height = 23,
                bitmap = [[insurrection/ui/bitmaps/input_small.bitmap]]
            },
            normal = {width = 187, height = 34, bitmap = [[insurrection/ui/bitmaps/input.bitmap]]}
        },
        overlay = {
            path = [[insurrection/ui/menus/overlay/overlay_graft.ui_widget_definition]]
        }
    }
}

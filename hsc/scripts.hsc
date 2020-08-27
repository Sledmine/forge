
;; Menu UI Effects
(script static void menu_blur_off
    (begin
        (show_hud true)
        (cinematic_stop)
    )
)

(script static void menu_blur_on
    (begin
        (show_hud false)
        (cinematic_screen_effect_start true)
        (cinematic_screen_effect_set_convolution 3 1 1 2 0)
        (cinematic_screen_effect_start false)
    )
)

;; Menus Widget Hooks
;; Function name: set_<menu_name>_menu_hook
;; Value name: <menu_name>_menu_hook

;; Maps Menu
(script static void set_maps_menu_hook
    (set maps_menu_hook true)
)

;; Forge Menu
(script static void set_forge_menu_hook
    (set forge_menu_hook true)
)

(script static void set_forge_menu_close_hook
    (set forge_menu_close_hook true)
)

(script static void set_map_vote_menu_hook
    (set map_vote_menu_hook true)
)

(script static void set_map_vote_menu_close_hook
    (set map_vote_menu_close_hook true)
)

;; Loading Menu
(script static void set_loading_menu_close_hook
    (begin
        (set loading_menu_close_hook true)
        (show_hud true)
        (cinematic_stop)
    )
)

;; Menus Widget Triggers
;; Function name: set_<menu_name>_trigger
;; Value name: <menu_name>_trigger

;; Maps Menu
(script static void set_maps_menu_trigger_1
    (set maps_menu_trigger_1 true)
)
(script static void set_maps_menu_trigger_2
    (set maps_menu_trigger_2 true)
)
(script static void set_maps_menu_trigger_3
    (set maps_menu_trigger_3 true)
)
(script static void set_maps_menu_trigger_4
    (set maps_menu_trigger_4 true)
)
(script static void set_maps_menu_trigger_5
    (set maps_menu_trigger_5 true)
)
(script static void set_maps_menu_trigger_6
    (set maps_menu_trigger_6 true)
)
(script static void set_maps_menu_trigger_7
    (set maps_menu_trigger_7 true)
)
(script static void set_maps_menu_trigger_8
    (set maps_menu_trigger_8 true)
)
;; List related
(script static void set_maps_menu_trigger_9
    (set maps_menu_trigger_9 true)
)
(script static void set_maps_menu_trigger_10
    (set maps_menu_trigger_10 true)
)

;; Forge Menu
(script static void set_forge_menu_trigger_1
    (set forge_menu_trigger_1 true)
)
(script static void set_forge_menu_trigger_2
    (set forge_menu_trigger_2 true)
)
(script static void set_forge_menu_trigger_3
    (set forge_menu_trigger_3 true)
)
(script static void set_forge_menu_trigger_4
    (set forge_menu_trigger_4 true)
)
(script static void set_forge_menu_trigger_5
    (set forge_menu_trigger_5 true)
)
(script static void set_forge_menu_trigger_6
    (set forge_menu_trigger_6 true)
)
(script static void set_forge_menu_trigger_7
    (set forge_menu_trigger_7 true)
)
(script static void set_forge_menu_trigger_8
    (set forge_menu_trigger_8 true)
)
(script static void set_forge_menu_trigger_9
    (set forge_menu_trigger_9 true)
)

;; Map Vote Menu
(script static void set_map_vote_menu_trigger_1
    (set map_vote_menu_trigger_1 true)
)
(script static void set_map_vote_menu_trigger_2
    (set map_vote_menu_trigger_2 true)
)
(script static void set_map_vote_menu_trigger_3
    (set map_vote_menu_trigger_3 true)
)
(script static void set_map_vote_menu_trigger_4
    (set map_vote_menu_trigger_4 true)
)
(script static void set_map_vote_menu_trigger_5
    (set map_vote_menu_trigger_5 true)
)

;; Auto respawn system
(script continuous respawn_vehicles
    (begin
        (if (volume_test_object "vehicle_respawn_scan" "v1")
            (object_create_anew "v1")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v2")
            (object_create_anew "v2")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v3")
            (object_create_anew "v3")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v4")
            (object_create_anew "v4")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v5")
            (object_create_anew "v5")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v6")
            (object_create_anew "v6")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v7")
            (object_create_anew "v7")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v8")
            (object_create_anew "v8")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v9")
            (object_create_anew "v9")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v10")
            (object_create_anew "v10")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v11")
            (object_create_anew "v11")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v12")
            (object_create_anew "v12")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v13")
            (object_create_anew "v13")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v14")
            (object_create_anew "v14")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v15")
            (object_create_anew "v15")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v16")
            (object_create_anew "v16")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v17")
            (object_create_anew "v17")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v18")
            (object_create_anew "v18")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v19")
            (object_create_anew "v19")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v20")
            (object_create_anew "v20")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v21")
            (object_create_anew "v21")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v22")
            (object_create_anew "v22")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v23")
            (object_create_anew "v23")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v24")
            (object_create_anew "v24")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v25")
            (object_create_anew "v25")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v26")
            (object_create_anew "v26")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v27")
            (object_create_anew "v27")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v28")
            (object_create_anew "v28")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v29")
            (object_create_anew "v29")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v30")
            (object_create_anew "v30")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v31")
            (object_create_anew "v31")
        )
        (if (volume_test_object "vehicle_respawn_scan" "v32")
            (object_create_anew "v32")
        )
    )
)

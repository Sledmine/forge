;; Menus Widget Hooks
;; Function name: set_<menu_name>_menu_hook
;; Value name: <menu_name>_menu_hook

;; Menu widgets hooks
(global boolean maps_menu_hook false)
(global boolean forge_menu_hook false)
(global boolean map_vote_menu_hook false)
;; Dynamic general menu hooks
(global boolean general_menu_forced_event_hook false)
(global boolean settings_menu_hook false)
(global boolean bipeds_menu_hook false)

(global boolean forge_menu_close_hook false)
(global boolean loading_menu_close_hook false)
(global boolean map_vote_menu_close_hook false)

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

;; General Menu
(script static void gm_forced_event
    (set general_menu_forced_event_hook true)
)

;; Settings Menu
(script static void set_settings_menu_hook
    (set settings_menu_hook true)
)

;; Bipeds Menu
(script static void set_biped_menu_hook
    (set bipeds_menu_hook true)
)
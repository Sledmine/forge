------------------------------------------------------------------------------
-- Forge Constants
-- Sledmine
-- Constants values
------------------------------------------------------------------------------
local core = require "forge.core"

local constants = {}

-- Constant forge values
constants.maximumBudget = 1024
constants.minimumZSpawnPoint = -18.69
constants.scenerysTagCollectionPath = core.findTag(map .. "_scenerys", tagClasses.tagCollection)

-- Constant ui widget definition values
constants.maximumSidebarSize = 249
constants.minimumSidebarSize = 40
constants.maximumProgressBarSize = 171
constants.maximumLoadingProgressBarSize = 422

local fontTagPath, fontTagId = core.findTag("blender_pro_12", tagClasses.font)
constants.hudFont = fontTagId

local projectileTagPath, projectileTagId = core.findTag("mp_needle", tagClasses.projectile)
constants.forgeProjectileSelector = projectileTagPath

-- Constante forge requests data
constants.requests = {
    spawnObject = {
        actionType = "SPAWN_FORGE_OBJECT",
        requestType = "#s",
        requestFormat = {
            {"requestType"},
            {"tagId", "I4"},
            {"x", "f"},
            {"y", "f"},
            {"z", "f"},
            {"yaw"},
            {"pitch"},
            {"roll"},
            {"remoteId", "I4"}
        }
    },
    updateObject = {
        actionType = "UPDATE_FORGE_OBJECT",
        requestType = "#u",
        requestFormat = {
            {"requestType"},
            {"objectId"},
            {"x", "f"},
            {"y", "f"},
            {"z", "f"},
            {"yaw"},
            {"pitch"},
            {"roll"}
        }
    },
    deleteObject = {
        actionType = "DELETE_FORGE_OBJECT",
        requestType = "#d",
        requestFormat = {
            {"requestType"},
            {"objectId"}
        }
    },
    flushForge = {actionType = "FLUSH_FORGE"},
    loadMapScreen = {
        actionType = "LOAD_MAP_SCREEN",
        requestType = "#lm",
        requestFormat = {
            {"requestType"},
            {"objectCount"},
            {"mapName"},
            {"mapDescription"}
        }
    },
    loadVoteMapScreen = {
        actionType = "LOAD_VOTE_MAP_SCREEN",
        requestType = "#lv",
        requestFormat = {{"requestType"}}
    },
    appendVoteMap = {
        actionType = "APPEND_VOTE_MAP",
        requestType = "#av",
        requestFormat = {
            {"requestType"},
            {"mapName"},
            {"mapGametype"},
            {"mapIndex"}
        }
    },
    sendMapVote = {
        actionType = "SEND_MAP_VOTE",
        requestType = "#v",
        requestFormat = {
            {"requestType"},
            {"mapVoted"}
        }
    },
    sendTotalMapVotes = {
        actionType = "SEND_TOTAL_MAP_VOTES",
        requestType = "#sv",
        requestFormat = {
            {"requestType"},
            {"votesMap1"},
            {"votesMap2"},
            {"votesMap3"},
            {"votesMap4"}
        }
    },
    flushVotes = {actionType = "FLUSH_VOTES"}
}

-- Biped tag definitions
constants.bipeds = {
    monitor = core.findTag("monitor", tagClasses.biped),
    spartan = core.findTag("cyborg_mp", tagClasses.biped)
}

-- Weapon hud tag definitions
constants.weaponHudInterfaces = {
    forgeCrosshair = core.findTag("ui\\hud\\forge", tagClasses.weaponHudInterface)
}

constants.bitmaps = {
    forgeLoadingProgress0 = "[shm]\\halo_4\\ui\\shell\\loading_menu\\bitmaps\\forge_loading_progress0",
    forgeLoadingProgress1 = "[shm]\\halo_4\\ui\\shell\\loading_menu\\bitmaps\\forge_loading_progress1"
}

-- UI widget definitions
constants.uiWidgetDefinitions = {
    forgeMenu = "[shm]\\halo_4\\ui\\shell\\forge_menu\\forge_menu",
    voteMenu = "[shm]\\halo_4\\ui\\shell\\map_vote_menu\\map_vote_menu",
    objectsList = "[shm]\\halo_4\\ui\\shell\\forge_menu\\category_menu\\category_list",
    amountBar = "[shm]\\halo_4\\ui\\shell\\forge_menu\\budget_dialog\\budget_progress_bar",
    loadingMenu = "[shm]\\halo_4\\ui\\shell\\loading_menu\\loading_menu",
    loadingAnimation = "[shm]\\halo_4\\ui\\shell\\loading_menu\\loading_menu_progress_animation",
    loadingProgress = "[shm]\\halo_4\\ui\\shell\\loading_menu\\loading_progress_bar",
    loadoutMenu = "[shm]\\halo_4\\ui\\shell\\loadout_menu\\loadout_menu_no_background",
    mapsList = "[shm]\\halo_4\\ui\\shell\\pause_game\\forge_options_menu\\maps_list\\maps_list",
    sidebar = "[shm]\\halo_4\\ui\\shell\\pause_game\\forge_options_menu\\forge_map_list_sidebar_bar"
}

-- Unicode string definitions
constants.unicodeStrings = {
    budgetCount = "[shm]\\halo_4\\ui\\shell\\forge_menu\\strings\\budget_count",
    forgeList = "[shm]\\halo_4\\ui\\shell\\forge_menu\\strings\\elements_text",
    votingList = "[shm]\\halo_4\\ui\\shell\\map_vote_menu\\strings\\vote_maps_names",
    votingCountList = "[shm]\\halo_4\\ui\\shell\\map_vote_menu\\strings\\vote_maps_count",
    pagination = "[shm]\\halo_4\\ui\\shell\\forge_menu\\strings\\pagination",
    mapsList = "[shm]\\halo_4\\ui\\shell\\pause_game\\strings\\maps_name",
    pauseGameStrings = "[shm]\\halo_4\\ui\\shell\\pause_game\\strings\\titles_and_headers"
}

return constants

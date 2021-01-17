------------------------------------------------------------------------------
-- Forge Constants
-- Sledmine
-- Constants values
------------------------------------------------------------------------------
local core = require "forge.core"

local constants = {}

-- Constant core values
-- constants.myGamesFolder = read_string(0x00647830)
constants.mouseInputAddress = 0x64C73C 
--constants.mouseInputAddress = read_dword(0x12CDFF50)

-- Constant Forge values
constants.requestSeparator = "&"
constants.maximumBudget = 1024
constants.minimumZSpawnPoint = -18.69
constants.forgeSelectorOffset = 0.33
constants.forgeSelectorVelocity = 15
constants.scenerysTagCollectionPath = core.findTag(map:gsub("_dev", ""):gsub("_beta", "") .. "_objects", tagClasses.tagCollection)

-- Constant UI widget definition values
constants.maximumSidebarSize = 249
constants.minimumSidebarSize = 40
constants.maximumProgressBarSize = 171
constants.maximumLoadingProgressBarSize = 422

local fontTagPath, fontTagId = core.findTag("blender_pro_medium_12", tagClasses.font)
constants.hudFontTagId = fontTagId

local projectileTagPath, projectileTagId = core.findTag("forge", tagClasses.projectile)
constants.forgeProjectilePath = projectileTagPath
constants.forgeProjectileTagId = projectileTagId

--[[local swordProjectilePath, swordProjectileTagId = core.findTag("slash", tagClasses.projectile)
constants.swordProjectilePath = projectileTagPath
constants.swordProjectileTagId = projectileTagId]]

-- Constant Forge requests data
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
            {"mapName"}
        }
    },
    setMapAuthor = {
        actionType = "SET_MAP_AUTHOR",
        requestType = "#ma",
        requestFormat = {
            {"requestType"},
            {"mapAuthor"}
        }
    },
    setMapDescription = {
        actionType = "SET_MAP_DESCRIPTION",
        requestType = "#md",
        requestFormat = {
            {"requestType"},
            {"mapDescription"}
        }
    },
    loadVoteMapScreen = {
        actionType = "LOAD_VOTE_MAP_SCREEN",
        requestType = "#lv",
        requestFormat = {{"requestType"}}
    },
    appendVoteMap = {
        actionType = "APPEND_MAP_VOTE",
        requestType = "#av",
        requestFormat = {
            {"requestType"},
            {"name"},
            {"gametype"},
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
    forgeCrosshair = core.findTag("ui\\hud\\forge", tagClasses.weaponHudInterface),
    forgeWeaponCrosshair = core.findTag("monitor\\forge", tagClasses.weaponHudInterface)
}

constants.bitmaps = {
    mapLoading0 = core.findTag("forge_loading_progress0", tagClasses.bitmap),
    mapLoading1 = core.findTag("forge_loading_progress1", tagClasses.bitmap),
    hudWeapons = core.findTag("hud_msg_icons_full", tagClasses.bitmap)
}

-- UI widget definitions
constants.uiWidgetDefinitions = {
    -- forgeMenu = "[shm]\\halo_4\\ui\\shell\\forge_menu\\forge_menu",
    forgeMenu = core.findTag("forge_menu", tagClasses.uiWidgetDefinition),
    voteMenu = "[shm]\\halo_4\\ui\\shell\\map_vote_menu\\map_vote_menu",
    voteMenuList = "[shm]\\halo_4\\ui\\shell\\map_vote_menu\\map_vote_menu_list\\vote_menu_list",
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
    forgeMenuElements = "[shm]\\halo_4\\ui\\shell\\forge_menu\\strings\\elements_text",
    votingMapsList = "[shm]\\halo_4\\ui\\shell\\map_vote_menu\\strings\\vote_maps_names",
    votingCountList = "[shm]\\halo_4\\ui\\shell\\map_vote_menu\\strings\\vote_maps_count",
    pagination = "[shm]\\halo_4\\ui\\shell\\forge_menu\\strings\\pagination",
    mapsList = "[shm]\\halo_4\\ui\\shell\\pause_game\\strings\\maps_name",
    pauseGameStrings = "[shm]\\halo_4\\ui\\shell\\pause_game\\strings\\titles_and_headers"
}

local monitorTag = blam.getTag(constants.bipeds.monitor, tagClasses.biped)
constants.monitorTagId = monitorTag.id

return constants

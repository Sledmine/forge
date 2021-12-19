------------------------------------------------------------------------------
-- Forge Constants
-- Sledmine
-- Constant values for different purposes
--[[ The idea behind this module is to gather all the data that does not change
 across runtime, so we can optimize getting data just once at map load time
 ]] ---------------------------------------------------------------------------
local core = require "forge.core"
local glue = require "glue"

local time = os.clock()

local constants = {}

-- Constant core values
-- constants.myGamesFolder = read_string(0x00647830)
constants.mouseInputAddress = 0x64C73C
constants.localPlayerAddress = 0x815918
-- Looks like the history/memory of the current widget loaded
-- It appears to work different on the main menu/ui
constants.currentWidgetIdAddress = 0x6B401C
-- constants.isWidgetOpenAddress = constants.currentWidgetIdAddress + 19
-- + 671 = New element??

-- Constant Forge values
constants.requestSeparator = "&"
constants.maximumObjectsBudget = 1024
constants.minimumZSpawnPoint = -18.69
constants.maximumZRenderShadow = -14.12
constants.minimumZMapLimit = -69.9
constants.maximumRenderShadowRadius = 7
constants.forgeSelectorOffset = 0.33
constants.forgeSelectorVelocity = 15

-- Map name should be the base project name, without build env variants
constants.absoluteMapName = map:gsub("_dev", ""):gsub("_beta", "")

-- Constant UI widget definition values
constants.maximumProgressBarSize = 171
constants.maxLoadingBarSize = 422

-- Constant gameplay values
constants.healthRegenerationAmount = 0.006

constants.hudFontTagId = core.findTag("blender_pro_medium_12", tagClasses.font).id
local forgeProjectile = core.findTag("forge", tagClasses.projectile)
constants.forgeProjectilePath = forgeProjectile.path
constants.forgeProjectileTagId = forgeProjectile.id
constants.forgeProjectileTagIndex = forgeProjectile.index
constants.fragGrenadeProjectileTagIndex = core.findTag("frag", tagClasses.projectile).index

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
            {"color"},
            {"teamIndex"},
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
            {"roll"},
            {"color"},
            {"teamIndex"}
        }
    },
    deleteObject = {
        actionType = "DELETE_FORGE_OBJECT",
        requestType = "#d",
        requestFormat = {{"requestType"}, {"objectId"}}
    },
    flushForge = {actionType = "FLUSH_FORGE"},
    loadMapScreen = {
        actionType = "LOAD_MAP_SCREEN",
        requestType = "#lm",
        requestFormat = {{"requestType"}, {"objectCount"}, {"mapName"}}
    },
    setMapAuthor = {
        actionType = "SET_MAP_AUTHOR",
        requestType = "#ma",
        requestFormat = {{"requestType"}, {"mapAuthor"}}
    },
    setMapDescription = {
        actionType = "SET_MAP_DESCRIPTION",
        requestType = "#md",
        requestFormat = {{"requestType"}, {"mapDescription"}}
    },
    loadVoteMapScreen = {
        actionType = "LOAD_VOTE_MAP_SCREEN",
        requestType = "#lv",
        requestFormat = {{"requestType"}}
    },
    appendVoteMap = {
        actionType = "APPEND_MAP_VOTE",
        requestType = "#av",
        requestFormat = {{"requestType"}, {"name"}, {"gametype"}, {"mapIndex"}}
    },
    sendMapVote = {
        actionType = "SEND_MAP_VOTE",
        requestType = "#v",
        requestFormat = {{"requestType"}, {"mapVoted"}}
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
    flushVotes = {actionType = "FLUSH_VOTES"},
    selectBiped = {
        actionType = "SELECT_BIPED",
        requestType = "#sb",
        requestFormat = {{"requestType"}, {"bipedTagId"}}
    }
}

-- Tag Collections ID
constants.tagCollections = {
    forgeObjectsTagId = core.findTag(constants.absoluteMapName .. "_objects",
                                     tagClasses.tagCollection).id
}

-- Biped Names
constants.bipedNames = {}
-- Biped Tags ID
constants.bipeds = {}
for _, tag in pairs(core.findTagsList("characters", tagClasses.biped)) do
    if (tag) then
        local pathSplit = glue.string.split(tag.path, "\\")
        local tagName = pathSplit[#pathSplit]
        if (not tagName:find("monitor")) then
            constants.bipedNames[core.toSentenceCase(tagName)] = tag.id
        end

        local bipedName = core.toCamelCase(tagName:gsub("_mp", ""))
        constants.bipeds[bipedName .. "TagId"] = tag.id
    end
end

-- First Person Model Tags ID
constants.firstPersonHands = {}
for _, tag in pairs(core.findTagsList("characters", tagClasses.biped)) do
    if (tag) then
        local pathSplit = glue.string.split(tag.path, "\\")
        local tagName = pathSplit[#pathSplit]
        local tagNameFixed = core.toCamelCase(tagName):gsub("_mp", "")
        constants.bipeds[tagNameFixed .. "TagId"] = tag.id
        local pathToBiped = table.concat(glue.shift(pathSplit, #pathSplit, -1), "\\")
        local fpTagPath = pathToBiped .. "\\fp\\" .. tagName .. " fp"
        local fpTag = blam.getTag(fpTagPath, tagClasses.gbxmodel)
        if (fpTag) then
            constants.firstPersonHands[tagName] = fpTag.id
        end
    end
end
-- Hardcode specific sets of armours with a resusable fp
constants.firstPersonHands["mark vii"] = constants.firstPersonHands["mark vi"]

-- Weapon HUD Interface Tags ID
constants.weaponHudInterfaces = {
    forgeCrosshairTagId = core.findTag("ui\\hud\\forge", tagClasses.weaponHudInterface).id
}

-- Bitmap Tags ID
constants.bitmaps = {
    forgingIconFrame0TagId = core.findTag("forge_loading_progress0", tagClasses.bitmap).id,
    forgeIconFrame1TagId = core.findTag("forge_loading_progress1", tagClasses.bitmap).id,
    unitHudBackgroundTagId = core.findTag("combined\\hud_background", tagClasses.bitmap).id,
    dialogIconsTagId = core.findTag("bitmaps\\loading_orb", tagClasses.bitmap).id
}

-- UI Widget definitions
local uiWidgetDefinitions = {
    forgeMenu = core.findTag("forge_menu\\forge_menu", tagClasses.uiWidgetDefinition),
    objectsList = core.findTag("category_list", tagClasses.uiWidgetDefinition),
    voteMenu = core.findTag("map_vote_menu", tagClasses.uiWidgetDefinition),
    voteMenuList = core.findTag("vote_menu_list", tagClasses.uiWidgetDefinition),
    amountBar = core.findTag("budget_progress_bar", tagClasses.uiWidgetDefinition),
    loadingMenu = core.findTag("loading_menu", tagClasses.uiWidgetDefinition),
    loadingAnimation = core.findTag("loading_menu_progress_animation", tagClasses.uiWidgetDefinition),
    loadingProgress = core.findTag("loading_progress_bar", tagClasses.uiWidgetDefinition),
    mapsMenu = core.findTag("forge_options_menu\\forge_options_menu", tagClasses.uiWidgetDefinition),
    mapsList = core.findTag("maps_list", tagClasses.uiWidgetDefinition),
    actionsMenu = core.findTag("forge_actions_menu\\forge_actions_menu",
                               tagClasses.uiWidgetDefinition),
    generalMenu = core.findTag("general_menu\\general_menu", tagClasses.uiWidgetDefinition),
    generalMenuList = core.findTag("general_menu\\options\\options", tagClasses.uiWidgetDefinition),
    scrollBar = core.findTag("common\\scroll_bar", tagClasses.uiWidgetDefinition),
    scrollPosition = core.findTag("common\\scroll_position", tagClasses.uiWidgetDefinition),
    warningDialog = core.findTag("warning_dialog", tagClasses.uiWidgetDefinition)
}
constants.uiWidgetDefinitions = uiWidgetDefinitions

-- Unicode string definitions
local unicodeStrings = {
    budgetCountTagId = core.findTag("budget_count", tagClasses.unicodeStringList).id,
    forgeMenuElementsTagId = core.findTag("elements_text", tagClasses.unicodeStringList).id,
    votingMapsListTagId = core.findTag("vote_maps_names", tagClasses.unicodeStringList).id,
    votingCountListTagId = core.findTag("vote_maps_count", tagClasses.unicodeStringList).id,
    paginationTagId = core.findTag("pagination", tagClasses.unicodeStringList).id,
    mapsListTagId = core.findTag("maps_name", tagClasses.unicodeStringList).id,
    pauseGameStringsTagId = core.findTag("titles_and_headers", tagClasses.unicodeStringList).id,
    forgeControlsTagId = core.findTag("forge_controls", tagClasses.unicodeStringList).id,
    generalMenuHeaderTagId = core.findTag("general_menu\\strings\\header",
                                          tagClasses.unicodeStringList).id,
    generalMenuStringsTagId = core.findTag("general_menu\\strings\\options",
                                           tagClasses.unicodeStringList).id,
    generalMenuValueStringsTagId = core.findTag("general_menu\\strings\\values",
                                                tagClasses.unicodeStringList).id,
    dialogStringsId = core.findTag("dialog_menu\\strings\\header_and_message",
                                   tagClasses.unicodeStringList).id
}
constants.unicodeStrings = unicodeStrings

constants.hsc = {playSound = [[(begin (sound_impulse_start "%s" (list_get (players) %s) %s))]]}

constants.sounds = {
    landHardPlayerDamagePath = core.findTag("land_hard_plyr_dmg", tagClasses.sound).path,
    uiForwardPath = core.findTag("forward", tagClasses.sound).path
}

--[[local swordProjectileTagPath, swordProjectileTagIndex =
    core.findTag("slash", tagClasses.projectile)
constants.swordProjectileTagIndex = swordProjectileTagIndex]]

constants.colors = {
    white = "#FFFFFF",
    black = "#000000",
    red = "#FE0000",
    blue = "#0201E3",
    gray = "#707E71",
    yellow = "#FFFF01",
    green = "#00FF01",
    pink = "#FF56B9",
    purple = "#AB10F4",
    cyan = "#01FFFF",
    cobalt = "#6493ED",
    orange = "#FF7F00",
    teal = "#1ECC91",
    sage = "#006401",
    brown = "#603814",
    tan = "#C69C6C",
    maroon = "#9D0B0E",
    salmon = "#F5999E"
}

constants.colorsNumber = {
    constants.colors.white,
    constants.colors.black,
    constants.colors.red,
    constants.colors.blue,
    constants.colors.gray,
    constants.colors.yellow,
    constants.colors.green,
    constants.colors.pink,
    constants.colors.purple,
    constants.colors.cyan,
    constants.colors.cobalt,
    constants.colors.orange,
    constants.colors.teal,
    constants.colors.sage,
    constants.colors.brown,
    constants.colors.tan,
    constants.colors.maroon,
    constants.colors.salmon
}

-- Name to search in some tags that are ignored at hidding objects as spartan
constants.hideObjectsExceptions = {"stand", "teleporters"}
constants.objectsMigration = {
    ["[shm]\\halo_4\\scenery\\spawning\\vehicles\\warthog spawn\\warthog spawn"] = "[shm]\\halo_4\\scenery\\spawning\\vehicles\\warthogs\\warthog spawn\\warthog spawn",
    ["[shm]\\halo_4\\scenery\\spawning\\vehicles\\rocket warthog spawn\\rocket warthog spawn"] = "[shm]\\halo_4\\scenery\\spawning\\vehicles\\warthogs\\rocket warthog spawn\\rocket warthog spawn"
}

-- constants.teleportersChannels = {alpha = 0, bravo = 1, charly = 2, delta = 3, echo = }
constants.teleportersChannels = {
    "alpha",
    "bravo",
    "charly",
    "delta",
    "echo",
    "foxtrot",
    "golf",
    "hotel",
    "india",
    "juliett",
    "kilo"
}

dprint(string.format("Constants gathered, elapsed time: %.6f\n", os.clock() - time))

return constants

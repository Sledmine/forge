------------------------------------------------------------------------------
-- Forge Constants
-- Author: Sledmine
-- Version: 1.0
-- Constants values
------------------------------------------------------------------------------

local constants = {}

constants.maximumProgressBarSize = 171
constants.maximumLoadingProgressBarSize = 422
constants.maximumBudget = 1024
constants.minimumZSpawnPoint = -18.69
constants.maximumSidebarSize = 249
constants.minimumSidebarSize = 40

constants.scenarioPath = '[shm]\\halo_4\\maps\\forge_island\\forge_island'

constants.actionTypes = {
    SPAWN_OBJECT = 'SPAWN_OBJECT',
    UPDATE_OBJECT = 'UPDATE_OBJECT',
    DELETE_OBJECT = 'DELETE_OBJECT',
    LOAD_MAP_SCREEN = 'LOAD_MAP_SCREEN',
    FLUSH_FORGE = 'FLUSH_FORGE'
}

-- Request types definition
constants.requestTypes = {
    ['SPAWN_OBJECT'] = '#s',
    ['UPDATE_OBJECT'] = '#u',
    ['DELETE_OBJECT'] = '#d',
    ['LOAD_MAP_SCREEN'] = '#l',
    -- We have to provide reverse typing for fast coding
    ['#s'] = 'SPAWN_OBJECT',
    ['#u'] = 'UPDATE_OBJECT',
    ['#d'] = 'DELETE_OBJECT',
    ['#l'] = 'LOAD_MAP_SCREEN',
    ['#ff'] = 'FLUSH_FORGE'
}

constants.requestFormats = {
    ['SPAWN_OBJECT'] = {'requestType', 'tagId', 'x', 'y', 'z', 'yaw', 'pitch', 'roll', 'remoteId'},
    ['UPDATE_OBJECT'] = {'requestType','objectId', 'x', 'y', 'z', 'yaw', 'pitch', 'roll'},
    ['DELETE_OBJECT'] = {'requestType', 'objectId'},
    ['LOAD_MAP_SCREEN'] = {'requestType', 'objectCount'},
    ['FLUSH_FORGE'] = {'requestType'}
}

constants.compressionFormats = {
    ['SPAWN_OBJECT'] = {tagId = 'I4', x = 'f', y = 'f', z = 'f', remoteId = 'I4'},
    ['UPDATE_OBJECT'] = {x = 'f', y = 'f', z = 'f'},
    ['DELETE_OBJECT'] = {},
    ['LOAD_MAP_SCREEN'] = {},
    ['FLUSH_FORGE'] = {}
}

constants.testObjectPath = '[shm]\\halo_4\\scenery\\spawning\\vehicles\\scorpion spawn\\scorpion spawn'

-- Biped tag definitions
constants.bipeds = {
    monitor = '[shm]\\halo_4\\characters\\monitor\\monitor_mp',
    spartan = 'characters\\cyborg_mp\\cyborg_mp'
}

-- Weapon hud tag definitions
constants.weaponHudInterfaces = {
    forgeCrosshair = '[shm]\\halo_4\\ui\\hud\\forge'
}

-- Unicode string definitions
constants.unicodeStrings = {
    budgetCount = '[shm]\\halo_4\\ui\\shell\\forge_menu\\strings\\budget_count',
    forgeList = '[shm]\\halo_4\\ui\\shell\\forge_menu\\strings\\elements_text',
    pagination = '[shm]\\halo_4\\ui\\shell\\forge_menu\\strings\\pagination',
    mapsList = '[shm]\\halo_4\\ui\\shell\\pause_game\\strings\\maps_name',
    pauseGameStrings = '[shm]\\halo_4\\ui\\shell\\pause_game\\strings\\titles_and_headers'
}

-- UI widget definitions
constants.widgetDefinitions = {
    forgeMenu = '[shm]\\halo_4\\ui\\shell\\forge_menu\\forge_menu',
    forgeList = '[shm]\\halo_4\\ui\\shell\\forge_menu\\category_menu\\category_list',
    amountBar = '[shm]\\halo_4\\ui\\shell\\forge_menu\\budget_dialog\\budget_progress_bar',
    loadingMenu ='[shm]\\halo_4\\ui\\shell\\loading_menu\\loading_menu',
    loadingProgress ='[shm]\\halo_4\\ui\\shell\\loading_menu\\loading_progress_bar',
    loadoutMenu ='[shm]\\halo_4\\ui\\shell\\loadout_menu\\loadout_menu_no_background',
    mapsList = '[shm]\\halo_4\\ui\\shell\\pause_game\\forge_options_menu\\maps_list\\maps_list',
    sidebar = '[shm]\\halo_4\\ui\\shell\\pause_game\\forge_options_menu\\forge_map_list_sidebar_bar',
    errorNonmodalFullscreen = 'ui\\shell\\error\\error_nonmodal_fullscreen'
}

constants.spawnValues = {
    -- CTF, Blue Team
    ctfSpawnPointBlueTeam = {type = 1, team = 1},
    -- CTF, Red Team
    ctfSpawnPointReadTeam = {type = 1, team = 0},
    -- Generic, Both teams
    slayerSpawnPointBlueTeam = {type = 3, team = 0},
    -- Generic, Both teams
    allGamesGenericSpawnPoint = {type = 12, team = 0},
    bansheeSpawn = {type = 0},
    warthogSpawn = {type = 1},
    ghostSpawn = {type = 2},
    scorpionSpawn = {type = 3},
    cTurretSpawn = {type = 4},
    soccerBallSpawn = {type = 5}
}

return constants
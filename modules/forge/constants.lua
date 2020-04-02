------------------------------------------------------------------------------
-- Forge Constants
-- Author: Sledmine
-- Version: 1.0
-- Constants values
------------------------------------------------------------------------------

local constants = {}

constants.maximumProgressBarSize = 171
constants.minimumZSpawnPoint = -18.69
constants.maximumSidebarSize = 249
constants.minimumSidebarSize = 40

-- Request types definition
constants.requestTypes = {
    --['LOAD_MAP'] = '#l',
    ['SPAWN_OBJECT'] = '#s',
    ['UPDATE_OBJECT'] = '#u',
    ['DELETE_OBJECT'] = '#d',
    -- We have to provide reverse typing for fast coding
    ['#s'] = 'SPAWN_OBJECT',
    ['#u'] = 'UPDATE_OBJECT',
    ['#d'] = 'DELETE_OBJECT'
}

constants.requestFormats = {
    ['SPAWN_OBJECT'] = {'requestType', 'tagId', 'x', 'y', 'z', 'yaw', 'pitch', 'roll'},
    ['UPDATE_OBJECT'] = {'requestType','serverId', 'x', 'y', 'z', 'yaw', 'pitch', 'roll'},
    ['DELETE_OBJECT'] = {'requestType', 'serverId'}
}

constants.compressionFormats = {
    ['SPAWN_OBJECT'] = {tagId = 'I4', x = 'f', y = 'f', z = 'f'},
    ['UPDATE_OBJECT'] = {x = 'f', y = 'f', z = 'f'},
    ['DELETE_OBJECT'] = {} -- Delete does not require compression, by now... 
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
    amountBar = '[shm]\\halo_4\\ui\\shell\\forge_menu\\budget_dialog\\budget_progress_bar',
    forgeMenu = '[shm]\\halo_4\\ui\\shell\\forge_menu\\forge_menu',
    forgeList = '[shm]\\halo_4\\ui\\shell\\forge_menu\\category_menu\\category_list',
    mapsList = '[shm]\\halo_4\\ui\\shell\\pause_game\\forge_options_menu\\maps_list\\maps_list',
    errorNonmodalFullscreen = 'ui\\shell\\error\\error_nonmodal_fullscreen',
    sidebar = '[shm]\\halo_4\\ui\\shell\\pause_game\\forge_options_menu\\forge_map_list_sidebar_bar'
}

-- Spawn objects definitions
constants.spawnObjects = {
    allGamesGenericSpawnPoint = '[shm]\\halo_4\\scenery\\spawning\\players\\all games\\generic spawn point\\generic spawn point',
    ctfSpawnPointBlueTeam = '[shm]\\halo_4\\scenery\\spawning\\players\\ctf\\ctf spawn point blue team\\ctf spawn point blue team',
    ctfSpawnPointReadTeam = '[shm]\\halo_4\\scenery\\spawning\\players\\ctf\\ctf spawn point red team\\ctf spawn point red team',
    slayerSpawnPointBlueTeam = '[shm]\\halo_4\\scenery\\spawning\\players\\slayer\\slayer spawn point blue team\\slayer spawn point blue team',
    bansheeSpawn = '[shm]\\halo_4\\scenery\\spawning\\vehicles\\banshee spawn\\banshee spawn',
    warthogSpawn = '[shm]\\halo_4\\scenery\\spawning\\vehicles\\warthog spawn\\warthog spawn',
    ghostSpawn = '[shm]\\halo_4\\scenery\\spawning\\vehicles\\ghost spawn\\ghost spawn',
    scorpionSpawn = '[shm]\\halo_4\\scenery\\spawning\\vehicles\\scorpion spawn\\scorpion spawn',
    cTurretSpawn = '[shm]\\halo_4\\scenery\\spawning\\vehicles\\c turret spawn\\c turret spawn',
    soccerBallSpawn = '[shm]\\halo_4\\scenery\\spawning\\objects\\soccer ball spawn\\soccer ball spawn'
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
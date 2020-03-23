------------------------------------------------------------------------------
-- Forge Constants
-- Author: Sledmine
-- Version: 1.0
-- Constants values
------------------------------------------------------------------------------

local constants = {}

constants.maximumProgressBarSize = 171
constants.minimumZSpawnPoint = -18.69

-- Request types definition
constants.actionTypes = {
    'LOAD_MAP',
    'SPAWN_OBJECT',
    'UPDATE_OBJECT',
    'DELETE_OBJECT',
    'UPDATE_MAP_LIST'
}

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
    forgeMenu = 'ui\\shell\\error\\error_nonmodal_fullscreen',
    forgeList = '[shm]\\halo_4\\ui\\shell\\forge_menu\\category_menu\\category_list',
    mapsList = '[shm]\\halo_4\\ui\\shell\\pause_game\\forge_options_menu\\maps_list\\maps_list',
    errorNonmodalFullscreen = 'ui\\shell\\error\\error_nonmodal_fullscreen'
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
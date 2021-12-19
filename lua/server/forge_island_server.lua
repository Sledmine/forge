------------------------------------------------------------------------------
-- Forge Island Server Script
-- Sledmine
-- Script server side for Forge Island
------------------------------------------------------------------------------
-- Constants
-- Declare SAPP API Version before importing modules
-- This is used by lua-blam for SAPP detection
api_version = "1.12.0.0"
-- Replace Chimera server type variable for compatibility purposes
server_type = "sapp"
-- Script name must be the base script name, without variants or extensions
scriptName = "forge_island_server" -- script_name:gsub(".lua", ""):gsub("_dev", ""):gsub("_beta", "")
defaultConfigurationPath = "config"
defaultMapsPath = "fmaps\\forge_island"

-- Print server current Lua version
print("Server is running " .. _VERSION)
-- Bring compatibility with Lua 5.3
require "compat53"
print("Compatibility with Lua 5.3 has been loaded!")

-- Lua modules
local inspect = require "inspect"
local glue = require "glue"
local redux = require "lua-redux"
local json = require "json"

-- Specific Halo Custom Edition modules
blam = require "blam"
tagClasses = blam.tagClasses
local rcon = require "rcon"

-- Forge modules
local core = require "forge.core"
local features = require "forge.features"

-- Reducers importation
local eventsReducer = require "forge.reducers.eventsReducer"
local votingReducer = require "forge.reducers.votingReducer"
local forgeReducer = require "forge.reducers.forgeReducer"

-- Variable used to store the current Forge map in memory
-- FIXME This should take the first map available on the list
forgeMapName = "octagon"
forgeMapFinishedLoading = false
-- Controls if "Forging" is available or not in the current game
local forgingEnabled = false
local mapVotingEnabled = true

-- TODO This needs some refactoring, this configuration is kinda useless on server side
-- Forge default configuration
config = {
    forge = {
        debugMode = false,
        autoSave = false,
        autoSaveTime = 15000,
        snapMode = false,
        objectsCastShadow = false
    }
}
-- Default debug mode state, set to false at release time to improve performance
config.forge.debugMode = false
--- Function to send debug messages to console output
---@param message string
---@param color string
function dprint(message, color)
    if (config.forge.debugMode) then
        local message = message
        if (type(message) ~= "string") then
            message = inspect(message)
        end
        debugBuffer = (debugBuffer or "") .. message .. "\n"
        if (color == "category") then
            console_out(message, 0.31, 0.631, 0.976)
        elseif (color == "warning") then
            console_out(message, blam.consoleColors.warning)
        elseif (color == "error") then
            console_out(message, blam.consoleColors.error)
        elseif (color == "success") then
            console_out(message, 0.235, 0.82, 0)
        else
            console_out(message)
        end
    end
end

--- Print console text to every player in the server
---@param message string
function grprint(message)
    for playerIndex = 1, 16 do
        if (player_present(playerIndex)) then
            rprint(playerIndex, message)
        end
    end
end

PlayersBiped = {}
local monitorPlayers = {}
local tempPosition = {}
local playerSyncThread = {}
local ticksTimer = {}

-- TODO This function should be used as thread controller instead of a function executor
function OnTick()
    if (forgeMapFinishedLoading) then
        for playerIndex = 1, 16 do
            if (player_present(playerIndex)) then
                features.regenerateHealth(playerIndex)
                -- Run player object sync thread
                local syncThread = playerSyncThread[playerIndex]
                if (syncThread) then
                    if (coroutine.status(syncThread) == "suspended") then
                        local status, response = coroutine.resume(syncThread)
                        if (status and response) then
                            core.sendRequest(response, playerIndex)
                        end
                    else
                        console_out("Object sync finished for player " .. playerIndex)
                        playerSyncThread[playerIndex] = nil
                    end
                end
                local playerObjectId = blam.player(get_player(playerIndex)).objectId
                if (playerObjectId) then
                    local player = blam.biped(get_object(playerObjectId))
                    if (player) then
                        if (forgingEnabled) then
                            -- Save player position before swap
                            tempPosition[playerIndex] = {player.x, player.y, player.z}
                            if (const.bipeds.monitorTagId) then
                                if (player.crouchHold and player.tagId == const.bipeds.monitorTagId) then
                                    monitorPlayers[playerIndex] = false
                                    delete_object(playerObjectId)
                                elseif (player.flashlightKey and player.tagId ~=
                                    const.bipeds.monitorTagId) then
                                    monitorPlayers[playerIndex] = true
                                    delete_object(playerObjectId)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Add our commands logic to rcon
function rcon.commandInterceptor(playerIndex, message, environment, rconPassword)
    dprint("Incoming rcon command:", "warning")
    dprint(message)
    local request = string.gsub(message, "'", "")
    local data = glue.string.split(request, const.requestSeparator)
    local incomingRequest = data[1]
    local actionType
    local currentRequest
    for requestName, request in pairs(const.requests) do
        if (incomingRequest and incomingRequest == request.requestType) then
            currentRequest = request
            actionType = request.actionType
        end
    end
    -- Parsing rcon request
    if (actionType) then
        return core.processRequest(actionType, request, currentRequest, playerIndex)
    else
        -- Parsing rcon command
        data = glue.string.split(request, " ")
        for i, param in pairs(data) do
            data[i] = param:gsub("\"", "")
        end
        local forgeCommand = data[1]
        if (forgeCommand == "fload") then
            local mapName = data[2]
            local gameType = data[3]
            if (mapName and gameType) then
                if (read_file(defaultMapsPath .. "\\" .. mapName .. ".fmap")) then
                    cprint("Loading map " .. mapName .. " on " .. gameType .. "...")
                    forgeMapName = mapName
                    mapVotingEnabled = false
                    execute_script("sv_map " .. map .. " " .. gameType or "slayer")
                else
                    rprint(playerIndex, "Could not read Forge map " .. mapName .. " file!")
                end
            else
                cprint("You must specify a forge map name and a gametype.")
                rprint(playerIndex, "You must specify a forge map name and a gametype.")
            end
        elseif (forgeCommand == "fbiped") then
            local bipedName = data[2]
            if (bipedName) then
                for playerIndex = 1, 16 do
                    if (player_present(playerIndex)) then
                        -- FIXME Tag id string should be added here
                        PlayersBiped[playerIndex] = bipedName
                    end
                end
                execute_script("sv_map_reset")
            else
                rprint(playerIndex, "You must specify a biped name.")
            end
        elseif (forgeCommand == "fforge") then
            forgeMapFinishedLoading = true
            forgingEnabled = not forgingEnabled
            if (forgingEnabled) then
                grprint("Admin ENABLED :D Forge mode!")
            else
                grprint("Admin DISABLED Forge mode!")
            end
        elseif (forgeCommand == "fspawn") then
            -- Get scenario data
            local scenario = blam.scenario(0)

            -- Get scenario player spawn points
            local mapSpawnPoints = scenario.spawnLocationList

            mapSpawnPoints[1].type = 12

            scenario.spawnLocationList = mapSpawnPoints
        elseif (forgeCommand == "fcache") then
            local eventsState = eventsStore:getState()
            local cachedResponses = eventsState.cachedResponses
            console_out(#glue.keys(cachedResponses))
        end
    end
end

--[[function OnCommand(playerIndex, command, environment, rconPassword)
    return rcon.OnCommand(playerIndex, command, environment, rconPassword)
end]]

OnCommand = rcon.OnCommand

function OnScriptLoad()
    rcon.attach()
    register_callback(cb["EVENT_GAME_START"], "OnGameStart")
    register_callback(cb["EVENT_GAME_END"], "OnGameEnd")
    register_callback(cb["EVENT_COMMAND"], "OnCommand")
end

function OnGameStart()
    -- Provide compatibily with Chimera by setting "map" as a global variable with current map name
    map = get_var(0, "$map")
    const = require "forge.constants"

    -- Add forge rcon as not dangerous for command interception
    rcon.submitRcon("forge")

    -- Add forge public commands
    local publicCommands = {
        const.requests.spawnObject.requestType,
        const.requests.updateObject.requestType,
        const.requests.deleteObject.requestType,
        const.requests.sendMapVote.requestType,
        const.requests.selectBiped.requestType
    }
    for _, command in pairs(publicCommands) do
        rcon.submitCommand(command)
    end

    -- Add forge admin commands
    local adminCommands = {"fload", "fsave", "fforge", "fbiped"}
    for _, command in pairs(adminCommands) do
        rcon.submitAdmimCommand(command)
    end

    -- Stores for all the forge data
    forgeStore = forgeStore or redux.createStore(forgeReducer)
    eventsStore = eventsStore or redux.createStore(eventsReducer)
    votingStore = votingStore or redux.createStore(votingReducer)

    -- local restoredEventsState = read_file("eventsState.json")
    -- local restoredForgeState = read_file("forgeState.json")
    -- if (restoredEventsState and restoredForgeState) then
    --    local restorationEventsState = json.decode(restoredEventsState)
    --    local restorationForgeState = json.decode(restoredForgeState)
    --    ---@type forgeState
    --    local forgeState = forgeStore:getState()
    --    forgeState = restorationForgeState
    --    ---@type eventsState
    --    local eventsState = eventsStore:getState()
    --    eventsState = restorationEventsState
    --    forgeMapName = forgeState.currentMap.name:gsub(" ", "_"):lower()
    -- end

    -- TODO Check if this is better to do on script load
    core.loadForgeMaps()

    if (forgeMapName) then
        core.loadForgeMap(forgeMapName)
    end

    eventsStore:dispatch({type = const.requests.flushVotes.actionType})
    mapVotingEnabled = true
    register_callback(cb["EVENT_TICK"], "OnTick")
    register_callback(cb["EVENT_JOIN"], "OnPlayerJoin")
    register_callback(cb["EVENT_OBJECT_SPAWN"], "OnObjectSpawn")
    register_callback(cb["EVENT_PRESPAWN"], "OnPlayerSpawn")
end

-- Change biped tag id from players and store their object ids
function OnObjectSpawn(playerIndex, tagId, parentId, objectId)
    -- Intercept objects that are related to a player
    if (playerIndex) then
        for index, bipedTagId in pairs(const.bipeds) do
            if (tagId == bipedTagId) then
                if (monitorPlayers[playerIndex]) then
                    return true, const.bipeds.monitorTagId
                else
                    local customBipedTagId = PlayersBiped[playerIndex]
                    if (customBipedTagId) then
                        return true, customBipedTagId
                    else
                        return true
                    end
                end
            end
        end
    end
    return true
end

-- Update object data after spawning
function OnPlayerSpawn(playerIndex)
    local player = blam.biped(get_dynamic_player(playerIndex))
    if (player) then
        -- Provide better movement to monitors
        if (core.isPlayerMonitor(playerIndex)) then
            -- player.ignoreCollision = true
        end
        local playerPosition = tempPosition[playerIndex]
        if (playerPosition) then
            player.x = playerPosition[1]
            player.y = playerPosition[2]
            player.z = playerPosition[3]
            tempPosition[playerIndex] = nil
        end
    end
end

local function asyncObjectSync(playerIndex, cachedResponses)
    -- Yield the coroutine to skip the first coroutine creation
    coroutine.yield()
    -- Send to to player all the current forged objects
    for objectIndex, response in pairs(cachedResponses) do
        coroutine.yield(response)
    end
end

-- Sync data to incoming players
function OnPlayerJoin(playerIndex)
    local forgeState = forgeStore:getState()
    local eventsState = eventsStore:getState()
    local forgeObjects = eventsState.forgeObjects
    local countableForgeObjects = glue.keys(forgeObjects)
    local objectCount = #countableForgeObjects

    local cachedResponses = eventsState.cachedResponses

    -- There are Forge objects that need to be synced
    if (forgeMapName or objectCount > 0) then
        console_out("Sending map info for: " .. playerIndex)

        -- Create a temporal Forge map object like to force data sync
        local onMemoryForgeMap = {}
        onMemoryForgeMap.objects = countableForgeObjects
        onMemoryForgeMap.name = forgeState.currentMap.name
        onMemoryForgeMap.description = forgeState.currentMap.description
        onMemoryForgeMap.author = forgeState.currentMap.author
        core.sendMapData(onMemoryForgeMap, playerIndex)

        dprint("Creating sync thread for: " .. playerIndex)
        local co = coroutine.create(asyncObjectSync)
        -- Prepare function with desired parameters
        coroutine.resume(co, playerIndex, cachedResponses)
        playerSyncThread[playerIndex] = co
    end
end

function OnGameEnd()
    -- Events store are already loaded
    if (eventsStore) then
        -- Clean all forge stuff
        eventsStore:dispatch({type = const.requests.flushForge.actionType})
        -- Start vote map screen
        if (mapVotingEnabled) then
            eventsStore:dispatch({type = const.requests.loadVoteMapScreen.actionType})
        end
    end
    -- FIXME This needs a better implementation
    -- write_file("eventsState.json", json.encode(eventsStore:getState()))
    -----@type forgeState
    -- local dumpedState = forgeStore:getState()
    -- dumpedState.currentMap.name = forgeMapName
    -- write_file("forgeState.json", json.encode(dumpedState))
    collectgarbage("collect")
end

function OnError()
    cprint(debug.traceback())
end

function OnScriptUnload()
    rcon.detach()
end

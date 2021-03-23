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
defaultMapsPath = "fmaps"

-- Print server current Lua version
print("Server is running " .. _VERSION)
-- Bring compatibility with Lua 5.3
require "compat53"
print("Compatibility with Lua 5.3 has been loaded!")
-- Bring compatibility with Chimera Lua API
require "chimera-api"

-- Lua modules
local inspect = require "inspect"
local glue = require "glue"
local redux = require "lua-redux"

-- Specific Halo Custom Edition modules
blam = require "blam"
tagClasses = blam.tagClasses
local rcon = require "rcon"

-- Forge modules
local core = require "forge.core"

-- Reducers importation
local eventsReducer = require "forge.reducers.eventsReducer"
local votingReducer = require "forge.reducers.votingReducer"
local forgeReducer = require "forge.reducers.forgeReducer"

-- Variable used to store the current Forge map in memory
forgeMapName = "Lockout"
forgeMapFinishedLoading = false
-- Controls if "Forging" is available or not in the current game
local bipedSwapping = false
local mapVotingEnabled = true

-- TODO This needs some refactoring, this configuration is useless on server side
-- Forge default configuration
configuration = {
    forge = {
        debugMode = false,
        autoSave = false,
        autoSaveTime = 15000,
        snapMode = false,
        objectsCastShadow = false
    }
}
-- Default debug mode state, set to false at release time to improve performance
configuration.forge.debugMode = false
-- Buffer to store all the debug printing
debugBuffer = ""

--- Function to send debug messages to console output
---@param message string
---@param color string | category | warning | error | success
function dprint(message, color)
    if (type(message) ~= "string") then
        message = inspect(message)
    end
    debugBuffer = debugBuffer .. message .. "\n"
    if (configuration.forge.debugMode) then
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
    for i = 1, 16 do
        if (player_present(i)) then
            rprint(i, message)
        end
    end
end

function getPlayersCount()
    local count = 0
    for i = 1, 16 do
        if (player_present(i)) then
            count = count + 1
        end
    end
    return count
end

local playersObjectId = {}
local playersBiped = {}
local playersTempPosition = {}
local playerSyncThread = {}

-- TODO This function should be used as thread controller instead of a function executor
function OnTick()
    if (forgeMapFinishedLoading) then
        for playerIndex = 1, 16 do
            if (player_present(playerIndex)) then
                -- Run player object sync thread
                local syncThread = playerSyncThread[playerIndex]
                if (syncThread) then
                    if (coroutine.status(syncThread) == "suspended") then
                        local status, response = coroutine.resume(syncThread)
                        if (status and response) then
                            core.sendRequest(response, playerIndex)
                        end
                    else
                        print("Object sync finished for player " .. playerIndex)
                        playerSyncThread[playerIndex] = nil
                    end
                end
                local playerObjectId = playersObjectId[playerIndex]
                if (playerObjectId) then
                    local player = blam.biped(get_object(playerObjectId))
                    if (player) then
                        if (bipedSwapping) then
                            if (constants.bipeds.monitorTagId) then
                                if (player.crouchHold and player.tagId ==
                                    constants.bipeds.monitorTagId) then
                                    dprint("playerObjectId: " .. tostring(playerObjectId))
                                    dprint("Trying to process a biped swap request...")
                                    -- FIXME Biped name should be parsed to remove tagId pattern
                                    playersBiped[playerIndex] = "spartan" .. "TagId"
                                    playersTempPosition[playerIndex] =
                                        {player.x, player.y, player.z}
                                    delete_object(playerObjectId)
                                elseif (player.flashlightKey and player.tagId ~=
                                    constants.bipeds.monitorTagId) then
                                    dprint("playerObjectId: " .. tostring(playerObjectId))
                                    dprint("Trying to process a biped swap request...")
                                    -- FIXME Biped name should be parsed to remove tagId pattern
                                    playersBiped[playerIndex] = "monitor" .. "TagId"
                                    playersTempPosition[playerIndex] =
                                        {player.x, player.y, player.z}
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

rcon.commandInterceptor = function(playerIndex, message, environment, rconPassword)
    -- TODO Check rcon environment
    dprint("Triggering rcon...")
    -- TODO Check if we have to avoid returning true or false
    dprint("Incoming rcon message:", "warning")
    dprint(message)
    local request = string.gsub(message, "'", "")
    local splitData = glue.string.split(request, constants.requestSeparator)
    local incomingRequest = splitData[1]
    local actionType
    local currentRequest
    for requestName, request in pairs(constants.requests) do
        if (incomingRequest and incomingRequest == request.requestType) then
            currentRequest = request
            actionType = request.actionType
        end
    end
    if (actionType) then
        return core.processRequest(actionType, request, currentRequest, playerIndex)
        -- TODO Move this into a server request
    else
        splitData = glue.string.split(request, " ")
        for k, v in pairs(splitData) do
            splitData[k] = v:gsub("\"", "")
        end
        local forgeCommand = splitData[1]
        if (forgeCommand == "#b") then
            if (bipedSwapping) then
                dprint("Trying to process a biped swap request...")
                if (playersObjectId[playerIndex]) then
                    local playerObjectId = playersObjectId[playerIndex]
                    dprint("playerObjectId: " .. tostring(playerObjectId))
                    local player = blam.object(get_object(playerObjectId))
                    if (player) then
                        playersTempPosition[playerIndex] = {player.x, player.y, player.z}
                        if (player.tagId == constants.bipeds.monitorTagId) then
                            playersBiped[playerIndex] = "spartanTagId"
                        else
                            playersBiped[playerIndex] = "monitorTagId"
                        end
                        delete_object(playerObjectId)
                    end
                end
            end
            return false
        elseif (forgeCommand == "fload") then
            local mapName = splitData[2]
            local gameType = splitData[3]
            if (mapName) then
                if (read_file("fmaps\\" .. mapName .. ".fmap", "t")) then
                    forgeMapName = mapName
                    mapVotingEnabled = false
                    execute_script("sv_map " .. map .. " " .. gameType)
                else
                    grprint("Could not read Forge map " .. mapName .. " file!")
                end
            else
                rprint(playerIndex, "You must specify a forge map name.")
            end
            return false
        elseif (forgeCommand == "fbip") then
            local bipedName = splitData[2]
            if (bipedName) then
                for i = 1, 16 do
                    if (player_present(i)) then
                        playersBiped[i] = bipedName
                    end
                end
                execute_script("sv_map_reset")
            else
                rprint(playerIndex, "You must specify a biped name.")
            end
            return false
        elseif (forgeCommand == "fmon") then
            bipedSwapping = not bipedSwapping
            grprint(tostring(bipedSwapping))
            return false
        elseif (forgeCommand == "fspawn") then
            -- Get scenario data
            local scenario = blam.scenario(0)

            -- Get scenario player spawn points
            local mapSpawnPoints = scenario.spawnLocationList

            mapSpawnPoints[1].type = 12

            scenario.spawnLocationList = mapSpawnPoints
            return false
        elseif (forgeCommand == "fdata") then
            local eventsState = eventsStore:getState()
            local cachedResponses = eventsState.cachedResponses
            print(#glue.keys(cachedResponses))
            return false
        end
    end
end

function OnRcon(playerIndex, command, environment, interceptedRcon)
    return rcon.OnRcon(playerIndex, command, environment, interceptedRcon)
end

function OnScriptLoad()
    rcon.attach()

    register_callback(cb["EVENT_GAME_START"], "OnGameStart")
    register_callback(cb["EVENT_GAME_END"], "OnGameEnd")
    register_callback(cb["EVENT_COMMAND"], "OnRcon")
end

function OnGameStart()
    -- Provide compatibily with Chimera by setting this as a global variable
    map = get_var(0, "$map")
    constants = require "forge.constants"

    -- Add forge rcon as not dangerous for command interception
    rcon.submitRcon("forge")

    -- Add forge public commands
    local forgeCommands = {
        constants.requests.spawnObject.requestType,
        constants.requests.updateObject.requestType,
        constants.requests.deleteObject.requestType,
        constants.requests.sendMapVote.requestType
    }
    for _, command in pairs(forgeCommands) do
        rcon.submitCommand(command)
    end

    -- Add forge admin commands
    local adminForgeCommands = {"fload", "fsave", "fmon", "fbip"}
    for _, command in pairs(adminForgeCommands) do
        rcon.submitAdmimCommand(command)
    end

    -- Store for all the forge and events data
    forgeStore = forgeStore or redux.createStore(forgeReducer)
    eventsStore = eventsStore or redux.createStore(eventsReducer)
    votingStore = votingStore or redux.createStore(votingReducer)

    -- TODO Check if this is better to do on script load
    core.loadForgeMaps()

    if (forgeMapName) then
        forgeMapFinishedLoading = false
        core.loadForgeMap(forgeMapName)
    end

    eventsStore:dispatch({type = constants.requests.flushVotes.actionType})
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
        for index, bipedTagId in pairs(constants.bipeds) do
            if (tagId == bipedTagId) then
                -- Track objectId of every player
                playersObjectId[playerIndex] = objectId
                local requestedBiped = playersBiped[playerIndex]
                -- There is a requested biped by a player
                if (requestedBiped) then
                    local requestedBipedTagPath = constants.bipeds[requestedBiped]
                    local bipedTag = blam.getTag(requestedBipedTagPath, tagClasses.biped)
                    if (bipedTag and bipedTag.id) then
                        return true, bipedTag.id
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
            player.ignoreCollision = true
        end
        local playerPosition = playersTempPosition[playerIndex]
        if (playerPosition) then
            player.x = playerPosition[1]
            player.y = playerPosition[2]
            player.z = playerPosition[3]
            playersTempPosition[playerIndex] = nil
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
        print("Sending map info for: " .. playerIndex)

        -- Create a temporal Forge map object like to force data sync
        local onMemoryForgeMap = {}
        onMemoryForgeMap.objects = countableForgeObjects
        onMemoryForgeMap.name = forgeState.currentMap.name
        onMemoryForgeMap.description = forgeState.currentMap.description
        onMemoryForgeMap.author = forgeState.currentMap.author:gsub("Author: ", "")
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
        -- Clean all forge objects
        --eventsStore:dispatch({type = constants.requests.flushForge.actionType})
        -- Start vote map screen
        if (mapVotingEnabled) then
            eventsStore:dispatch({type = constants.requests.loadVoteMapScreen.actionType})
        end
    end
    playersObjectId = {}
    collectgarbage("collect")
end

function OnError()
    print(debug.traceback())
end

function OnScriptUnload()
    rcon.detach()
end

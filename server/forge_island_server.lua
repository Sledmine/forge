------------------------------------------------------------------------------
-- Forge Island Server Script
-- Sledmine
-- Version 1.0
-- Script server side for Forge Island
------------------------------------------------------------------------------
-- Constants
-- Declare SAPP API Version before importing libraries
-- This is usefull for SAPP detection
api_version = "1.12.0.0"
-- Replace Chimera server type variable for compatibility purposes
server_type = "sapp"
-- Script name must be the base script name, without variants or extensions
scriptName = "forge_island_server" -- script_name:gsub(".lua", ""):gsub("_dev", ""):gsub("_beta", "")
defaultConfigurationPath = "config"
defaultMapsPath = "fmaps"

print("Server is running " .. _VERSION)
-- Bring compatibility with Lua 5.3
require "compat53"
print("Compatibility with Lua 5.3 has been loaded!")
-- Bring compatibility with Chimera Lua API
require "cbindings"

-- Lua libraries
local inspect = require "inspect"
local glue = require "glue"
local redux = require "lua-redux"

-- Specific Halo Custom Edition libraries
blam = require "blam"
tagClasses = blam.tagClasses

-- Forge modules
local core = require "forge.core"

-- Reducers importation
local eventsReducer = require "forge.reducers.eventsReducer"
local votingReducer = require "forge.reducers.votingReducer"
local forgeReducer = require "forge.reducers.forgeReducer"

-- Variable used to store the current Forge map in memory
forgeMapName = "Octagon"
-- Controls if Forging is available or not for the current game
-- //FIXME For some reason Forge is not being blocked by this variable
local bipedSwapping = true
local mapVotingEnabled = true

-- // TODO This needs some refactoring, this configuration is useless on server side
-- Forge default configuration
configuration = {}

configuration.forge = {
    debugMode = false,
    autoSave = false,
    autoSaveTime = 15000,
    snapMode = false,
    objectsCastShadow = false
}

-- Default debug mode state
configuration.forge.debugMode = true

-- Internal functions and variables

-- Internal functions and variables
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

local playersObjIds = {}
local playersBiped = {}
local playersTemPos = {}
local playerQueuedObjects = {}

-- // TODO This function should be used as thread controller instead of a function executor
function OnTick()
    for playerIndex = 1, 16 do
        if (player_present(playerIndex)) then
            local playerObjectId = playersObjIds[playerIndex]
            if (playerObjectId) then
                local player = blam.biped(get_object(playerObjectId))
                if (player) then
                    local co = playerQueuedObjects[playerIndex]
                    if (co and coroutine.status(co) == "suspended") then
                        local status, response = coroutine.resume(co)
                        print("Thread status: " .. tostring(status))
                        if (status == false) then
                            print("Object sync finished for player " .. playerIndex)
                            playerQueuedObjects[playerIndex] = nil
                        elseif (status and response) then
                            core.sendRequest(response, playerIndex)
                        end
                    end
                    if (bipedSwapping) then
                        if (constants.monitorTagId) then
                            if (player.crouchHold and player.tagId == constants.monitorTagId) then
                                dprint("playerObjectId: " .. tostring(playerObjectId))
                                dprint("Trying to process a biped swap request...")
                                playersBiped[playerIndex] = "spartan"
                                playersTemPos[playerIndex] =
                                    {
                                        player.x,
                                        player.y,
                                        player.z
                                    }
                                delete_object(playerObjectId)
                            elseif (player.flashlightKey and player.tagId ~= constants.monitorTagId) then
                                dprint("playerObjectId: " .. tostring(playerObjectId))
                                dprint("Trying to process a biped swap request...")
                                playersBiped[playerIndex] = "monitor"
                                playersTemPos[playerIndex] =
                                    {
                                        player.x,
                                        player.y,
                                        player.z
                                    }
                                delete_object(playerObjectId)
                            end
                        end
                    end
                end
            end
        end
    end
end

function OnScriptLoad()
    register_callback(cb["EVENT_GAME_START"], "OnGameStart")
    register_callback(cb["EVENT_GAME_END"], "OnGameEnd")
    register_callback(cb["EVENT_COMMAND"], "OnRcon")
    register_callback(cb["EVENT_OBJECT_SPAWN"], "OnObjectSpawn")
    register_callback(cb["EVENT_JOIN"], "OnPlayerJoin")
    register_callback(cb["EVENT_PRESPAWN"], "OnPlayerSpawn")
end

function OnGameStart()
    -- Provide compatibily with Chimera by setting this as a global variable
    map = get_var(0, "$map")
    constants = require "forge.constants"

    -- Store for all the forge and events data
    forgeStore = forgeStore or redux.createStore(forgeReducer)
    eventsStore = eventsStore or redux.createStore(eventsReducer)
    votingStore = votingStore or redux.createStore(votingReducer)

    -- Add forge rcon as not dangerous for command interception
    execute_command("lua_call rcon_bypass submitRcon " .. "forge")

    -- Add forge commands for interception
    local forgeCommands = {
        "#s",
        "#d",
        "#u",
        "#l",
        "#b",
        "#v",
        "fload",
        "fsave",
        "fmon",
        "fbip"
    }
    for index, command in pairs(forgeCommands) do
        execute_command("lua_call rcon_bypass submitCommand " .. command)
    end

    -- // TODO Check if this is better to do on script load
    core.loadForgeMaps()

    if (forgeMapName) then
        core.loadForgeMap(forgeMapName)
    end

    eventsStore:dispatch({
        type = constants.requests.flushVotes.actionType
    })
    mapVotingEnabled = true
    register_callback(cb["EVENT_TICK"], "OnTick")
end

-- Change biped tag id from players and store their object ids
function OnObjectSpawn(playerIndex, tagId, parentId, objectId)
    if (not player_present(playerIndex)) then
        return true
    else
        for index, tagPath in pairs(constants.bipeds) do
            local bipedTag = blam.getTag(tagPath, tagClasses.biped)
            if (bipedTag and tagId == bipedTag.id) then
                -- Track objectId of every player
                playersObjIds[playerIndex] = objectId
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
            local tempObject = blam.biped(get_dynamic_player(playerIndex))
            tempObject.ignoreCollision = true
        end
        local playerPosition = playersTemPos[playerIndex]
        if (playerPosition) then
            local tempObject = blam.object(get_dynamic_player(playerIndex))
            tempObject.x = playerPosition[1]
            tempObject.y = playerPosition[2]
            tempObject.z = playerPosition[3]
            playersTemPos[playerIndex] = nil
        end
    end
end

local function asyncObjectSync(playerIndex, cachedResponses)
    -- Yield the coroutine to skip the first coroutine creation
    coroutine.yield()
    -- Send to to player all the current forged objects
    for objectIndex, response in pairs(cachedResponses) do
        print("From co:")
        print(playerIndex, response)
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

    -- There are objects to sync
    if (forgeMapName or objectCount > 0) then
        print("Sending map info")
        dprint("Sending sync responses for: " .. playerIndex)

        -- Create a temporal Forge map object like to force data sync
        local onMemoryForgeMap = {}
        onMemoryForgeMap.objects = countableForgeObjects
        onMemoryForgeMap.name = forgeState.currentMap.name
        onMemoryForgeMap.description = forgeState.currentMap.description
        onMemoryForgeMap.author = forgeState.currentMap.author:gsub("Author: ", "")
        core.sendMapData(onMemoryForgeMap, playerIndex)

        local co = coroutine.create(asyncObjectSync)
        -- Prepare function with desired parameters
        coroutine.resume(co, playerIndex, cachedResponses)
        playerQueuedObjects[playerIndex] = co
    end
end

function OnRcon(playerIndex, message, environment, rconPassword)
    -- // TODO Check rcon environment
    dprint("Triggering rcon...")
    -- // TODO Check if we have to avoid returning true or false
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
        -- // TODO Move this into a server request
    else
        splitData = glue.string.split(request, " ")
        for k, v in pairs(splitData) do
            splitData[k] = v:gsub("\"", "")
        end
        local forgeCommand = splitData[1]
        if (forgeCommand == "#b") then
            if (bipedSwapping) then
                dprint("Trying to process a biped swap request...")
                if (playersObjIds[playerIndex]) then
                    local playerObjectId = playersObjIds[playerIndex]
                    dprint("playerObjectId: " .. tostring(playerObjectId))
                    local player = blam.object(get_object(playerObjectId))
                    if (player) then
                        playersTemPos[playerIndex] =
                            {
                                player.x,
                                player.y,
                                player.z
                            }
                        local monitorTag = blam.getTag(constants.bipeds.monitor, tagClasses.biped)
                        if (monitorTag) then
                            if (player.tagId == monitorTag.id) then
                                playersBiped[playerIndex] = "spartan"
                            else
                                playersBiped[playerIndex] = "monitor"
                            end
                            delete_object(playerObjectId)
                        end
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

function OnGameEnd()
    -- Start vote map screen
    if (eventsStore) then
        -- Clean all forge objects
        eventsStore:dispatch({
            type = constants.requests.flushForge.actionType
        })
        if (mapVotingEnabled) then
            eventsStore:dispatch({
                type = constants.requests.loadVoteMapScreen.actionType
            })
        end
    end
    playersObjIds = {}
end

function OnError()
    print(debug.traceback())
end

function OnScriptUnload()
end

------------------------------------------------------------------------------
-- Forge Island Server Script
-- Authors: Sledmine
-- Version: 4.0
-- Script server side for Forge Island
------------------------------------------------------------------------------
-- Declare SAPP API Version before importing libraries
-- This is usefull for SAPP detection
api_version = "1.12.0.0"

print("Server is running " .. _VERSION)
-- Bring compatibility with Lua 5.3
require "compat53"
print("Compatibility with Lua 5.3 has been loaded!")

-- Set server type to sapp for triggering certain server actions
server_type = "sapp"

-- Lua libraries
local inspect = require "inspect"
local glue = require "glue"
local redux = require "lua-redux"

-- Specific Halo Custom Edition libraries
local maeth = require "maethrillian"
blam = require "nlua-blam"
tagClasses = blam35.tagClasses
blam = blam35.compat35()

-- Forge modules

local core = require "forge.core"

-- Reducers importation
local eventsReducer = require "forge.reducers.eventsReducer"
local forgeReducer = require "forge.reducers.forgeReducer"

-- Variable used to store the current forge map in memory
local forgeMapName
local forgeAllowed = true

-- Default debug mode state
debugMode = true

-- Forge server default configuration
-- DO NOT MODIFY ON SCRIPT!! use json config file instead
configuration = {}

-- Internal functions

--- Function to send debug messages to console output
---@param message string
---@param color string | "'category'" | "'warning'" | "'error'" | "'success'"
function dprint(message, color)
    if (debugMode) then
        if (color == "category") then
            console_out(message, 0.31, 0.631, 0.976)
        elseif (color == "warning") then
            console_out(message)
        elseif (color == "error") then
            console_out(message)
        elseif (color == "success") then
            console_out(message, 0.235, 0.82, 0)
        else
            console_out(message)
        end
    end
end

--- Print console text to every player in the server
---@param message string
function gprint(message)
    for i = 1, 16 do
        if (player_present(i)) then
            rprint(i, message)
        end
    end
end

function loadForgeMaps()
end

local playersObjectIds = {}
local bipedChangeRequest = {}
local playerObjectTempPos = {}

function OnScriptLoad()
    map = get_var(0, "$map")
    constants = require "forge.constants"

    forgeStore = redux.createStore(forgeReducer) -- Isolated store for all the Forge 'app' data
    eventsStore = redux.createStore(eventsReducer) -- Unique store for all the Forge Objects

    -- Forge folders creation
    forgeMapsFolder = "fmaps"

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
        "monitor"
    }
    for index, command in pairs(forgeCommands) do
        execute_command("lua_call rcon_bypass submitCommand " .. command)
    end
    register_callback(cb["EVENT_COMMAND"], "OnRcon")
    register_callback(cb["EVENT_OBJECT_SPAWN"], "OnObjectSpawn")
    register_callback(cb["EVENT_JOIN"], "OnPlayerJoin")
    register_callback(cb["EVENT_GAME_START"], "OnGameStart")
    register_callback(cb["EVENT_GAME_END"], "OnGameEnd")
    register_callback(cb["EVENT_PRESPAWN"], "OnPlayerSpawn")
end

-- Change biped tag id from players and store their object ids
function OnObjectSpawn(playerIndex, tagId, parentId, objectId)
    if (not player_present(playerIndex)) then
        return true
    else
        local isBiped = false
        for index, tagPath in pairs(constants.bipeds) do
            local bipedTagId = get_tag_id(tagClasses.biped, tagPath)
            if (tagId == bipedTagId) then
                isBiped = true
                break
            end
        end
        if (isBiped and forgeAllowed) then
            -- Track objectId of every player
            playersObjectIds[playerIndex] = objectId

            -- There is a requsted biped by a player
            if (bipedChangeRequest[playerIndex]) then
                local requestedBipedName = bipedChangeRequest[playerIndex]
                local requestedBipedTagPath = constants.bipeds[requestedBipedName]
                local requestedBipedTagId = get_tag_id(tagClasses.biped, requestedBipedTagPath)
                return true, requestedBipedTagId
            end
        end
    end
    return true
end

-- Update object data after spawning
function OnPlayerSpawn(playerIndex)
    local player = blam35.biped(get_dynamic_player(playerIndex))
    if (player) then
        -- Provide better movement to monitors
        if (core.isPlayerMonitor(playerIndex)) then
            blam35.biped(get_dynamic_player(playerIndex), {
                ignoreCollision = true
            })
        end
        local playerPosition = playerObjectTempPos[playerIndex]
        if (playerPosition) then
            blam35.object(get_dynamic_player(playerIndex), {
                x = playerPosition[1],
                y = playerPosition[2],
                z = playerPosition[3]
            })
            playerObjectTempPos[playerIndex] = nil
        end
    end
end

-- Sync all the required stuff to new players
function OnPlayerJoin(playerIndex)
    local forgeState = forgeStore:getState()
    local forgeObjects = eventsStore:getState().forgeObjects
    local countableForgeObjects = glue.keys(forgeObjects)
    -- local objectCount = #countableForgeObjects

    -- There are objects to sync
    if (forgeMapName) then -- and objectCount > 0) then
        print("Sending map info")
        dprint("Sending sync responses for: " .. playerIndex)

        -- Create a temporal forge map object like to force data sync
        local onMemoryForgeMap = {}
        onMemoryForgeMap.objects = countableForgeObjects
        onMemoryForgeMap.name = forgeState.currentMap.name
        onMemoryForgeMap.description = forgeState.currentMap.description
        core.sendMapData(onMemoryForgeMap, playerIndex)

        -- Send to new players all the current forged objects
        for objectId, forgeObject in pairs(forgeObjects) do
            local instanceObject = glue.update({}, forgeObject)
            instanceObject.requestType = constants.requests.spawnObject.requestType
            instanceObject.tagId = blam35.object(get_object(objectId)).tagId
            local response = core.createRequest(instanceObject)
            core.sendRequest(response, playerIndex)
        end
    end
end

function OnRcon(playerIndex, message, environment, rconPassword)
    -- // TODO: Check rcon environment
    dprint("Triggering rcon...")
    -- // TODO: Check if we have to avoid returning true or false
    dprint("Incoming rcon message:", "warning")
    dprint(message)
    local request = string.gsub(message, "'", "")
    local splitData = glue.string.split(request, "|")
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
        return core.processRequest(actionType, request, currentRequest)
    elseif (incomingRequest == "#b") then
        dprint("Trying to process a biped swap request...")
        -- // TODO: Split this into different functions!
        if (forgeAllowed) then
            if (playersObjectIds[playerIndex]) then
                local playerObjectId = playersObjectIds[playerIndex]
                dprint("playerObjectId: " .. tostring(playerObjectId))
                local player = blam35.object(get_object(playerObjectId))
                if (player) then
                    playerObjectTempPos[playerIndex] =
                        {
                            player.x,
                            player.y,
                            player.z
                        }
                    if (player.tagId == get_tag_id("bipd", constants.bipeds.monitor)) then
                        bipedChangeRequest[playerIndex] = "spartan"
                    else
                        bipedChangeRequest[playerIndex] = "monitor"
                    end
                    delete_object(playerObjectId)
                end
            end
        end
    elseif (incomingRequest == "#v") then
        gprint("A player has voted for map .. " .. splitData[2])
    elseif (incomingRequest == "monitor") then
        forgeAllowed = not forgeAllowed
    elseif (incomingRequest == "fload") then
        local mapName = splitData[2]
        local gameType = splitData[3]
        if (mapName) then
            local forgeObjects = eventsStore:getState().forgeObjects
            -- // FIXME: This control block is not ok, is just a patch!
            if (true) then
                forgeMapName = mapName
                execute_script("sv_map forge_island " .. gameType)
            end
        else
            rprint(playerIndex, "You must specify a forge map name.")
        end
    end
end

function OnGameStart()
    -- Load current forge map
    if (forgeMapName) then
        core.loadForgeMap(forgeMapName)
    end
end

function OnGameEnd()
    eventsStore:dispatch({
        type = constants.actionTypes.FLUSH_FORGE
    })
end

function OnError()
    print(debug.traceback())
end

function OnScriptUnload()
end

------------------------------------------------------------------------------
-- Forge Island Server Script
-- Authors: Sledmine
-- Version: 4.0
-- Script server side for Forge Island
------------------------------------------------------------------------------
-- Declare SAPP API Version before importing libraries
-- This is usefull for SAPP detection
api_version = '1.12.0.0'

print('Server is running ' .. _VERSION)
-- Bring compatibility with Lua 5.3
require('compat53')
print('Compatibility with Lua 5.3 has been loaded!')

-- Set server type to sapp for triggering certain server actions
server_type = 'sapp'

-- Lua libraries
inspect = require 'inspect'
glue = require 'glue'
redux = require 'lua-redux'

-- Specific Halo Custom Edition libraries
local blam = require 'lua-blam'
maethrillian = require 'maethrillian'

-- Forge modules
constants = require 'forge.constants'
features = require 'forge.features'
tests = require 'forge.tests'
core = require 'forge.core'

local forgeMap

-- Default debug mode state
debugMode = true

-- Internal functions

--- Function to send debug messages to console output
---@param message string
---@param color string | "'category'" | "'warning'" | "'error'" | "'success'"
function dprint(message, color)
    if (debugMode) then
        if (color == 'category') then
            console_out(message, 0.31, 0.631, 0.976)
        elseif (color == 'warning') then
            console_out(message)
        elseif (color == 'error') then
            console_out(message)
        elseif (color == 'success') then
            console_out(message, 0.235, 0.82, 0)
        else
            console_out(message)
        end
    end
end

-- Rotate object into desired degrees
function core.rotateObject(objectId, yaw, pitch, roll)
    local rotation = features.convertDegrees(yaw, pitch, roll)
    blam.object(get_object(objectId), {
        pitch = rotation[1],
        yaw = rotation[2],
        roll = rotation[3],
        xScale = rotation[4],
        yScale = rotation[5],
        zScale = rotation[6]
    })
end

local playersObjectIds = {}
local bipedChangeRequest = {}
local playerObjectTempPos = {}

-- Reducers importation
require 'forge.eventsReducer'
require 'forge.forgeReducer'

function OnScriptLoad()
    forgeStore = redux.createStore(forgeReducer) -- Isolated store for all the Forge 'app' data
    eventsStore = redux.createStore(eventsReducer) -- Unique store for all the Forge Objects

    -- Forge maps folder creation
    forgeMapsFolder = '.\\fmaps'
    loadForgeMapsList()

    -- Add forge rcon as not dangerous for command interception
    execute_command('lua_call rcon_bypass submitRcon ' .. 'forge')

    -- Add forge commands for interception
    local forgeCommands = {'#s', '#d', '#u', '#l', '#b', 'fload', 'fsave'}
    for k, v in pairs(forgeCommands) do
        execute_command('lua_call rcon_bypass submitCommand ' .. v)
    end
    register_callback(cb['EVENT_COMMAND'], 'onRcon')
    register_callback(cb['EVENT_OBJECT_SPAWN'], 'onObjectSpawn')
    register_callback(cb['EVENT_JOIN'], 'onPlayerJoin')
    register_callback(cb['EVENT_GAME_START'], 'onGameStart')
    register_callback(cb['EVENT_GAME_END'], 'onGameEnd')
    register_callback(cb['EVENT_PRESPAWN'], 'onPlayerSpawn')
end

function loadForgeMapsList() end

-- Change biped tag id from players and store their object ids
function onObjectSpawn(playerIndex, tagId, parentId, objectId)
    if (not player_present(playerIndex)) then
        return true
    elseif (tagId == get_tag_id('bipd', constants.bipeds.spartan) or tagId ==
        get_tag_id('bipd', constants.bipeds.monitor)) then
        playersObjectIds[playerIndex] = objectId
        if (bipedChangeRequest[playerIndex]) then
            local requestedBiped = bipedChangeRequest[playerIndex]
            return true, get_tag_id('bipd', constants.bipeds[requestedBiped])
        end
    end
    return true
end

-- Update object position after spawning as monitor
function onPlayerSpawn(playerIndex)
    local pos = playerObjectTempPos[playerIndex]
    if (pos) then
        blam.object(get_dynamic_player(playerIndex),
                    {x = pos[1], y = pos[2], z = pos[3]})
        playerObjectTempPos[playerIndex] = nil
    end
end

-- Sync preoviosly forged stuff for upcoming players
function onPlayerJoin(playerIndex)
    local forgeState = forgeStore:getState()
    local forgeObjects = eventsStore:getState().forgeObjects
    local objectCount = #glue.keys(forgeObjects)

    if (objectCount > 0) then
        dprint('Sending sync responses for: ' .. playerIndex)

        -- Create a temporal composed object like
        local tempObject = {}
        tempObject.objectCount = objectCount
        tempObject.mapName = forgeState.currentMap.name

        local response = core.createRequest(tempObject, constants.requestTypes
                                                .LOAD_MAP_SCREEN)
        core.sendRequest(response, playerIndex)

        for objectId, composedObject in pairs(forgeObjects) do
            local response = core.createRequest(composedObject,
                                                constants.requestTypes
                                                    .SPAWN_OBJECT)
            core.sendRequest(response, playerIndex)
        end
    end

end

function onRcon(playerIndex, message, environment, rconPassword)
    -- TO DO: Check rcon environment
    if (environment) then
        dprint('Triggering rcon...')
        -- TO DO: Check if we have to avoid returning true or false
        dprint('Incoming rcon message:', 'warning')
        dprint(message)
        local request = string.gsub(message, "'", '')
        local splitData = glue.string.split(',', request)
        local command = splitData[1]
        local requestType = constants.requestTypes[command]
        if (requestType) then
            dprint('Decoding incoming ' .. requestType .. ' ...', 'warning')

            local requestObject = maethrillian.convertRequestToObject(request,
                                                                      constants.requestFormats[requestType])

            if (requestObject) then
                dprint('Done.', 'success')
            else
                dprint('Error at converting request.', 'error')
                return false, nil
            end

            dprint('Decompressing ...', 'warning')
            local compressionFormat = constants.compressionFormats[requestType]
            requestObject = maethrillian.decompressObject(requestObject,
                                                          compressionFormat)

            if (requestObject) then
                dprint('Done.', 'success')
            else
                dprint('Error at decompressing request.', 'error')
                return false, nil
            end
            dprint('Error at decompressing request.', 'error')
            if (not ftestingMode) then
                eventsStore:dispatch({
                    type = requestType,
                    payload = {requestObject = requestObject}
                })
            end
            return false, requestObject
        elseif (command == '#b') then
            dprint('Trying to process a biped swap request...')
            if (playersObjectIds[playerIndex]) then
                local playerObjectId = playersObjectIds[playerIndex]
                dprint('playerObjectId: ' .. tostring(playerObjectId))
                local player = blam.object(get_object(playerObjectId))
                if (player) then
                    dprint('lua-blam rocks!!!')
                    playerObjectTempPos[playerIndex] =
                        {player.x, player.y, player.z}
                    if (player.tagId ==
                        get_tag_id('bipd', constants.bipeds.monitor)) then
                        bipedChangeRequest[playerIndex] = 'spartan'
                    else
                        bipedChangeRequest[playerIndex] = 'monitor'
                    end
                    delete_object(playerObjectId)
                end
            end
        elseif (command == 'fload') then
            local mapName = splitData[2]
            local gameType = splitData[3]
            if (mapName) then
                local forgeObjects = eventsStore:getState().forgeObjects
                if (#glue.keys(forgeObjects) > 0) then
                    forgeMap = mapName
                    execute_script('sv_map forge_island ' .. gameType)
                else
                    core.loadForgeMap(mapName)
                end
            else
                console_out('You must specify a forge map name.')
            end
        end
    end
end

function onGameStart() if (forgeMap) then core.loadForgeMap(forgeMap) end end

function onGameEnd()
    eventsStore:dispatch({type = constants.actionTypes.FLUSH_FORGE})
end

function OnScriptUnload() end

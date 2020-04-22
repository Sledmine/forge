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
json = require 'json'
glue = require 'glue'
redux = require 'lua-redux'

-- Specific Halo Custom Edition libraries
blam = require 'lua-blam'
maethrillian = require 'maethrillian'

-- Forge modules
constants = require 'forge.constants'
features = require 'forge.features'
tests = require 'forge.tests'

-- Default debug mode state
debugMode = true

-- Internal functions

-- Super function to keep compatibility with SAPP and printing debug messages if needed
---@param message string
---@param color string | "'category'" | "'warning'" | "'error'" | "'success'"
local oldCprint = cprint
function cprint(message, color)
    if (debugMode) then
        --console_out(message)
        if (color == 'category') then
            oldCprint(message)
        elseif (color == 'warning') then
            oldCprint(message)
        elseif (color == 'error') then
            oldCprint(message)
        elseif (color == 'success') then
            oldCprint(message)
        else
            oldCprint(message)
        end
    end
end

-- Super function for debug printing and accurate spawning
---@param type string | "'scen'" | '"bipd"'
---@param tagPath string
---@param x number @param y number @param Z number
---@return number | nil objectId
function cspawn_object(type, tagPath, x, y, z)
    cprint(' -> [ Object Spawning ]')
    cprint('Type:', 'category')
    cprint(type)
    cprint('Tag  Path:', 'category')
    cprint(tagPath)
    cprint('Trying to spawn object...', 'warning')
    -- Prevent objects from phantom spawning!
    -- local variables are accesed first than parameter variables
    local z = z
    if (z < constants.minimumZSpawnPoint) then
        z = constants.minimumZSpawnPoint
    end
    local objectId = spawn_object(type, tagPath, x, y, z)
    if (objectId) then
        cprint('-> Object: ' .. objectId .. ' succesfully spawned!!!', 'success')
        return objectId
    end
    cprint('Error at trying to spawn object!!!!', 'error')
    return nil
end

-- Rotate object into desired degrees
function rotateObject(objectId, yaw, pitch, roll)
    local rotation = features.convertDegrees(yaw, pitch, roll)
    blam.object(
        get_object(objectId),
        {
            pitch = rotation[1],
            yaw = rotation[2],
            roll = rotation[3],
            xScale = rotation[4],
            yScale = rotation[5],
            zScale = rotation[6]
        }
    )
end

-- Return object remote id from local id
function getObjectIdByRemoteId(state, remoteId)
    for k, v in pairs(state) do
        if (v.remoteId == remoteId) then
            return k
        end
    end
    return nil
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
    local forgeCommands = {
        '#s',
        '#d',
        '#u',
        '#l',
        '#b',
        'smap',
        'lmap'
    }
    for k, v in pairs(forgeCommands) do
        execute_command('lua_call rcon_bypass submitCommand ' .. v)
    end
    register_callback(cb['EVENT_COMMAND'], 'onRcon')
    register_callback(cb['EVENT_OBJECT_SPAWN'], 'onObjectSpawn')
    register_callback(cb['EVENT_JOIN'], 'onPlayerJoin')
    --register_callback(cb['EVENT_GAME_END'], 'flushScript')
    register_callback(cb['EVENT_PRESPAWN'], 'onPlayerSpawn')
end

function loadForgeMapsList()
end

-- Change biped tag id from players and store their object ids
function onObjectSpawn(playerIndex, tagId, parentId, objectId)
    if (not player_present(playerIndex)) then
        return true
    elseif
        (tagId == get_tag_id('bipd', constants.bipeds.spartan) or tagId == get_tag_id('bipd', constants.bipeds.monitor))
     then
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
        blam.object(get_dynamic_player(playerIndex), {x = pos[1], y = pos[2], z = pos[3]})
        playerObjectTempPos[playerIndex] = nil
    end
end

-- Sync preoviosly forged stuff for upcoming players
function onPlayerJoin(playerIndex)
    cprint('Sending sync responses for: ' .. playerIndex)
    local forgeObjects = eventsStore:getState().forgeObjects
    local objectCount = #glue.keys(forgeObjects)
    if (objectCount > 0) then
        local composedObject = {}
        composedObject.objectCount = objectCount
        local response = createRequest(composedObject, constants.requestTypes.LOAD_MAP_SCREEN)
        sendRequest(response, playerIndex)
        for objectId, composedObject in pairs(forgeObjects) do
            local response = createRequest(composedObject, constants.requestTypes.SPAWN_OBJECT)
            sendRequest(response, playerIndex)
        end
    end
end

-- Create a request for an object action
---@param composedObject number
---@param requestType string
function createRequest(composedObject, requestType)
    local objectData = {}
    if (composedObject) then
        objectData.requestType = requestType
        if (requestType == constants.requestTypes.SPAWN_OBJECT) then
            objectData.tagId = composedObject.object.tagId
            if (server_type == 'sapp') then
                objectData.remoteId = composedObject.remoteId
            end
        elseif (requestType == constants.requestTypes.UPDATE_OBJECT) then
            composedObject.object = blam.object(get_object(composedObject.objectId))
            if (server_type ~= 'sapp') then
                objectData.objectId = composedObject.remoteId
            else
                objectData.objectId = composedObject.objectId
            end
        elseif (requestType == constants.requestTypes.DELETE_OBJECT) then
            if (server_type ~= 'sapp') then
                objectData.objectId = composedObject.remoteId
            else
                objectData.objectId = composedObject.objectId
            end
            return objectData
        elseif (requestType == constants.requestTypes.LOAD_MAP_SCREEN) then
            objectData.objectCount = composedObject.objectCount
            return objectData
        end
        objectData.x = composedObject.object.x
        objectData.y = composedObject.object.y
        objectData.z = composedObject.object.z
        objectData.yaw = composedObject.yaw
        objectData.pitch = composedObject.pitch
        objectData.roll = composedObject.roll
        return objectData
    end
    return nil
end

-- Send a request to the server throug rcon
---@param data table
---@param playerIndex number
---@return boolean success
---@return string request
function sendRequest(data, playerIndex)
    cprint('Request data: ')
    cprint(inspect(data))
    cprint('-> [ Sending request ]')
    local requestType = constants.requestTypes[data.requestType]
    if (requestType) then
        cprint('Type: ' .. requestType, 'category')
        local compressionFormat = constants.compressionFormats[requestType]

        if (not compressionFormat) then
            cprint('There is no format compression for this request!!!!', 'error')
            return false
        end

        cprint('Compression: ' .. inspect(compressionFormat))

        local requestObject = maethrillian.compressObject(data, compressionFormat, true)

        local requestOrder = constants.requestFormats[requestType]
        local request = maethrillian.convertObjectToRequest(requestObject, requestOrder)

        request = "rcon forge '" .. request .. "'"

        cprint('Request: ' .. request)
        if (server_type == 'local') then
            -- We need to mockup the server response in local mode
            local mockedResponse = string.gsub(string.gsub(request, "rcon forge '", ''), "'", '')
            cprint('Local Request: ' .. mockedResponse)
            onRcon(mockedResponse)
            return true, mockedResponse
        elseif (server_type == 'dedicated') then
            -- Player is connected to a server
            cprint('Dedicated Request: ' .. request)
            execute_script(request)
            return true, request
        elseif (server_type == 'sapp') then
            local fixedResponse = string.gsub(request, "rcon forge '", '')
            cprint('Server Request: ' .. fixedResponse)

            -- We want to broadcast to every player in the server
            if (not playerIndex) then
                for i = 1, 16 do
                    if (player_present(i)) then
                        rprint(i, fixedResponse)
                    end
                end
            else
                -- We are looking to send data to a specific player
                rprint(playerIndex, fixedResponse)
            end
            return true, fixedResponse
        end
    end
    cprint('Error at trying to send request!!!!', 'error')
    return false
end

function onRcon(playerIndex, message, environment, rconPassword)
    -- TO DO: Check rcon environment
    if (true) then
        cprint('Triggering rcon...')
        -- TO DO: Check if we have to avoid returning true or false
        cprint('Incoming rcon message:', 'warning')
        cprint(message)
        local request = string.gsub(message, "'", '')
        local splitData = glue.string.split(',', request)
        local command = splitData[1]
        local requestType = constants.requestTypes[command]
        if (requestType) then
            cprint('Decoding incoming ' .. requestType .. ' ...', 'warning')

            local requestObject = maethrillian.convertRequestToObject(request, constants.requestFormats[requestType])

            if (requestObject) then
                cprint('Done.', 'success')
            else
                cprint('Error at converting request.', 'error')
                return false, nil
            end

            cprint('Decompressing ...', 'warning')
            local compressionFormat = constants.compressionFormats[requestType]
            requestObject = maethrillian.decompressObject(requestObject, compressionFormat)

            if (requestObject) then
                cprint('Done.', 'success')
            else
                cprint('Error at decompressing request.', 'error')
                return false, nil
            end
            cprint('Error at decompressing request.', 'error')
            if (not ftestingMode) then
                eventsStore:dispatch({type = requestType, payload = {requestObject = requestObject}})
            end
            return false, requestObject
        elseif (command == '#b') then
            cprint('Trying to process a biped swap request...')
            if (playersObjectIds[playerIndex]) then
                local playerObjectId = playersObjectIds[playerIndex]
                cprint('playerObjectId: ' .. tostring(playerObjectId))
                local player = blam.object(get_object(playerObjectId))
                if (player) then
                    cprint('lua-blam rocks!!!')
                    playerObjectTempPos[playerIndex] = {player.x, player.y, player.z}
                    if (player.tagId == get_tag_id('bipd', constants.bipeds.monitor)) then
                        bipedChangeRequest[playerIndex] = 'spartan'
                    else
                        bipedChangeRequest[playerIndex] = 'monitor'
                    end
                    delete_object(playerObjectId)
                end
            end
        end
    end
end

function OnScriptUnload()
end

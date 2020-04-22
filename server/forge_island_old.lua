------------------------------------------------------------------------------
-- Forge Island Server Script
-- Authors: Sledmine, Gelatinos0
-- Version: 3.0
-- Script server side for Forge Island
------------------------------------------------------------------------------

-- Declare SAPP API Version before importing libraries
-- This is usefull for SAPP detection
api_version = '1.12.0.0'
print('Server is running ' .. _VERSION)
-- Brings compatibility with Lua 5.3
require('compat53')
print('Compatibility with Lua 5.3 has been loaded!')

--[[
	We want to keep client script and server script
	similar as possible, to avoid differences between
	them we can bypass some of the stuff that is not
	supposed to happen in the client side but it must
	happen in the server side by setting this value
	to 'local'
]]
local server_type = 'local'

local scenarioPath = '[shm]\\halo_4\\maps\\forge_island\\forge_island'

local blam = require 'luablam'
local glue = require 'glue'
local json = require 'json'
local inspect = require 'inspect'

-- Internal mod functions
local function getExistentObjects()
    local objectsList = {}
    for i = 0, 1023 do
        if (get_object(i)) then
            objectsList[#objectsList + 1] = i
        end
    end
    return objectsList
end

local function rotate(X, Y, alpha)
    local c, s = math.cos(math.rad(alpha)), math.sin(math.rad(alpha))
    local t1, t2, t3 = X[1] * s, X[2] * s, X[3] * s
    X[1], X[2], X[3] = X[1] * c + Y[1] * s, X[2] * c + Y[2] * s, X[3] * c + Y[3] * s
    Y[1], Y[2], Y[3] = Y[1] * c - t1, Y[2] * c - t2, Y[3] * c - t3
end

local function convert(Yaw, Pitch, Roll)
    local F, L, T = {1, 0, 0}, {0, 1, 0}, {0, 0, 1}
    rotate(F, L, Yaw)
    rotate(F, T, Pitch)
    rotate(T, L, Roll)
    return {F[1], -L[1], -T[1], -F[3], L[3], T[3]}
end

-- Rotate object into desired degrees
local function rotateObject(objectId, yaw, pitch, roll)
    if (yaw > 360) then
        yaw = 0
    elseif (yaw < 0) then
        yaw = 360
    end
    if (pitch > 360) then
        pitch = 0
    elseif (pitch < 0) then
        pitch = 360
    end
    if (roll > 360) then
        roll = 0
    elseif (roll < 0) then
        roll = 360
    end
    local rotation = convert(yaw, pitch, roll)
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

local function inSceneryList(tagId, objectList)
    for k, v in pairs(objectList) do
        if (get_tag_id('scen', v) == tagId) then
            return k
        end
    end
    return nil
end

local eventsStore = {}
local bipedChangeRequest = {}
local playersObjectIds = {}
local playerObjectTempPos = {}

local minimumZSpawnPoint = -18.61

-- Biped tag definitions
local bipeds = {
    monitor = '[shm]\\halo_4\\characters\\monitor\\monitor_mp',
    spartan = 'characters\\cyborg_mp\\cyborg_mp'
}

-- Scenery definitions
local sceneries = {
    spawnPoint = '[shm]\\halo_4\\scenery\\spawning\\spawn point\\spawn point',
    spawnPointBlueTeam = '[shm]\\halo_4\\scenery\\spawning\\spawn point blue team\\spawn point blue team',
    spawnPointGray = '[shm]\\halo_4\\scenery\\spawning\\spawn point gray\\spawn point gray',
    spawnPointRedTeam = '[shm]\\halo_4\\scenery\\spawning\\spawn point red team\\spawn point red team',
    spawnPointVehicle = '[shm]\\halo_4\\scenery\\spawning\\spawn point vehicle\\spawn point vehicle'
}

local spawnValues = {
    -- CTF, Blue Team
    spawnPointBlueTeam = {type = 1, team = 1},
    -- CTF, Red Team
    spawnPointRedTeam = {type = 1, team = 0},
    -- Generic, Both teams
    spawnPoint = {type = 12, team = 0},
    -- Generic, Both teams
    spawnPointGray = {type = 12, team = 0},
    spawnPointVehicle = {type = 1}
}

function OnScriptLoad()
    forgeMapsFolder = '.\\fmaps'

    -- Add forge rcon as not dangerous for command interception
    execute_command('lua_call rcon_bypass submitRcon ' .. 'forge')

    -- Add forge commands for interception
    local forgeCommands = {
        '#s',
        '#d',
        '#u',
        '#b',
        'smap',
        'lmap'
    }
    for k, v in pairs(forgeCommands) do
        execute_command('lua_call rcon_bypass submitCommand ' .. v)
    end
    register_callback(cb['EVENT_COMMAND'], 'decodeIncomingData')
    register_callback(cb['EVENT_OBJECT_SPAWN'], 'onObjectSpawn')
    register_callback(cb['EVENT_JOIN'], 'onPlayerJoin')
    register_callback(cb['EVENT_GAME_END'], 'flushScript')
    register_callback(cb['EVENT_PRESPAWN'], 'onPlayerSpawn')
end

local function resetSpawnPoints()
    local scenario = blam.scenario(get_tag("scnr", scenarioPath))

    local mapSpawnCount = scenario.spawnLocationCount
    local vehicleLocationCount = scenario.vehicleLocationCount

    cprint('Found ' .. mapSpawnCount .. ' stock player starting points!')
    cprint('Found ' .. vehicleLocationCount .. ' stock vehicle location points!')
    local mapSpawnPoints = scenario.spawnLocationList
    -- Reset any spawn point, except the first one
    for i = 1, mapSpawnCount do
        -- Disable them by setting type to 0
        mapSpawnPoints[i].type = 0
    end
    local vehicleLocationList = scenario.vehicleLocationList
    for i = 2, vehicleLocationCount do
        vehicleLocationList[i].type = 65535
        execute_script('object_destroy v' .. vehicleLocationList[i].nameIndex)
    end
    blam.scenario(get_tag("scnr", scenarioPath), {spawnLocationList = mapSpawnPoints, vehicleLocationList = vehicleLocationList})
end

local function flushForge()
    resetSpawnPoints()
    cprint('FLUSHING ALL THE FORGE STUFFFFFFFFFF')
    for i = 1, 16 do
        if (player_present(i)) then
            rprint(i, '#fo')
        end
    end
    for k, v in pairs(eventsStore) do
        if (get_object(k)) then
            delete_object(k)
        end
    end
    eventsStore = {}
end

--[[
        0 = none
        1 = ctf
        2 = slayer
        3 = oddball
        4 = king of the hill
        5 = race
        6 = terminator
        12 = all games
        13 = all except ctf
        14 = all except race and ctf
    ]]
-- Must be called after adding scenery object to the store!!
-- @return true if found an available spawn
local function createSpawnPoint(objectLocalId, spawnType, teamIndex)
    local scenario = blam.scenario(get_tag("scnr", scenarioPath))
    local mapSpawnCount = scenario.spawnLocationCount
    local mapSpawnPoints = scenario.spawnLocationList

    local spawnObject = eventsStore[objectLocalId]
    -- Object exists, it's synced
    if (spawnObject) then
        if (not spawnObject.reflectedSpawn) then
            for i = 1, mapSpawnCount do
                if (mapSpawnPoints[i].type == 0) then
                    -- Replace spawn point values
                    mapSpawnPoints[i].x = spawnObject.x
                    mapSpawnPoints[i].y = spawnObject.y
                    mapSpawnPoints[i].z = spawnObject.z
                    mapSpawnPoints[i].rotation = math.rad(spawnObject.yaw)
                    mapSpawnPoints[i].teamIndex = teamIndex
                    mapSpawnPoints[i].type = spawnType

                    -- Debug spawn index
                    cprint('Creating spawn replacing index: ' .. i)
                    spawnObject.reflectedSpawn = i

                    -- Stop looking for "available" spawn slots
                    break
                end
            end
        else
            -- Replace spawn point values
            mapSpawnPoints[spawnObject.reflectedSpawn].x = spawnObject.x
            mapSpawnPoints[spawnObject.reflectedSpawn].y = spawnObject.y
            mapSpawnPoints[spawnObject.reflectedSpawn].z = spawnObject.z
            mapSpawnPoints[spawnObject.reflectedSpawn].rotation = math.rad(spawnObject.yaw)
            cprint(mapSpawnPoints[spawnObject.reflectedSpawn].type)
            -- Debug spawn index
            cprint('Updating spawn replacing index: ' .. spawnObject.reflectedSpawn)
        end
        -- Update spawn point list
        blam.scenario(get_tag("scnr", scenarioPath), {spawnLocationList = mapSpawnPoints})
        return true
    end
    return false
end

-- Must be called before deleting scenery object from the store!!
-- @return true if spawn has been deleted
local function deleteSpawnPoint(objectLocalId)
    local scenario = blam.scenario(get_tag("scnr", scenarioPath))
    local mapSpawnCount = scenario.spawnLocationCount
    cprint(mapSpawnCount)
    local mapSpawnPoints = scenario.spawnLocationList

    local spawnObject = eventsStore[objectLocalId]
    -- Object exists, it's synced
    if (spawnObject and spawnObject.reflectedSpawn) then
        if (mapSpawnPoints[spawnObject.reflectedSpawn]) then
            -- Disable or "delete" spawn point by setting type as 0
            mapSpawnPoints[spawnObject.reflectedSpawn].type = 0

            -- Update spawn point list
            blam.scenario(get_tag("scnr", scenarioPath), {spawnLocationList = mapSpawnPoints})

            -- Debug spawn index
            cprint('Deleting spawn replacing index: ' .. spawnObject.reflectedSpawn)
            return true
        end
    end
    return false
end

--[[
    0 = banshee
    1 = warthog
]]
-- Must be called after adding scenery object to the store!!
-- @return true if found an available spawn
local function createVehicleSpawnPoint(objectLocalId, vehicleType)
    -- Get all the scenario data
    local scenario = blam.scenario(get_tag("scnr", scenarioPath))
    local vehicleLocationCount = scenario.vehicleLocationCount
    cprint('Maximum count of vehicle spawn points: ' .. vehicleLocationCount)
    local vehicleLocationList = scenario.vehicleLocationList

    -- Get all the incoming object data
    local spawnObject = eventsStore[objectLocalId]
    -- Object exists, it's synced
    if (spawnObject) then
        if (not spawnObject.reflectedSpawn) then
            for i = 2, vehicleLocationCount do
                if (vehicleLocationList[i].type == 65535) then
                    -- Replace spawn point values
                    vehicleLocationList[i].x = spawnObject.x
                    vehicleLocationList[i].y = spawnObject.y
                    vehicleLocationList[i].z = spawnObject.z

                    -- REMINDER!!! Check vehicle rotation

                    vehicleLocationList[i].type = vehicleType

                    -- Debug spawn index
                    cprint('Creating spawn replacing index: ' .. i)
                    spawnObject.reflectedSpawn = i

                    -- Update spawn point list
                    blam.scenario(get_tag("scnr", scenarioPath), {vehicleLocationList = vehicleLocationList})

                    execute_script('object_create_anew v' .. vehicleLocationList[i].nameIndex)
                    -- Stop looking for "available" spawn slots
                    break
                end
            end
        else
            -- Replace spawn point values
            vehicleLocationList[spawnObject.reflectedSpawn].x = spawnObject.x
            vehicleLocationList[spawnObject.reflectedSpawn].y = spawnObject.y
            vehicleLocationList[spawnObject.reflectedSpawn].z = spawnObject.z

            -- REMINDER!!! Check vehicle rotation

            -- Debug spawn index
            cprint('Updating spawn replacing index: ' .. spawnObject.reflectedSpawn)

            -- Update spawn point list
            blam.scenario(get_tag("scnr", scenarioPath), {vehicleLocationList = vehicleLocationList})
        end
        return true
    end
    return false
end

-- Must be called before deleting scenery object from the store!!
-- @return true if spawn has been deleted
local function deleteVehicleSpawnPoint(objectLocalId)
    local scenario = blam.scenario(get_tag("scnr", scenarioPath))
    local vehicleLocationCount = scenario.vehicleLocationCount
    local vehicleLocationList = scenario.vehicleLocationList

    local spawnObject = eventsStore[objectLocalId]
    -- Object exists, it's synced
    if (spawnObject and spawnObject.reflectedSpawn) then
        if (vehicleLocationList[spawnObject.reflectedSpawn]) then
            -- Disable or "delete" spawn point by setting type as 0
            vehicleLocationList[spawnObject.reflectedSpawn].type = 65535

            -- Update spawn point list
            blam.scenario(get_tag("scnr", scenarioPath), {vehicleLocationList = vehicleLocationList})

            execute_script('object_destroy v' .. vehicleLocationList[spawnObject.reflectedSpawn].nameIndex)

            -- Debug spawn index
            cprint('Deleting spawn replacing index: ' .. spawnObject.reflectedSpawn)
            return true
        end
    end
    return false
end

local function updateBudgetCount()
    -- This function is called every time a new object is deleted/created
end

function decodeIncomingData(playerIndex, data)
    cprint('Incoming rcon message: ' .. data)
    data = string.gsub(data, "'", '')
    local splittedData = glue.string.split(',', data)
    local command = splittedData[1]
    if (command == '#s') then
        cprint('Decoding incoming object spawn...')
        cprint(inspect(splittedData))
        local objectProperties = {}
        cprint('Reaching data unpacking...')
        objectProperties.tagId = string.unpack('I4', glue.string.fromhex(splittedData[2]))
        objectProperties.x = string.unpack('f', glue.string.fromhex(splittedData[3]))
        objectProperties.y = string.unpack('f', glue.string.fromhex(splittedData[4]))
        objectProperties.z = string.unpack('f', glue.string.fromhex(splittedData[5]))
        objectProperties.yaw = tonumber(splittedData[6])
        objectProperties.pitch = tonumber(splittedData[7])
        objectProperties.roll = tonumber(splittedData[8])
        for property, value in pairs(objectProperties) do -- Evaluate all the data
            if (not value) then
                cprint('Incoming object data is in a WRONG format!!!')
            else
                cprint(property .. ' ' .. value)
            end
        end
        cprint('Object succesfully decoded!')
        spawnLocalObject(objectProperties)
    elseif (command == '#u') then
        cprint('Decoding incoming object update...')
        cprint(inspect(splittedData))
        local objectProperties = {}
        objectProperties.serverId = string.unpack('I4', glue.string.fromhex(splittedData[2]))
        objectProperties.x = string.unpack('f', glue.string.fromhex(splittedData[3]))
        objectProperties.y = string.unpack('f', glue.string.fromhex(splittedData[4]))
        objectProperties.z = string.unpack('f', glue.string.fromhex(splittedData[5]))
        objectProperties.yaw = tonumber(splittedData[6])
        objectProperties.pitch = tonumber(splittedData[7])
        objectProperties.roll = tonumber(splittedData[8])
        for property, value in pairs(objectProperties) do -- Evaluate all the data
            if (not value) then
                cprint('Incoming object data is in a WRONG format!!!')
            else
                cprint(property .. ' ' .. value)
            end
        end
        cprint('Object update succesfully decoded!')
        updateLocalObject(objectProperties)
    elseif (command == '#d') then
        cprint('Decoding incoming object deletion...')

        local objectServerId = tonumber(splittedData[2])

        -- There is an object with the required id
        if (objectServerId) then
            -- We are server, any id is local for us
            local objectLocalId = objectServerId

            if (objectLocalId and get_object(objectLocalId)) then
                cprint('Deleting object with serverId: ' .. objectServerId)

                -- Get object properties
                local tempObject = blam.object(get_object(objectLocalId))

                -- Reflect spawn points
                local tagName = inSceneryList(tempObject.tagId, sceneries)
                if (tagName) then
                    if (tagName:find('spawnPoint') and not tagName:find('spawnPointVehicle')) then
                        if (not deleteSpawnPoint(objectLocalId)) then
                            cprint('ERROR!: Spawn point with id:' .. objectLocalId .. ' can not be DELETED!!!')
                        end
                    else
                        if (server_type == 'local') then
                            deleteVehicleSpawnPoint(objectLocalId)
                        end
                    end
                end

                -- SERVER must send object deletion to every player
                broadcastObjectDelete(eventsStore[objectServerId])

                -- Erase the object from the game memory
                delete_object(objectLocalId)

                -- Erase the object from objects store
                eventsStore[objectLocalId] = nil

                -- Update global budget count
                updateBudgetCount()
            else
                print('Error at trying to erase object with serverId: ' .. objectServerId)
            end
        else
            cprint('Incoming object data is in a WRONG format!!!')
        end
    elseif (command == '#b') then
        cprint('TRYING TO CHANGE BIPED')
        if (playersObjectIds[playerIndex]) then
            local playerObjectId = playersObjectIds[playerIndex]
            cprint(tostring(playerObjectId))
            local playerObject = blam.object(get_object(playerObjectId))
            if (playerObject) then
                cprint('LUA BLAM ROCKS')
                playerObjectTempPos[playerIndex] = {playerObject.x, playerObject.y, playerObject.z}
                if (playerObject.tagId == get_tag_id('bipd', bipeds.monitor)) then
                    bipedChangeRequest[playerIndex] = 'spartan'
                else
                    bipedChangeRequest[playerIndex] = 'monitor'
                end
                delete_object(playerObjectId)
            end
        end
    elseif (command == 'smap' and splittedData[2]) then
        local mapName = splittedData[2]
        if (mapName) then
            saveForgeMap(mapName)
        else
            rprint(playerIndex, 'You must specify a name for your forge map.')
        end
    elseif (command == 'lmap' and splittedData[2]) then
        local mapName = splittedData[2]
        if (mapName) then
            loadForgeMap(mapName)
        else
            rprint(playerIndex, 'You must specify a forge map name.')
        end
    end
end

function onObjectSpawn(playerIndex, tagId, parentId, objectId)
    if (not player_present(playerIndex)) then
        return true
    elseif (tagId == get_tag_id('bipd', bipeds.spartan) or tagId == get_tag_id('bipd', bipeds.monitor)) then
        playersObjectIds[playerIndex] = objectId
        if (bipedChangeRequest[playerIndex]) then
            local requestedBiped = bipedChangeRequest[playerIndex]
            return true, get_tag_id('bipd', bipeds[requestedBiped])
        end
    end
    return true
end

function onPlayerJoin(playerIndex)
    if (player_present(playerIndex)) then
        for k, v in pairs(eventsStore) do
            sendObjectEntitySpawn(k, playerIndex)
        end
    end
end

-- Spawn object with specific properties and sync it
function spawnLocalObject(objectProperties)
    cprint('Trying to spawn object with tag id: ' .. objectProperties.tagId)
    local tagPath = get_tag_path(objectProperties.tagId)
    local fixedZ = objectProperties.z
    if (fixedZ < minimumZSpawnPoint) then
        fixedZ = minimumZSpawnPoint
    end
    -- We don't need to checkout for new spawned objects and retrieve the new one as i did on client script because we are server
    local objectLocalId = spawn_object('scen', tagPath, objectProperties.x, objectProperties.y, fixedZ)

    if (objectLocalId) then
        cprint('Object succesfully spawned with id: ' .. objectLocalId)
        objectProperties.id = objectLocalId

        -- Update object Z
        blam.object(get_object(objectLocalId), {z = objectProperties.z})

        -- Update object rotation
        rotateObject(objectLocalId, objectProperties.yaw, objectProperties.pitch, objectProperties.roll)

        -- Sync object with store
        eventsStore[objectLocalId] = objectProperties

        -- SERVER! must send the new object to every player
        broadcastObjectSpawn(eventsStore[objectLocalId])

        -- Update budget count
        updateBudgetCount()

        -- Reflect spawnpoints
        local tagName = inSceneryList(objectProperties.tagId, sceneries)
        if (tagName) then
            if (tagName:find('spawnPoint') and not tagName:find('spawnPointVehicle')) then
                local spawnData = spawnValues[tagName]
                -- We are trying to create a player spawn point
                if (not createSpawnPoint(objectLocalId, spawnData.type, spawnData.team)) then
                    cprint('ERROR!!: Spawn point with id: ' .. objectLocalId .. " can't be CREATED!!")
                end
            else
                -- We are trying to create vehicle spawn point
                if (server_type == 'local') then
                    createVehicleSpawnPoint(objectLocalId, spawnValues[tagName].type)
                end
            end
        end

        cprint('Object succesfully spawned with id: ' .. objectLocalId)
    else
        cprint('Error at trying to spawn object!!!')
    end
end

-- Spawn object with specific properties and sync it
function updateLocalObject(objectProperties)
    cprint('Trying to update object with server id: ' .. objectProperties.serverId)

    -- As SERVER! every object id is a local object id for us
    local objectLocalId = objectProperties.serverId
    if (objectLocalId) then
        -- Sync object with store
        eventsStore[objectLocalId].yaw = objectProperties.yaw
        eventsStore[objectLocalId].pitch = objectProperties.pitch
        eventsStore[objectLocalId].roll = objectProperties.roll
        eventsStore[objectLocalId].x = objectProperties.x
        eventsStore[objectLocalId].y = objectProperties.y
        eventsStore[objectLocalId].z = objectProperties.z

        -- Update object position
        blam.object(
            get_object(objectLocalId),
            {
                x = objectProperties.x,
                y = objectProperties.y,
                z = objectProperties.z
            }
        )

        -- Update object rotation
        rotateObject(objectLocalId, objectProperties.yaw, objectProperties.pitch, objectProperties.roll)

        -- SERVER! must send the updated data of the object
        broadcastObjectUpdate(eventsStore[objectLocalId])

        -- Update budget count
        updateBudgetCount()

        -- Get tag properties
        local tempObject = blam.object(get_object(objectLocalId))

        -- Reflect spawnpoints
        local tagName = inSceneryList(tempObject.tagId, sceneries)
        if (tagName) then
            if (tagName:find('spawnPoint') and not tagName:find('spawnPointVehicle')) then
                local spawnData = spawnValues[tagName]
                -- We are trying to UPDATE a player spawn point
                if (not createSpawnPoint(objectLocalId)) then
                    cprint('ERROR!!: Spawn point with id: ' .. objectLocalId .. " can't be UPDATED!!")
                end
            else
                -- We are trying to UPDATE vehicle spawn point
                if (server_type == 'local') then
                    createVehicleSpawnPoint(objectLocalId)
                end
            end
        end

        cprint('Object succesfully updated with local id: ' .. objectLocalId)
    else
        cprint('Error at trying to update object!!!')
    end
end

function sendObjectEntitySpawn(objectId, playerIndex)
    local object = blam.object(get_object(objectId))
    if (object) then
        cprint('Sending object spawn response... for tagId: ' .. object.tagId)
        local compressedData = {
            string.pack('I4', object.tagId),
            string.pack('f', object.x),
            string.pack('f', object.y),
            string.pack('f', object.z),
            eventsStore[objectId].yaw,
            eventsStore[objectId].pitch,
            eventsStore[objectId].roll,
            string.pack('I4', objectId)
        }
        local function convertDataToRequest(data)
            local response = {}
            for property, value in pairs(compressedData) do
                local encodedValue
                if (type(value) ~= 'number') then
                    encodedValue = glue.string.tohex(value)
                else
                    encodedValue = value
                end
                table.insert(response, encodedValue)
                cprint(property .. ' ' .. encodedValue)
            end
            local commandRequest = table.concat(response, ',')
            cprint('Request size is: ' .. #commandRequest + 5 .. ' characters')
            return "'#s," .. commandRequest .. "'" -- Spawn format
        end
        local response = convertDataToRequest(compressedData)
        rprint(playerIndex, response)
    end
end

-- Send an object spawn response to the client
function broadcastObjectSpawn(composedObject)
    for i = 1, 16 do
        if (player_present(i)) then
            local object = blam.object(get_object(composedObject.id))
            if (object) then
                cprint('Sending object spawn response... for tagId: ' .. object.tagId)
                local compressedData = {
                    string.pack('I4', object.tagId),
                    string.pack('f', object.x),
                    string.pack('f', object.y),
                    string.pack('f', object.z),
                    composedObject.yaw,
                    composedObject.pitch,
                    composedObject.roll,
                    string.pack('I4', composedObject.id)
                }
                local function convertDataToRequest(data)
                    local response = {}
                    for property, value in pairs(compressedData) do
                        local encodedValue
                        if (type(value) ~= 'number') then
                            encodedValue = glue.string.tohex(value)
                        else
                            encodedValue = value
                        end
                        table.insert(response, encodedValue)
                        cprint(property .. ' ' .. encodedValue)
                    end
                    local commandRequest = table.concat(response, ',')
                    cprint('Request size is: ' .. #commandRequest + 5 .. ' characters')
                    return "'#s," .. commandRequest .. "'" -- Spawn format
                end
                local response = convertDataToRequest(compressedData)
                rprint(i, response)
            end
        end
    end
end

-- Send an object spawn response to the client
function broadcastObjectUpdate(composedObject)
    for i = 1, 16 do
        if (player_present(i)) then
            local object = blam.object(get_object(composedObject.id))
            if (object) then
                cprint('Sending object update request... for objectId: ' .. composedObject.id)
                local compressedData = {
                    string.pack('I4', composedObject.id),
                    string.pack('f', object.x),
                    string.pack('f', object.y),
                    string.pack('f', object.z),
                    composedObject.yaw,
                    composedObject.pitch,
                    composedObject.roll
                }
                local function convertDataToRequest(data)
                    local request = {}
                    for property, value in pairs(compressedData) do
                        local encodedValue
                        if (type(value) ~= 'number') then
                            encodedValue = glue.string.tohex(value)
                        else
                            encodedValue = value
                        end
                        table.insert(request, encodedValue)
                        cprint(property .. ' ' .. encodedValue)
                    end
                    local commandRequest = table.concat(request, ',')
                    cprint('Request size is: ' .. #commandRequest + 5 .. ' characters')
                    return "'#u," .. commandRequest .. "'" -- Update format
                end
                local response = convertDataToRequest(compressedData)
                rprint(i, response)
            end
        end
    end
end

function saveForgeMap(mapName)
    cprint('Saving forge map...')
    local forgeObjects = {}
    for objectId, composedObject in pairs(eventsStore) do
        -- Get scenery tag path to keep compatibility between versions
        local sceneryPath = get_tag_path(composedObject.tagId)
        cprint(sceneryPath)
        -- Create a copy of the composed object in the store to avoid replacing useful values
        local fmapComposedObject = {}
        for k, v in pairs(composedObject) do
            fmapComposedObject[k] = v
        end

        -- Remove all the unimportant data
        fmapComposedObject.tagId = nil
        fmapComposedObject.serverId = nil

        -- Add tag path property
        fmapComposedObject.tagPath = sceneryPath

        -- Add forge object to list
        forgeObjects[#forgeObjects + 1] = fmapComposedObject
    end
    local fmapContent = json.encode(forgeObjects)

    local forgeMapFile = glue.writefile(forgeMapsFolder .. '\\' .. mapName .. '.fmap', fmapContent, 't')
    if (forgeMapFile) then
        cprint("Forge map '" .. mapName .. "' has been succesfully saved!")
    else
        cprint("ERROR!! At saving '" .. mapName .. "' as a forge map...")
    end
end

function loadForgeMap(mapName)
    local forgeObjects = {}
    local fmapContent = glue.readfile(forgeMapsFolder .. '\\' .. mapName .. '.fmap', 't')
    if (fmapContent) then
        cprint('Loading forge map...')
        forgeObjects = json.decode(fmapContent)
        if (forgeObjects and #forgeObjects > 0) then
            flushForge()
            for k, v in pairs(forgeObjects) do
                v.tagId = get_tag_id('scen', v.tagPath)
                v.tagPath = nil
                spawnLocalObject(v)
            end
            cprint("Succesfully loaded '" .. mapName .. "' fmap!")
        else
            cprint("ERROR!! At decoding data from '" .. mapName .. "' forge map...")
        end
    else
        cprint("ERROR!! At trying to load '" .. mapName .. "' as a forge map...")
    end
end

function broadcastObjectDelete(composedObject)
    for i = 1, 16 do
        if (player_present(i)) then
            local object = blam.object(get_object(composedObject.id))
            if (object) then
                local data = '#d,' .. composedObject.id
                rprint(i, data)
            end
        end
    end
end

function flushScript()
    eventsStore = {}
    bipedChangeRequest = {}
    playersObjectIds = {}
end

function onPlayerSpawn(playerIndex)
    local pos = playerObjectTempPos[playerIndex]
    if (pos) then
        blam.object(get_dynamic_player(playerIndex), {x = pos[1], y = pos[2], z = pos[3]})
        playerObjectTempPos[playerIndex] = nil
    end
end

function OnScriptUnload()
end

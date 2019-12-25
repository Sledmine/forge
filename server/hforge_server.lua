------------------------------------------------------------------------------
-- HForge Server - Forge Island Server Script
-- Authors: Sledmine, Gelatinos0
-- Version: 3.0
-- Script server side for Forge Island
------------------------------------------------------------------------------

-- Declare SAPP API Version before importing libraries, useful for SAPP detection
api_version = "1.12.0.0"
print("Server is running " .. _VERSION)
-- Brings compatibility with Lua 5.3
require("compat53")
print("Compatibility with Lua 5.3 has been loaded!")

local blam = require "luablam"
local glue = require "glue"
local json = require "json"
local inspect = require "inspect"

-- Internal functions
local function convertObjectKeysToString(object)
	local fixedObject = {}
	for k,v in pairs(object) do
		fixedObject[tostring(k)] = v
	end
	return fixedObject
end

local function convertObjectKeysToNumber(object)
	local fixedObject = {}
	for k,v in pairs(object) do
		fixedObject[tonumber(k)] = v
	end
	return fixedObject
end

-- Internal mod functions
local function getExistentObjects()
	local objectsList = {}
	for i=0,1023 do
		if (get_object(i)) then
			objectsList[#objectsList + 1] = i
		end
	end
	return objectsList
end

local function rotate(X, Y, alpha)
	local c, s = math.cos(math.rad(alpha)), math.sin(math.rad(alpha))
	local t1, t2, t3 = X[1]*s, X[2]*s, X[3]*s
	X[1], X[2], X[3] = X[1]*c+Y[1]*s, X[2]*c+Y[2]*s, X[3]*c+Y[3]*s
	Y[1], Y[2], Y[3] = Y[1]*c-t1, Y[2]*c-t2, Y[3]*c-t3
end

local function convert(Yaw, Pitch, Roll)
	local F, L, T = {1,0,0}, {0,1,0}, {0,0,1}
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
		get_object(objectId),{
			pitch = rotation[1],
			yaw = rotation[2],
			roll = rotation[3],
			xScale = rotation[4],
			yScale = rotation[5],
			zScale = rotation[6]
		}
	)
end

local objectsStore = {}
local bipedChangeRequest = {}
local playersObjectIds = {}
local playerObjectTempPos = {}

local minimumZSpawnPoint = -18.61

-- Biped tag definitions
local bipeds = {
	monitor = "[shm]\\halo_4\\characters\\monitor\\monitor_mp",
	spartan = "characters\\cyborg_mp\\cyborg_mp"
}

local scenerys = {
	spawnPoint = "[shm]\\halo_4\\scenery\\spawning\\spawn point\\spawn point",
}

function OnScriptLoad()
	-- Add forge rcon as not dangerous for command interception
	execute_command("lua_call rcon_bypass submitRcon " .. "forge")

	-- Add forge commands for interception
	local forgeCommands = {
		"#s",
		"#d",
		"#u",
		"#b",
		"smap",
		"lmap"
	}
	for k,v in pairs(forgeCommands) do
		execute_command("lua_call rcon_bypass submitCommand " .. v)
	end
	register_callback(cb['EVENT_COMMAND'], "decodeIncomingData")
	register_callback(cb['EVENT_OBJECT_SPAWN'],"onObjectSpawn")
	register_callback(cb['EVENT_JOIN'],"onPlayerJoin")
	register_callback(cb['EVENT_GAME_END'],"flushScript")
	register_callback(cb['EVENT_PRESPAWN'],"onPlayerSpawn")
end

local function reflectSpawnPoints()
	-- SAPP does not recognize tag id 0 as the default map .scenario so i hardcoded scenario path
	local scenario = blam.scenario(get_tag("scnr", "[shm]\\halo_4\\maps\\begotten\\forge_island_local"))
	local mapSpawnCount = scenario.spawnLocationCount
	cprint("Found " .. mapSpawnCount .. " stock spawn points!")
	local mapSpawnPoints = scenario.spawnLocationList
	for i = 2, mapSpawnCount do
		mapSpawnPoints[i].type = 0
	end
	local lastReflectedSpawn = 0
	for k,composedObject in pairs(objectsStore) do
		local tempObject = blam.object(get_object(k))
		-- Object exists, is a server synced object, is an scenery and it's a spawn point scenery
		if (tempObject and tempObject.type == 6 and tempObject.tagId == get_tag_id("scen", scenerys.spawnPoint)) then
			cprint("Reflecting spawn point at object index: " .. k)
			lastReflectedSpawn = lastReflectedSpawn + 1
			mapSpawnPoints[lastReflectedSpawn].x = composedObject.x
			mapSpawnPoints[lastReflectedSpawn].y = composedObject.y
			mapSpawnPoints[lastReflectedSpawn].z = composedObject.z
			mapSpawnPoints[lastReflectedSpawn].rotation = math.rad(composedObject.yaw)
			mapSpawnPoints[lastReflectedSpawn].type = 12
		end
	end
	blam.scenario(get_tag("scnr", "[shm]\\halo_4\\maps\\begotten\\forge_island_local"), {spawnLocationList = mapSpawnPoints})
end

local function updateBudgetCount()
	-- This function is called every time a new object is deleted/created so we can use it to reflect spawn points
	reflectSpawnPoints()
end

function decodeIncomingData(playerIndex, data)
	cprint("Incoming rcon message: " .. data)
	data = string.gsub(data, "'", "")
	local splittedData = glue.string.split(",", data)
	local command = splittedData[1]
	if (command== "#s") then
		cprint("Decoding incoming object spawn...")
		cprint(inspect(splittedData))
		local objectProperties = {}
		cprint("Reaching data unpacking...")
		objectProperties.tagId = string.unpack("I4", glue.string.fromhex(splittedData[2]))
		objectProperties.x = string.unpack("f", glue.string.fromhex(splittedData[3]))
		objectProperties.y = string.unpack("f", glue.string.fromhex(splittedData[4]))
		objectProperties.z = string.unpack("f", glue.string.fromhex(splittedData[5]))
		objectProperties.yaw = tonumber(splittedData[6])
		objectProperties.pitch = tonumber(splittedData[7])
		objectProperties.roll = tonumber(splittedData[8])
		for property,value in pairs(objectProperties) do -- Evaluate all the data
			if (not value) then
				cprint("Incoming object data is in a WRONG format!!!")
			else
				cprint(property .. " " .. value)
			end
		end
		cprint("Object succesfully decoded!")
		spawnLocalObject(objectProperties)
	elseif (command == "#u") then
		cprint("Decoding incoming object update...")
		cprint(inspect(splittedData))
		local objectProperties = {}
		objectProperties.serverId = string.unpack("I4", glue.string.fromhex(splittedData[2]))
		objectProperties.x = string.unpack("f", glue.string.fromhex(splittedData[3]))
		objectProperties.y = string.unpack("f", glue.string.fromhex(splittedData[4]))
		objectProperties.z = string.unpack("f", glue.string.fromhex(splittedData[5]))
		objectProperties.yaw = tonumber(splittedData[6])
		objectProperties.pitch = tonumber(splittedData[7])
		objectProperties.roll = tonumber(splittedData[8])
		for property,value in pairs(objectProperties) do -- Evaluate all the data
			if (not value) then
				cprint("Incoming object data is in a WRONG format!!!")
			else
				cprint(property .. " " .. value)
			end
		end
		cprint("Object update succesfully decoded!")
		updateLocalObject(objectProperties)
	elseif (command == "#d") then
		cprint("Decoding incoming object deletion...")
		local objectServerId = tonumber(splittedData[2])
		if (objectServerId) then
			if (get_object(objectServerId)) then
				cprint("Deleting object with serverId: " .. objectServerId)
				broadcastObjectDelete(objectsStore[objectServerId])
				delete_object(objectServerId)
				objectsStore[objectServerId] = nil
				updateBudgetCount()
			else
				print("Error at trying to erase object with serverId: " .. objectServerId)
			end
		else
			cprint("Incoming object data is in a WRONG format!!!")
		end
	elseif (command == "#b") then
		cprint("TRYING TO CHANGE BIPED")
		if (playersObjectIds[playerIndex]) then
			local playerObjectId = playersObjectIds[playerIndex]
			cprint(tostring(playerObjectId))
			local playerObject = blam.object(get_object(playerObjectId))
			if (playerObject) then
				cprint("LUA BLAM ROCKS")
				playerObjectTempPos[playerIndex] = {playerObject.x, playerObject.y, playerObject.z}
				if (playerObject.tagId == get_tag_id("bipd", bipeds.monitor)) then
					bipedChangeRequest[playerIndex] = "spartan"
				else
					bipedChangeRequest[playerIndex] = "monitor"
				end
				delete_object(playerObjectId)
			end
		end
	elseif (command == "smap" and splittedData[2]) then
		local mapName = splittedData[2]
		local fmap = io.open(mapName .. ".fmap", "w")
		if (fmap) then
			local fmapContent = json.encode(convertObjectKeysToString(objectsStore))
			fmap:write(fmapContent)
			fmap:close()
			rprint(playerIndex, "'" .. mapName .. "' has been succesfully saved.")
			cprint(inspect(fmapContent))
		else
			rprint(playerIndex, "Error at saving '" .. mapName .. "' fmap.")
		end
	elseif (command == "lmap" and splittedData[2]) then
		local mapName = splittedData[2]
		local fmap = io.open(mapName .. ".fmap", "r")
		if (fmap) then
			local fmapData = fmap:read("*a")
			local newObjectsStore = convertObjectKeysToNumber(json.decode(fmapData))
			if (newObjectsStore) then
				-- Erase all the objects on the server
				for k,v in pairs(objectsStore) do
					-- Erase all the objects on the client
					for i=1,16 do
						if (player_present(i)) then
							rprint(playerIndex, "#fo")
						end
					end
					--broadcastObjectDelete({id = k})
					if (get_object(k)) then
						delete_object(k)
					end
				end
				objectsStore = {}
				-- Create new objects on the server
				cprint("BEFORE loading fmap: " .. inspect(objectsStore))
				for k,v in pairs(newObjectsStore) do
					spawnLocalObject(v)
				end
				cprint("AFTER loading fmap: " .. inspect(objectsStore))
			else
				rprint(playerIndex, "Error at loading '" .. mapName .. "' fmap.")
			end
			fmap:close()
			rprint(playerIndex, "'" .. mapName .. "' has been succesfully loaded.")
		else
			rprint(playerIndex, "Error at loading '" .. mapName .. "' fmap.")
		end
	end
end

function onObjectSpawn(playerIndex, tagId, parentId, objectId)
	if (not player_present(playerIndex)) then
		return true
	elseif (tagId == get_tag_id("bipd", bipeds.spartan) or tagId == get_tag_id("bipd", bipeds.monitor)) then
		playersObjectIds[playerIndex] = objectId
		if (bipedChangeRequest[playerIndex]) then
			local requestedBiped = bipedChangeRequest[playerIndex]
			return true, get_tag_id("bipd", bipeds[requestedBiped])
		end
	end
    return true
end

function onPlayerJoin(playerIndex)
	if (player_present(playerIndex)) then
		for k,v in pairs(objectsStore) do
			sendObjectEntitySpawn(k, playerIndex)
		end
	end
end

-- Spawn object with specific properties and sync it
function spawnLocalObject(objectProperties)
	cprint("Trying to spawn object with tag id: " .. objectProperties.tagId)
	local tagPath = get_tag_path(objectProperties.tagId)
	local fixedZ = objectProperties.z
	if (fixedZ < minimumZSpawnPoint) then
		fixedZ = minimumZSpawnPoint
	end
	-- We don't need to checkout for new spawned objects and retrieve the new one as i did on client script because we are server
	local objectLocalId = spawn_object("scen", tagPath, objectProperties.x, objectProperties.y, fixedZ)

	cprint("New array value is: " .. tostring(objectLocalId))
	if (objectLocalId) then
		cprint("Object succesfully spawned with id: " .. objectLocalId)
		objectProperties.id = objectLocalId

		-- Update object Z
		blam.object(get_object(objectLocalId), {z = objectProperties.z})

		-- Sync scenery object
		objectsStore[objectLocalId] = objectProperties

		-- Update object rotation
		rotateObject(objectLocalId, objectProperties.yaw, objectProperties.pitch, objectProperties.roll)

		broadcastObjectSpawn(objectsStore[objectLocalId])
		-- Update budget count
		updateBudgetCount()
	else
		cprint("Error at trying to spawn object!!!")
	end
end

-- Spawn object with specific properties and sync it
function updateLocalObject(objectProperties)
	cprint("Trying to update object with server id: " .. objectProperties.serverId)

	-- This is needed because Chimera API returns a different id than the ones Halo is tracking 
	local objectLocalId = objectProperties.serverId
	if (objectLocalId) then
		cprint("Object succesfully updated with local id: " .. objectLocalId)

		-- Sync scenery object
		objectsStore[objectLocalId].yaw = objectProperties.yaw
		objectsStore[objectLocalId].pitch = objectProperties.pitch
		objectsStore[objectLocalId].roll = objectProperties.roll
		objectsStore[objectLocalId].x = objectProperties.x
		objectsStore[objectLocalId].y = objectProperties.y
		objectsStore[objectLocalId].z = objectProperties.z

		-- Update object Z
		blam.object(get_object(objectLocalId), {x = objectProperties.x, y = objectProperties.y, z = objectProperties.z})
		rotateObject(objectLocalId, objectProperties.yaw, objectProperties.pitch, objectProperties.roll)

		broadcastObjectUpdate(objectsStore[objectLocalId])
		-- Update budget count
		updateBudgetCount()
	else
		cprint("Error at trying to update object!!!")
	end
end

function sendObjectEntitySpawn(objectId, playerIndex)
	local object = blam.object(get_object(objectId))
	if (object) then
		cprint("Sending object spawn response... for tagId: " .. object.tagId)
		local compressedData = {
			string.pack("I4", object.tagId),
			string.pack("f", object.x),
			string.pack("f", object.y),
			string.pack("f", object.z),
			objectsStore[objectId].yaw,
			objectsStore[objectId].pitch,
			objectsStore[objectId].roll,
			string.pack("I4", objectId)
		}
		local function convertDataToRequest(data)
			local response = {}
			for property,value in pairs(compressedData) do
				local encodedValue
				if (type(value) ~= "number") then
					encodedValue = glue.string.tohex(value)
				else
					encodedValue = value
				end
				table.insert(response, encodedValue)
				cprint(property .. " " .. encodedValue)
			end
			local commandRequest = table.concat(response, ",")
			cprint("Request size is: " .. #commandRequest + 5 .. " characters")
			return "'#s," .. commandRequest .. "'" -- Spawn format
		end
		local response = convertDataToRequest(compressedData)
		rprint(playerIndex, response)
	end
end

-- Send an object spawn response to the client
function broadcastObjectSpawn(composedObject)
    for i = 1,16 do
        if (player_present(i)) then
			local object = blam.object(get_object(composedObject.id))
			if (object) then
				cprint("Sending object spawn response... for tagId: " .. object.tagId)
				local compressedData = {
					string.pack("I4", object.tagId),
					string.pack("f", object.x),
					string.pack("f", object.y),
					string.pack("f", object.z),
					composedObject.yaw,
					composedObject.pitch,
					composedObject.roll,
					string.pack("I4", composedObject.id)
				}
				local function convertDataToRequest(data)
					local response = {}
					for property,value in pairs(compressedData) do
						local encodedValue
						if (type(value) ~= "number") then
							encodedValue = glue.string.tohex(value)
						else
							encodedValue = value
						end
						table.insert(response, encodedValue)
						cprint(property .. " " .. encodedValue)
					end
					local commandRequest = table.concat(response, ",")
					cprint("Request size is: " .. #commandRequest + 5 .. " characters")
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
    for i = 1,16 do
        if (player_present(i)) then
			local object = blam.object(get_object(composedObject.id))
			if (object) then
				cprint("Sending object update request... for objectId: " .. composedObject.id)
				local compressedData = {
					string.pack("I4", composedObject.id),
					string.pack("f", object.x),
					string.pack("f", object.y),
					string.pack("f", object.z),
					composedObject.yaw,
					composedObject.pitch,
					composedObject.roll,
				}
				local function convertDataToRequest(data)
					local request = {}
					for property,value in pairs(compressedData) do
						local encodedValue
						if (type(value) ~= "number") then
							encodedValue = glue.string.tohex(value)
						else
							encodedValue = value
						end
						table.insert(request, encodedValue)
						cprint(property .. " " .. encodedValue)
					end
					local commandRequest = table.concat(request, ",")
					cprint("Request size is: " .. #commandRequest + 5 .. " characters")
					return "'#u," .. commandRequest .. "'" -- Update format
				end
				local response = convertDataToRequest(compressedData)
				rprint(i, response)
			end
        end
    end
end

function broadcastObjectDelete(composedObject)
    for i = 1,16 do
        if (player_present(i)) then
            local object = blam.object(get_object(composedObject.id))
            if (object) then
                local data = "#d," .. composedObject.id
                rprint(i, data)
            end
        end
    end
end

function flushScript()
	objectsStore = {}
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

function OnScriptUnload() end
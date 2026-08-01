---@meta _
---@diagnostic disable: duplicate-set-field

local luna = require "luna"

-- This module remains required by the project for SAPP compatibility.
-- For native Balltze v2 runtimes we intentionally do nothing.
if type(register_callback) ~= "function" then
    return
end

-- Load global variable for SAPP API
api_version = "1.12.0.0"

local isWine = os.getenv("WINEPREFIX") or os.getenv("WINELOADERNOEXEC") or os.getenv("WINESERVER")

require "compat53"
local blam2 = require "blam2"
local blam = require "blam"

Balltze = Balltze or {}
Balltze.filesystem = Balltze.filesystem or {}
Balltze.memory = Balltze.memory or {}
Balltze.logger = Balltze.logger or {}

Engine = Engine or {}
Engine.game = Engine.game or {}
Engine.script = Engine.script or {}
Engine.terminal = Engine.terminal or {}
Engine.object = Engine.object or {}
Engine.player = Engine.player or {}
Engine.tag = Engine.tag or {}
Engine.cacheFile = Engine.cacheFile or {}
Engine.uiWidget = Engine.uiWidget or {}

local ansiColorMap = {[2] = 32, [3] = 36, [4] = 31, [6] = 33}

-- Override cprint to make it faster! (original cprint is very slow)
function cprint(message, colorId)
    local ansiColor = ansiColorMap[colorId]
    if ansiColor then
        message = "\x1b[1;" .. ansiColor .. "m" .. message .. "\x1b[0m"
    end
    print(message)
end

local function formatMessage(format, ...)
    local args = {...}
    local index = 1
    local text = tostring(format or "")
    return text:gsub("{}", function()
        local arg = args[index]
        index = index + 1
        return tostring(arg)
    end)
end

local function toBlam2TagGroup(group)
    if type(group) ~= "string" then
        return group
    end
    if blam2.tag.groups[group] then
        return blam2.tag.groups[group]
    end

    local camel = group:gsub("_([a-z])", function(letter)
        return letter:upper()
    end)
    if blam2.tag.groups[camel] then
        return blam2.tag.groups[camel]
    end

    return group
end

local function toV2TagGroup(group)
    if type(group) ~= "string" then
        return "null"
    end
    return group:gsub("(%u)", function(letter)
        return "_" .. letter:lower()
    end)
end

local function makeHandle(handleValue)
    return {
        value = handleValue,
        index = blam2.getIndexFromHandle(handleValue),
        isNull = function()
            return blam2.isNull(handleValue)
        end
    }
end

-- ---------------------------------------------------------------------------
-- Balltze.logger (v2 surface)
-- ---------------------------------------------------------------------------
local loggerColor = {debug = 3, info = 2, warning = 6, error = 4, fatal = 4}
local muteDebugLogs = false

function Balltze.logger.debug(format, ...)
    if muteDebugLogs then
        return
    end
    cprint(os.date("%H:%M:%S") .. " DEBUG - " .. formatMessage(format, ...), loggerColor.debug)
end

function Balltze.logger.info(format, ...)
    cprint(os.date("%H:%M:%S") .. " INFO - " .. formatMessage(format, ...), loggerColor.info)
end

function Balltze.logger.warning(format, ...)
    cprint(os.date("%H:%M:%S") .. " WARN - " .. formatMessage(format, ...), loggerColor.warning)
end

function Balltze.logger.error(format, ...)
    cprint(os.date("%H:%M:%S") .. " ERROR - " .. formatMessage(format, ...), loggerColor.error)
end

function Balltze.logger.fatal(format, ...)
    cprint(os.date("%H:%M:%S") .. " FATAL - " .. formatMessage(format, ...), loggerColor.fatal)
end

function Balltze.logger.muteDebug(setting)
    if setting == nil then
        return muteDebugLogs
    end
    muteDebugLogs = setting == true
end

function Balltze.logger.muteConsole(_)
    return nil
end

-- ---------------------------------------------------------------------------
-- Balltze.filesystem
-- ---------------------------------------------------------------------------
local serverDataPathAddress = 0x005B9610

function Balltze.filesystem.getPluginPath()
    local serverDataPath = read_string(serverDataPathAddress)
    serverDataPath = serverDataPath .. "\\balltze\\plugins"
    if isWine then
        serverDataPath = serverDataPath:replace("\\", "/")
    end
    return serverDataPath
end

function Balltze.filesystem.readFile(path)
    return luna.file.read(path)
end

function Balltze.filesystem.writeFile(path, data)
    return luna.file.write(path, data)
end

-- ---------------------------------------------------------------------------
-- Balltze.memory
-- ---------------------------------------------------------------------------
Balltze.memory.writeBit = write_bit
Balltze.memory.writeInt8 = write_byte
Balltze.memory.writeInt16 = write_word
Balltze.memory.writeInt32 = write_dword
Balltze.memory.writeFloat = write_float

-- ---------------------------------------------------------------------------
-- Engine namespace (v2 surface)
-- ---------------------------------------------------------------------------
function Engine.terminal.print(colorOrFormat, formatOrArg, ...)
    local format
    local args
    if type(colorOrFormat) == "string" then
        format = colorOrFormat
        args = {formatOrArg, ...}
    else
        format = formatOrArg
        args = {...}
    end
    cprint(formatMessage(format, table.unpack(args)))
end

function Engine.script.execute(script)
    execute_script(script)
end

function Engine.game.getTickCount()
    return tonumber(get_var(0, "$ticks"))
end

function Engine.game.getGameConnectionType()
    return "networkServer"
end

function Engine.game.getGameEngineType()
    return nil
end

function Engine.object.getObject(handle, type)
    ---@diagnostic disable-next-line: param-type-mismatch
    return blam2.gameState.getObject(handle, type)
end

function Engine.object.createObject(tagHandle, parentObjectHandle, position)
    local _ = parentObjectHandle
    local handleValue
    if type(tagHandle) == "number" then
        handleValue = spawn_object(tagHandle, position.x, position.y, position.z)
    else
        handleValue = spawn_object(tagHandle.value, position.x, position.y, position.z)
    end
    return makeHandle(handleValue)
end

function Engine.object.deleteObject(objectHandle)
    if type(objectHandle) == "number" then
        return destroy_object(objectHandle)
    end
    return destroy_object(objectHandle.value)
end

function Engine.object.objectAttachToMarker(objectHandle, objectMarker, attachmentObjectHandle,
                                            attachmentMarker)
    local objectValue = type(objectHandle) == "number" and objectHandle or objectHandle.value
    local attachmentValue = type(attachmentObjectHandle) == "number" and attachmentObjectHandle or
                                attachmentObjectHandle.value
    return attach_object(attachmentValue, objectValue, objectMarker, attachmentMarker)
end

function Engine.player.getPlayer(playerIndexOrHandle)
    local player = blam.player(get_player(playerIndexOrHandle))
    if not player then
        return nil
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    local object = blam.object(get_object(player.objectId))
    local position = {x = 0, y = 0, z = 0}
    if object then
        position = {x = object.x, y = object.y, z = object.z}
    end

    return {
        playerId = player.id,
        teamIndex = player.team,
        position = position,
        unitHandle = makeHandle(player.objectId)
    }
end

function Engine.tag.lookupTag(path, group)
    local tagGroup = toBlam2TagGroup(group)
    ---@diagnostic disable-next-line: param-type-mismatch
    local tag = blam2.getTagEntry(path, tagGroup)
    if not tag then
        return nil
    end
    return tag.handle
end

function Engine.tag.getTagData(handle, group)
    local tagGroup = toBlam2TagGroup(group)
    local tagHandle = type(handle) == "number" and handle or handle.value
    ---@diagnostic disable-next-line: param-type-mismatch
    local tag = blam2.getTagEntry(tagHandle, tagGroup)
    if not tag then
        return nil
    end
    return tag.data
end

function Engine.tag.getTagEntry(handle)
    local tagHandle = type(handle) == "number" and handle or handle.value
    ---@diagnostic disable-next-line: param-type-mismatch
    local tag = blam2.getTagEntry(tagHandle)
    if not tag then
        return nil
    end

    local entry = {
        group = toV2TagGroup(tag.class or "null"),
        parentGroups = {"null", "null"},
        handle = tag.handle,
        path = tag.path,
        indexed = tag.indexed and 1 or 0
    }

    function entry:getData()
        return Engine.tag.getTagData(self.handle, self.group)
    end

    return entry
end

function Engine.tag.filterTags(group, pathFilter)
    local tagGroup = toBlam2TagGroup(group)
    ---@diagnostic disable-next-line: param-type-mismatch
    local tags = blam2.tag.findTags(pathFilter or "", tagGroup) or {}
    local result = {}

    for _, tag in ipairs(tags) do
        local entry = {
            group = group,
            parentGroups = {"null", "null"},
            handle = tag.handle,
            path = tag.path,
            indexed = tag.indexed and 1 or 0
        }
        function entry:getData()
            return Engine.tag.getTagData(self.handle, self.group)
        end
        table.insert(result, entry)
    end

    return result
end

function Engine.uiWidget.getActiveWidget()
    return nil
end

function Engine.cacheFile.getLoadedCacheFileHeader()
    return {
        engineType = "custom",
        fileSize = 0,
        tagDataOffset = 0x40440000,
        tagDataSize = 0,
        name = get_var(0, "$map"),
        build = "unknown",
        gameType = "multiplayer",
        crc32 = 0
    }
end

function Engine.cacheFile.getList()
    return {}
end

-- ---------------------------------------------------------------------------
-- SAPP -> Balltze v2 event bridge
-- ---------------------------------------------------------------------------
local listenersByEvent = {}

local function getListeners(eventName)
    local listeners = listenersByEvent[eventName]
    if not listeners then
        listeners = {}
        listenersByEvent[eventName] = listeners
    end
    return listeners
end

function Balltze.addEventListener(eventName, callbackFunction, priority)
    local listener = {
        handle = tostring(os.clock()) .. "_" .. tostring(math.random(1, 1000000)),
        priority = priority or "default",
        event = eventName
    }

    function listener:remove()
        local listeners = listenersByEvent[self.event]
        if not listeners then
            return
        end
        for index, subscribed in ipairs(listeners) do
            if subscribed == self then
                table.remove(listeners, index)
                return
            end
        end
    end

    listener.callback = callbackFunction
    table.insert(getListeners(eventName), listener)
    return listener
end

function Balltze.removeEventListeners(eventName)
    listenersByEvent[eventName] = {}
end

local function dispatchEvent(eventName, context)
    local listeners = listenersByEvent[eventName]
    if not listeners then
        return
    end

    for _, listener in ipairs(listeners) do
        local results = {listener.callback(context)}
        if results[1] ~= nil then
            return table.unpack(results)
        end
    end
end

local function mapEventContext(mapName)
    return {
        getMapName = function()
            return mapName
        end
    }
end

function _BalltzeOnTick()
    dispatchEvent("tick", nil)
    dispatchEvent("frame_begin", nil)
    dispatchEvent("frame", nil)
    dispatchEvent("frame_end", nil)
end

function _BalltzeOnMapLoad()
    local mapName = get_var(0, "$map") or ""
    dispatchEvent("map_load", mapEventContext(mapName))
    dispatchEvent("map_loaded", mapEventContext(mapName))
    if type(PluginOnGameStart) == "function" then
        PluginOnGameStart()
    end
end

function Balltze.registerSappCallbacks()
    register_callback(cb["EVENT_TICK"], "_BalltzeOnTick")
    register_callback(cb["EVENT_GAME_START"], "_BalltzeOnMapLoad")
end

function OnScriptLoad()
    if type(PluginOnSappLoad) == "function" then
        PluginOnSappLoad()
    end
end

function OnScriptUnload()
    if type(PluginUnload) == "function" then
        PluginUnload()
    end
end

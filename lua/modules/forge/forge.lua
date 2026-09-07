local engine = Engine
local core = require "forge.core"
local json = require "json"
local script = require "script"
local sleep = script.sleep
local getPlayer = engine.player.getPlayer
local getObject = engine.object.getObject
local getTagData = engine.tag.getTagData
local getTagEntry = engine.tag.getTagEntry
local logger = Balltze.logger
local castRay = engine.physics.castRay
local component = require "ui.component"
local hudText = require "forge.hud.text"
local hudCrosshair = require "forge.hud.crosshair"
local rotation = require "forge.math.rotation"
local vectorsToEulerAngles = rotation.vectorsToEulerAngles
local eulerToRotationVectors = rotation.eulerToRotationVectors
local point = require "forge.math.point"
local pointDistance = point.distance
local abs = math.abs

component.callbacks()

local defaultMapsPath = "fmaps"

---Update hud data to reflect state
---@param attachedObjectHandle? integer | ObjectHandle
---@param aimedObjectHandle? integer | ObjectHandle
local function updateMonitorHud(attachedObjectHandle, aimedObjectHandle)
    -- Compute attached object rotation display here (presentation logic belongs in forge)
    local centerSecondary = nil
    if attachedObjectHandle then
        local object = getObject(attachedObjectHandle)
        if object then
            local yaw, pitch, roll = vectorsToEulerAngles(object.rotation[1], object.rotation[2])
            centerSecondary = string.format("Y: %d  P: %d  R: %d", math.floor(yaw + 0.5),
                                            math.floor(pitch + 0.5), math.floor(roll + 0.5))
        end
    end

    return hudText.updateMonitorHud(attachedObjectHandle, aimedObjectHandle, centerSecondary)
end

---@class forgePlayerState
---@field attachedObject integer?
---@field distance number
---@field lockDistance boolean
---@field highlightedObject integer?
---@field currentAngle "yaw" | "pitch" | "roll"
---@field rotationStep number
---@field yaw number
---@field pitch number
---@field roll number

local forge = {
    ---@type "edit" | "normal"
    mode = "edit",
    constants = {
        bipeds = {
            ---@type TagEntry?
            monitor = nil,
            ---@type TagEntry?
            player = nil
        },
        tagCollections = {
            ---@type TagEntry?
            forgeObjects = nil
        },
        weaponHudInterfaces = {
            ---@type TagEntry?
            monitorCrosshair = nil
        },
        fonts = {
            ---@type TagEntry?
            hud = nil
        }
    },
    callbacks = {
        ---@param mode "tools" | "place"
        launchMonitorMenu = function(mode)
            logger.debug("Forge: launchMonitorMenu callback not set, mode={}", mode)
        end
    },
    state = {
        ---@type table<integer, forgePlayerState>
        players = {},
        player = {
            ---@type integer?
            attachedObject = nil
        }
    }
}

---Get player's state given a player index
---@param playerIndex integer
---@return forgePlayerState
local function getPlayerState(playerIndex)
    if type(playerIndex) ~= "number" then
        playerIndex = 0
    end
    forge.state.players[playerIndex] = forge.state.players[playerIndex] or {
        attachedObject = nil,
        distance = 5,
        lockDistance = true,
        highlightedObject = nil,
        currentAngle = "yaw",
        rotationStep = 5,
        yaw = 0,
        pitch = 0,
        roll = 0
    }
    return forge.state.players[playerIndex]
end

---Normalize rotation angle
---@param value number
---@return number
local function normalizeRotation(value)
    local normalized = value % 360
    if normalized < 0 then
        normalized = normalized + 360
    end
    return normalized
end

---Apply object rotation from state given player index
---@param playerIndex integer
local function applyAttachedObjectRotation(playerIndex)
    local playerState = getPlayerState(playerIndex)
    if not playerState.attachedObject then
        return
    end

    local object = getObject(playerState.attachedObject)
    if not object then
        return
    end

    local yaw = tonumber(playerState.yaw) or 0
    local pitch = tonumber(playerState.pitch) or 0
    local roll = tonumber(playerState.roll) or 0
    local forwardVector, upVector = eulerToRotationVectors(yaw, pitch, roll)
    engine.object.setObjectPosition(playerState.attachedObject, object.position, {
        i = forwardVector.i,
        j = forwardVector.j,
        k = forwardVector.k
    }, {i = upVector.i, j = upVector.j, k = upVector.k})
end

local function getScenarioShortName()
    local cacheHeader = engine.cacheFile.getLoadedCacheFileHeader()
    local scenarioName = "forge_island_dev"
    if cacheHeader and cacheHeader.scenarioName and cacheHeader.scenarioName ~= "" then
        scenarioName = cacheHeader.scenarioName or scenarioName
    end
    logger.debug("Current scenario name: {}", scenarioName)
    local shortName = scenarioName:match("([^\\/]+)$") or scenarioName
    return shortName
end

local function normalizeMapName(name)
    if type(name) ~= "string" then
        return ""
    end
    return name:gsub(" ", "_"):lower()
end

local function stripMapVariant(name)
    if type(name) ~= "string" then
        return ""
    end

    local strippedName = name:lower():gsub("\\", "/")
    strippedName = strippedName:match("([^/]+)$") or strippedName
    strippedName = strippedName:gsub("%.fmap$", "")
    strippedName = strippedName:gsub("_dev$", "")
    strippedName = strippedName:gsub("_beta$", "")
    return strippedName
end

local function isMapCompatible(savedMapName)
    if type(savedMapName) ~= "string" or savedMapName == "" then
        return true
    end
    local currentMap = normalizeMapName(getScenarioShortName())
    local savedMap = normalizeMapName(savedMapName)

    local currentBase = stripMapVariant(currentMap)
    local savedBase = stripMapVariant(savedMap)
    return currentMap == savedMap or currentBase == savedMap or currentMap == savedBase or
               currentBase == savedBase
end

local function resolveSceneryTagHandle(tagPath)
    if type(tagPath) ~= "string" or tagPath == "" then
        return nil
    end
    local tags = engine.tag.filterTags("scenery", tagPath)
    if not tags or #tags == 0 then
        return nil
    end

    for _, tag in ipairs(tags) do
        if tag.path == tagPath and tag.handle then
            return tag.handle
        end
    end

    local firstTag = tags[1]
    return firstTag and firstTag.handle or nil
end

local function restoreObjectRotation(objectHandle, yaw, pitch, roll)
    if type(yaw) ~= "number" or type(pitch) ~= "number" or type(roll) ~= "number" then
        return
    end

    local forwardVector, upVector = eulerToRotationVectors(yaw, pitch, roll)
    if engine.object.setObjectPosition then
        local objectPosition = engine.object.getObjectPosition(objectHandle)
        if not objectPosition then
            return
        end
        engine.object.setObjectPosition(objectHandle, objectPosition, {
            i = forwardVector.i,
            j = forwardVector.j,
            k = forwardVector.k
        }, {i = upVector.i, j = upVector.j, k = upVector.k})
    end
end

--- Spawn a forge scenery object from a tag handle with shared logic
---@param tagHandle TagHandle | integer
---@param position? Point3d
---@param opts? {euler?: EulerAngles, forward?: Vector3d, up?: Vector3d}
---@return ObjectHandle? handle
function forge.spawnForgeObject(tagHandle, position, opts)
    if not tagHandle then
        return nil
    end
    position = position or {x = 0, y = 0, z = 0}
    -- Ensure tag data flags (shadow) are set when available
    local ok, tagData = pcall(function()
        return getTagData(tagHandle, "scenery")
    end)
    if ok and tagData and tagData.flags then
        tagData.flags.castShadowByDefault = true
    end

    local objectHandle = engine.object.createObject(tagHandle, nil, position)
    if not objectHandle then
        return nil
    end

    local handleValue = objectHandle.value or objectHandle

    -- Apply rotation/orientation if provided
    if opts then
        if opts.euler and type(opts.euler) == "table" then
            local yaw = tonumber(opts.euler.yaw) or 0
            local pitch = tonumber(opts.euler.pitch) or 0
            local roll = tonumber(opts.euler.roll) or 0
            restoreObjectRotation(handleValue, yaw, pitch, roll)
        else
            logger.debug("Spawning object with forward/up vectors")
            local forward = opts.forward
            local up = opts.up
            logger.debug("Forward vector: {}",
                         forward and
                             string.format("{i=%.2f,j=%.2f,k=%.2f}", forward.i or 0, forward.j or 0,
                                           forward.k or 0) or "nil")
            logger.debug("Up vector: {}", up and
                             string.format("{i=%.2f,j=%.2f,k=%.2f}", up.i or 0, up.j or 0, up.k or 0) or
                             "nil")
            if forward or up then
                engine.object.setObjectPosition(handleValue, position,
                                                forward or {i = 0, j = 0, k = 1},
                                                up or {i = 0, j = 1, k = 0})
            end
        end
    end

    return objectHandle
end

---Get the absolute position of a given biped
---@param playerBiped BipedObject
---@return Point3d
local function getBipedWorldPosition(playerBiped)
    if playerBiped and playerBiped.bipedPosition then
        return playerBiped.bipedPosition
    end
    if playerBiped and playerBiped.position then
        return playerBiped.position
    end
    return {x = 0, y = 0, z = 0}
end

---Return looking component vectors from a given biped
---@param playerBiped BipedObject
---@return integer i, integer j, integer k
local function getBipedViewDirection(playerBiped)
    if playerBiped and playerBiped.lookingVector then
        local lv = playerBiped.lookingVector
        if lv.i or lv.j or lv.k then
            return lv.i or 0, lv.j or 0, lv.k or 0
        end
    end
    return 0, 0, 1
end

---Get the object handle that a given biped is currently aiming at (if any)
---@param playerBiped BipedObject
---@return integer? aimedObjectHandle
local function getAimedObjectHandle(playerBiped)
    if not playerBiped then
        return nil
    end

    local origin = getBipedWorldPosition(playerBiped)
    local viewI, viewJ, viewK = getBipedViewDirection(playerBiped)
    local rayLength = 25
    local hit = castRay(origin,
                        {i = viewI * rayLength, j = viewJ * rayLength, k = viewK * rayLength},
                        "objects")

    if not hit or hit.type ~= "object" or not hit.objectHandle then
        return nil
    end

    local aimedHandle = hit.objectHandle.value
    if not aimedHandle then
        return nil
    end

    local aimedObject = getObject(aimedHandle)
    if not aimedObject then
        return nil
    end

    return aimedHandle
end

---Set higlight effect to a given object
---@param objectHandle ObjectHandle | integer
---@param enabled boolean
local function setObjectHighlight(objectHandle, enabled)
    if not objectHandle then
        return
    end
    local object = getObject(objectHandle)
    if not object then
        return
    end

    if enabled then
        object.vitals.health = 1
        object.vitals.shield = 1
    else
        object.vitals.health = 0
        object.vitals.shield = 0
    end
end

local function updateAimedObjectHighlight(playerIndex, aimedObjectHandle)
    local state = getPlayerState(playerIndex)
    local previousHandle = state.highlightedObject
    local attachedHandle = state.attachedObject

    if previousHandle and previousHandle ~= aimedObjectHandle and previousHandle ~= attachedHandle then
        setObjectHighlight(previousHandle, false)
    end

    state.highlightedObject = aimedObjectHandle
    forge.state.player.highlightedObject = aimedObjectHandle
    if aimedObjectHandle and aimedObjectHandle ~= attachedHandle then
        setObjectHighlight(aimedObjectHandle, true)
    end
end

--- Changes Forge crosshair state
---@param mode "hidden" | "idle" | "selected" | "holding" | "bounds"
local function setMonitorMode(mode)
    return hudCrosshair.setMode(mode, forge.state)
end

---Make a given player by index to select an object being aimed at
---@param playerIndex integer
---@param playerBiped BipedObject
---@return boolean
local function pickupAimedObject(playerIndex, playerBiped)
    local aimedObjectHandle = getAimedObjectHandle(playerBiped)
    if not aimedObjectHandle then
        return false
    end

    forge.setAttachedObject(playerIndex, aimedObjectHandle)
    return true
end

function forge.getAttachedObject(playerIndex)
    local state = getPlayerState(playerIndex)
    return state.attachedObject
end

function forge.setAttachedObject(playerIndex, objectHandle)
    local state = getPlayerState(playerIndex)
    state.attachedObject = objectHandle
    state.highlightedObject = objectHandle
    state.currentAngle = state.currentAngle or "yaw"
    state.rotationStep = state.rotationStep or 5

    local object = getObject(objectHandle)
    assert(object, "Object not found for handle: " .. tostring(objectHandle))
    local yaw, pitch, roll = vectorsToEulerAngles(object.rotation[1], object.rotation[2])

    state.yaw = tonumber(yaw) or 0
    state.pitch = tonumber(pitch) or 0
    state.roll = tonumber(roll) or 0

    local player = getPlayer(playerIndex)
    if player then
        local playerBiped = getObject(player.unitHandle.value, "biped")
        local object = getObject(objectHandle)
        if playerBiped and object and object.position then
            local bipedPosition = getBipedWorldPosition(playerBiped)
            state.distance = pointDistance(bipedPosition, object.position)
        end
    end
    applyAttachedObjectRotation(playerIndex)

    forge.state.player.attachedObject = objectHandle

    updateAimedObjectHighlight(playerIndex, objectHandle)
    forge.state.player.highlightedObject = objectHandle

    setMonitorMode("holding")
end

---Detach current attached object from a player given player index
---@param playerIndex integer
---@param deleteObject? boolean
local function detachAttachedObject(playerIndex, deleteObject)
    local state = getPlayerState(playerIndex)
    if state.highlightedObject then
        setObjectHighlight(state.highlightedObject, false)
        state.highlightedObject = nil
        forge.state.player.highlightedObject = nil
    end
    if deleteObject and state.attachedObject then
        local object = engine.object.getObject(state.attachedObject)
        if object then
            engine.object.deleteObject(state.attachedObject)
        end
    elseif state.attachedObject then
        setObjectHighlight(state.attachedObject, false)
    end
    state.attachedObject = nil
    forge.state.player.attachedObject = nil
end

---Remove (dettach and removed) attached object from a player given player index
---@param playerIndex integer
function forge.clearAttachedObject(playerIndex)
    detachAttachedObject(playerIndex, true)
end

---Update attached player object relative to camera
---@param playerIndex integer
---@param playerBiped BipedObject
---@return boolean
local function updateAttachedObjectFromCamera(playerIndex, playerBiped)
    local state = getPlayerState(playerIndex)
    if not state.attachedObject then
        return false
    end

    local attachedObject = getObject(state.attachedObject)
    if not attachedObject then
        detachAttachedObject(playerIndex)
        return false
    end

    if not playerBiped then
        return false
    end

    local bipedPosition = getBipedWorldPosition(playerBiped)
    local viewI, viewJ, viewK = getBipedViewDirection(playerBiped)

    local distance = state.distance or 5
    if distance < 0.5 then
        distance = 0.5
    end

    engine.object.setObjectPosition(state.attachedObject, {
        x = bipedPosition.x + viewI * distance,
        y = bipedPosition.y + viewJ * distance,
        z = bipedPosition.z + viewK * distance
    })

    return true
end

---Update object distance if allowd
---@param playerIndex integer
---@param playerBiped BipedObject
local function updateAttachedObjectDistance(playerIndex, playerBiped)
    local state = getPlayerState(playerIndex)
    if state.lockDistance or not state.attachedObject then
        return
    end

    local attachedObject = getObject(state.attachedObject)
    if not attachedObject then
        return
    end

    local bipedPosition = getBipedWorldPosition(playerBiped)
    state.distance = pointDistance(bipedPosition, attachedObject.position)
end

---@param tagHandle TagHandle
---@param playerIndex integer?
---@return boolean
function forge.placeObject(tagHandle, playerIndex)
    if not tagHandle then
        logger.debug("Place object: missing tag handle for object")
        return false
    end
    local tagEntry = getTagEntry(tagHandle)
    assert(tagEntry, "Place object: tag entry not found for handle")
    local tagPath = tagEntry.path

    local targetPlayerIndex = playerIndex or 0
    local player = getPlayer(targetPlayerIndex)
    local playerBiped = nil
    if player and player.unitHandle then
        playerBiped = getObject(player.unitHandle, "biped")
    end

    ---@type Point3d
    local position = {x = 0, y = 0, z = 0}

    if playerBiped then
        local origin = getBipedWorldPosition(playerBiped)
        local viewI, viewJ, viewK = getBipedViewDirection(playerBiped)
        local spawnDistance = 5
        position = {
            x = origin.x + viewI * spawnDistance,
            y = origin.y + viewJ * spawnDistance,
            z = origin.z + viewK * spawnDistance
        }
    end

    local objectHandle = forge.spawnForgeObject(tagHandle, position)
    if not objectHandle then
        logger.debug("Place object: unable to spawn object for tag: {}", tagPath)
        return false
    end
    local objectHandleValue = objectHandle.value or objectHandle
    forge.setAttachedObject(targetPlayerIndex, objectHandleValue)
    logger.debug("Place object selected: {}", tagPath)
    return true
end

--- Copy an existing object (spawn a duplicate near the source)
---@param playerIndex integer
---@param sourceObjectHandleValue integer
---@return integer? newObjectHandle
function forge.copyObject(playerIndex, sourceObjectHandleValue)
    if not sourceObjectHandleValue then
        return nil
    end

    local sourceObject = getObject(sourceObjectHandleValue)
    if not sourceObject then
        return nil
    end

    local tagHandleValue = sourceObject.tagHandle.value
    local srcPos = sourceObject.position or {x = 0, y = 0, z = 0}

    -- Slight offset to avoid overlapping exactly
    local position = {x = srcPos.x + 0.5, y = srcPos.y + 0.5, z = srcPos.z}

    -- Copy orientation from source object
    local forward, up = sourceObject.rotation[1], sourceObject.rotation[2]

    local newObjectHandle = forge.spawnForgeObject(tagHandleValue, position,
                                                   {forward = forward, up = up})
    if not newObjectHandle then
        logger.debug("Copy object: spawn failed for handle {}", tostring(sourceObjectHandleValue))
        return nil
    end

    local newHandleValue = newObjectHandle.value or newObjectHandle

    -- Select the newly created object for the player
    forge.setAttachedObject(playerIndex, newHandleValue)

    return newHandleValue
end

---@param mapName string
---@return boolean loaded
---@return integer loadedObjects
function forge.loadSavedMap(mapName)
    if type(mapName) ~= "string" or mapName == "" then
        return false, 0
    end

    local filePath = string.format("%s/%s.fmap", defaultMapsPath, normalizeMapName(mapName))
    local fmapContent = Balltze.filesystem.readFile(filePath)
    if not fmapContent then
        logger.debug("Forge map file not found: {}", filePath)
        return false, 0
    end

    local ok, forgeMap = pcall(json.decode, fmapContent)
    if not ok or type(forgeMap) ~= "table" then
        logger.warning("Failed to parse forge map JSON: {}", filePath)
        return false, 0
    end

    if not isMapCompatible(forgeMap.map) then
        logger.warning("Forge map \"{}\" is for map \"{}\" and cannot be loaded on \"{}\"", mapName,
                       tostring(forgeMap.map), getScenarioShortName())
        return false, 0
    end

    local loadedCount = 0
    local skippedCount = 0
    local mapObjects = forgeMap.objects
    if type(mapObjects) ~= "table" then
        logger.warning("Forge map {} does not contain a valid objects array", mapName)
        return false, 0
    end

    for _, forgeObject in pairs(mapObjects) do
        local tagPath = forgeObject and forgeObject.tagPath
        local tagHandle = resolveSceneryTagHandle(tagPath)
        if tagHandle then
            local tagData = getTagData(tagHandle, "scenery")
            if tagData and tagData.flags then
                tagData.flags.castShadowByDefault = true
            end

            local position = {
                x = tonumber(forgeObject.x) or 0,
                y = tonumber(forgeObject.y) or 0,
                z = tonumber(forgeObject.z) or 0
            }
            local objectHandle = forge.spawnForgeObject(tagHandle, position, {
                euler = {
                    yaw = tonumber(forgeObject.yaw) or 0,
                    pitch = tonumber(forgeObject.pitch) or 0,
                    roll = tonumber(forgeObject.roll) or 0
                }
            })
            if objectHandle then
                loadedCount = loadedCount + 1
            else
                skippedCount = skippedCount + 1
            end
        else
            skippedCount = skippedCount + 1
        end
    end

    forge.state.map = {
        name = forgeMap.name or mapName,
        author = forgeMap.author,
        description = forgeMap.description,
        sourceFile = filePath,
        loadedObjects = loadedCount
    }

    logger.info("Loaded forge map '{}' ({} objects, {} skipped)", tostring(forge.state.map.name),
                loadedCount, skippedCount)
    return true, loadedCount
end

--- Build a nested menu tree for all forge-available object tags in the current map.
---@return table menuList @{ root = { ... } }
---@return table objectDatabase @{ [displayName] = tagPath }
function forge.getAvailableForgeObjectsMenu()
    local forgeObjectsTag = forge.constants.tagCollections.forgeObjects
    assert(forgeObjectsTag, "Forge objects tag collection not found")
    -- logger.debug("Forge objects tag: {}", forgeObjectsTag.path)
    local menuList = {root = {}}
    local objectDatabase = {}

    local function addObjectPath(tagPath, tagHandle)
        local displayName = tagPath:match("([^\\]+)$") or tagPath
        objectDatabase[displayName] = tagHandle

        local pathParts = {}
        local collectPath = false
        for part in tagPath:gmatch("[^\\]+") do
            if part == "scenery" then
                collectPath = true
            elseif collectPath then
                part = part:gsub("^_", "")
                if part ~= "" then
                    table.insert(pathParts, part)
                end
            end
        end

        if #pathParts == 0 then
            pathParts = {displayName}
        end

        local treePosition = menuList.root
        for _, part in ipairs(pathParts) do
            if not treePosition[part] then
                treePosition[part] = {}
            end
            treePosition = treePosition[part]
        end
    end

    local function walkTagCollection(tagCollectionHandle)
        local ok, collectionData = pcall(function()
            return getTagData(tagCollectionHandle, "tag_collection")
        end)
        if not ok or not collectionData or not collectionData.tagReferences then
            return
        end

        for _, tagReference in ipairs(collectionData.tagReferences) do
            if not tagReference or not tagReference.tag then
                goto continue
            end

            local referenceTag = tagReference.tag
            local tagPath = referenceTag.path
            local tagHandle = referenceTag.tagHandle

            if not tagPath or tagPath == "" then
                goto continue
            end

            local nestedOk, nestedCollectionData = pcall(function()
                if tagHandle and tagHandle.value then
                    return getTagData(tagHandle.value, "tag_collection")
                end
                return nil
            end)

            if nestedOk and nestedCollectionData then
                walkTagCollection(tagHandle.value)
            else
                addObjectPath(tagPath, tagHandle)
            end

            ::continue::
        end
    end

    if not forgeObjectsTag then
        return menuList, objectDatabase
    end

    walkTagCollection(forgeObjectsTag.handle.value)
    return menuList, objectDatabase
end

local bipeds = forge.constants.bipeds

--- Swap a player's biped and restore gameplay state used by Forge controls.
---@param playerIndex integer
---@param targetBipedName "monitor" | "player"
---@param previousPosition? {x: number, y: number, z: number}
---@return BipedObject?
function forge.swapPlayerBiped(playerIndex, targetBipedName, previousPosition)
    -- Reset attached object when swapping bipeds to avoid invalid states
    forge.clearAttachedObject(playerIndex)

    local player = getPlayer(playerIndex)
    if not player then
        return nil
    end

    local targetBiped = bipeds[targetBipedName]
    if not targetBiped then
        return nil
    end

    core.swapBiped(playerIndex, targetBiped.handle.value)
    -- If biped exists at this point in time
    -- if engine.object.getObject(player.unitHandle.value, "biped") then
    if not player.unitHandle:isNull() then
        engine.object.deleteObject(player.unitHandle.value)
    end
    sleep(1)

    local playerBiped
    sleep(function()
        playerBiped = core.getPlayerObject(playerIndex)
        return playerBiped ~= nil
    end)

    if not playerBiped then
        return nil
    end

    if previousPosition then
        core.teleportPlayer(playerIndex, previousPosition.x, previousPosition.y, previousPosition.z)
    end
    return playerBiped
end

local isGameClient = engine.game.getGameConnectionType() == "networkClient"

function forge.load()
    hudCrosshair.init(forge.constants.weaponHudInterfaces.monitorCrosshair)
    hudText.init(forge.constants.fonts.hud)
end

function forge.controls()
    for playerIndex = 0, 15 do
        -- Does this player exists?
        if getPlayer(playerIndex) then
            -- We create individual anonymous scripts for each player so that each thread
            -- can sleep independently of other players
            script.create(function()
                if not forge.mode == "edit" then
                    return
                end
                local player = getPlayer(playerIndex)
                if not player then
                    return
                end
                local playerBiped = getObject(player.unitHandle.value, "biped")
                if not playerBiped then
                    return
                end
                local previousPosition = {
                    x = playerBiped.position.x,
                    y = playerBiped.position.y,
                    z = playerBiped.position.z
                }
                local isPlayerMonitor = playerBiped.tagHandle.value == bipeds.monitor.handle.value
                local playerInput = playerBiped.unitControlFlags
                local playerState = getPlayerState(playerIndex)
                local attachedObjectHandle = playerState.attachedObject
                local aimedObjectHandle = nil
                if isPlayerMonitor then
                    aimedObjectHandle = getAimedObjectHandle(playerBiped)
                end

                if isGameClient then
                    updateMonitorHud(attachedObjectHandle, aimedObjectHandle)
                end

                if isPlayerMonitor and attachedObjectHandle then
                    local attachedObject = getObject(attachedObjectHandle)
                    if not attachedObject then
                        detachAttachedObject(playerIndex, false)
                        setMonitorMode("idle")
                        return
                    end

                    if playerInput.action then
                        if playerState.currentAngle == "yaw" then
                            playerState.currentAngle = "pitch"
                        elseif playerState.currentAngle == "pitch" then
                            playerState.currentAngle = "roll"
                        else
                            playerState.currentAngle = "yaw"
                        end
                        -- logger.debug("Player {} rotation axis: {}", playerIndex, rotationState.currentAngle)
                    end

                    setMonitorMode("holding")

                    if playerInput.light then
                        forge.callbacks.launchMonitorMenu("tools")
                        return
                    end

                    if playerInput.jump then
                        detachAttachedObject(playerIndex, true)
                        setMonitorMode("idle")
                        return
                    end

                    if playerInput.melee then
                        playerState.lockDistance = not playerState.lockDistance
                        logger.debug("Player {} distance lock: {}", playerIndex,
                                     playerState.lockDistance)
                        return
                    end

                    if playerInput.secondaryTrigger then
                        detachAttachedObject(playerIndex, false)
                        local aimedObjectHandle = getAimedObjectHandle(playerBiped)
                        updateAimedObjectHighlight(playerIndex, aimedObjectHandle)
                        if aimedObjectHandle then
                            setMonitorMode("selected")
                        else
                            setMonitorMode("idle")
                        end
                        return
                    end

                    -- Rotation input is handled per-frame above.

                    updateAttachedObjectDistance(playerIndex, playerBiped)
                    if not updateAttachedObjectFromCamera(playerIndex, playerBiped) then
                        setMonitorMode("idle")
                        return
                    end

                    return
                end

                if isPlayerMonitor then
                    local aimedObjectHandle = getAimedObjectHandle(playerBiped)
                    updateAimedObjectHighlight(playerIndex, aimedObjectHandle)
                    if aimedObjectHandle then
                        setMonitorMode("selected")
                    else
                        setMonitorMode("idle")
                    end

                    if playerInput.action and not attachedObjectHandle and aimedObjectHandle then
                        forge.copyObject(playerIndex, aimedObjectHandle)
                        return
                    end
                end

                if playerInput.primaryTrigger and isPlayerMonitor and not attachedObjectHandle then
                    if pickupAimedObject(playerIndex, playerBiped) then
                        return
                    end
                end

                if playerInput.light then
                    if not isPlayerMonitor and playerBiped.tagHandle.value ==
                        bipeds.player.handle.value then
                        logger.debug("Player {} is pressing light", playerIndex)
                        playerBiped =
                            forge.swapPlayerBiped(playerIndex, "monitor", previousPosition)
                        if not playerBiped then
                            return
                        end
                        logger.debug("Player {} swapped to monitor", playerIndex)
                        playerBiped.vitals.health = 1
                        playerBiped.vitals.shield = 1
                        -- TODO Restore biped rotation as well
                        setMonitorMode("idle")
                        logger.debug("Player {} monitor mode set to idle", playerIndex)
                    else
                        forge.callbacks.launchMonitorMenu(
                            forge.getAttachedObject(playerIndex) and "tools" or "place")
                    end
                elseif playerInput.crouch then
                    if isPlayerMonitor then
                        logger.debug("Player {} is pressing crouch", playerIndex)
                        playerBiped = forge.swapPlayerBiped(playerIndex, "player", previousPosition)
                        if not playerBiped then
                            return
                        end
                        setMonitorMode("hidden")
                    end
                end
            end)
        end
    end
end

--- Handle on frame events
---
--- - Object rotation using mouse wheel
function forge.frame()
    if isGameClient then
        local localPlayerIndex = engine.player.getLocalPlayerHandle(
                                     engine.player.getPlayer().localPlayerIndex).index
        local playerState = getPlayerState(localPlayerIndex)
        if playerState.attachedObject then
            local mouseWheel = engine.input.getMouseWheel()
            if mouseWheel ~= 0 then
                local currentAxis = playerState.currentAngle or "yaw"
                local step = abs(tonumber(playerState.rotationStep) or 5)
                local direction = (mouseWheel > 0) and -1 or 1
                local previousRotation = tonumber(playerState[currentAxis]) or 0
                local nextRotation = previousRotation + (step * direction)
                playerState[currentAxis] = normalizeRotation(nextRotation)
                applyAttachedObjectRotation(playerIndex)
                -- logger.debug("Player {} {}: {}", playerIndex, currentAxis, rotationState[currentAxis])
            end
        end
    end
end

return forge

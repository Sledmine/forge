local engine = Engine
local core = require "forge.core"
local script = require "script"
local sleep = script.sleep
local getPlayer = engine.player.getPlayer
local getObject = engine.object.getObject
local getTagData = engine.tag.getTagData
local logger = Balltze.logger
local sqrt = math.sqrt

local component = require "ui.component"
local list = require "ui.list"
local button = require "ui.button"
component.callbacks()

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
        }
    },
    callbacks = {
        ---@param mode "tools" | "place"
        launchMonitorMenu = function(mode)
            logger.debug("Forge: launchMonitorMenu callback not set, mode={}", mode)
        end
    },
    state = {
        ---@type table<integer, {attachedObject: integer?, distance: number, lockDistance: boolean}>
        players = {},
        player = {
            ---@type integer?
            attachedObject = nil
        }
    }
}

local function getPlayerState(playerIndex)
    if type(playerIndex) ~= "number" then
        playerIndex = 0
    end
    forge.state.players[playerIndex] = forge.state.players[playerIndex] or {
        attachedObject = nil,
        distance = 5,
        lockDistance = true
    }
    return forge.state.players[playerIndex]
end

local function calculateDistance(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return sqrt(dx * dx + dy * dy + dz * dz)
end

local function getBipedWorldPosition(playerBiped)
    if playerBiped and playerBiped.bipedPosition then
        return playerBiped.bipedPosition
    end
    if playerBiped and playerBiped.position then
        return playerBiped.position
    end
    return {x = 0, y = 0, z = 0}
end

local function getBipedViewDirection(playerBiped)
    if playerBiped and playerBiped.lookingVector then
        local lv = playerBiped.lookingVector
        if lv.i or lv.j or lv.k then
            return lv.i or 0, lv.j or 0, lv.k or 0
        end
    end

    local cameraX = playerBiped and playerBiped.cameraX or 0
    local cameraY = playerBiped and playerBiped.cameraY or 0
    local cameraZ = playerBiped and playerBiped.cameraZ or 0
    return cameraX, cameraY, cameraZ
end

function forge.getAttachedObject(playerIndex)
    local state = getPlayerState(playerIndex)
    return state.attachedObject
end

function forge.setAttachedObject(playerIndex, objectHandle)
    local state = getPlayerState(playerIndex)
    state.attachedObject = objectHandle

    local player = getPlayer(playerIndex)
    if player and player.unitHandle and player.unitHandle.value then
        local playerBiped = getObject(player.unitHandle.value, "biped")
        local object = getObject(objectHandle)
        if playerBiped and object and object.position then
            local bipedPosition = getBipedWorldPosition(playerBiped)
            state.distance = calculateDistance(bipedPosition, object.position)
        end
    end

    forge.state.player.attachedObject = objectHandle
end

function forge.detachAttachedObject(playerIndex, deleteObject)
    local state = getPlayerState(playerIndex)
    if deleteObject and state.attachedObject then
        local object = engine.object.getObject(state.attachedObject)
        if object then
            engine.object.deleteObject(state.attachedObject)
        end
    end
    state.attachedObject = nil
    forge.state.player.attachedObject = nil
end

function forge.clearAttachedObject(playerIndex)
    forge.detachAttachedObject(playerIndex, true)
end

function forge.updateAttachedObjectFromCamera(playerIndex, playerBiped)
    local state = getPlayerState(playerIndex)
    if not state.attachedObject then
        return false
    end

    local attachedObject = getObject(state.attachedObject)
    if not attachedObject or not attachedObject.position then
        forge.detachAttachedObject(playerIndex, false)
        return false
    end

    if not playerBiped then
        return false
    end

    local bipedPosition = getBipedWorldPosition(playerBiped)
    local cameraX, cameraY, cameraZ = getBipedViewDirection(playerBiped)

    local distance = state.distance or 5
    if distance < 0.5 then
        distance = 0.5
    end

    attachedObject.position.x = bipedPosition.x + cameraX * distance
    attachedObject.position.y = bipedPosition.y + cameraY * distance
    attachedObject.position.z = bipedPosition.z + cameraZ * distance

    return true
end

function forge.updateAttachedObjectDistance(playerIndex, playerBiped)
    local state = getPlayerState(playerIndex)
    if state.lockDistance or not state.attachedObject then
        return
    end

    local attachedObject = getObject(state.attachedObject)
    if not attachedObject or not attachedObject.position then
        return
    end

    local bipedPosition = getBipedWorldPosition(playerBiped)
    state.distance = calculateDistance(bipedPosition, attachedObject.position)
end

---@param itemLabel string
---@param tagHandle TagHandle|integer
---@param playerIndex integer?
---@return boolean
function forge.placeObject(itemLabel, tagHandle, playerIndex)
    if not tagHandle then
        logger.debug("Place object: missing tag handle for {}", itemLabel)
        return false
    end

    local targetPlayerIndex = playerIndex or 0
    local player = getPlayer(targetPlayerIndex)
    local playerBiped = nil
    if player and player.unitHandle and player.unitHandle.value then
        playerBiped = getObject(player.unitHandle.value, "biped")
    end

    local position = {x = 0, y = 0, z = 0}
    if playerBiped then
        local origin = getBipedWorldPosition(playerBiped)
        local cameraX, cameraY, cameraZ = getBipedViewDirection(playerBiped)
        local spawnDistance = 5
        position = {
            x = origin.x + cameraX * spawnDistance,
            y = origin.y + cameraY * spawnDistance,
            z = origin.z + cameraZ * spawnDistance
        }
    end

    local objectHandle = engine.object.createObject(tagHandle, nil, position)
    if not objectHandle then
        logger.debug("Place object: unable to spawn {}", itemLabel)
        return false
    end

    local objectHandleValue = objectHandle.value or objectHandle
    forge.setAttachedObject(targetPlayerIndex, objectHandleValue)
    logger.debug("Place object selected: {} ({})", itemLabel,
                 objectHandleValue or "unknown")
    forge.setMonitorMode("holding")
    return true
end

local monitorCrosshairHudTag
local monitorCrosshairHudData

function forge.load()
    monitorCrosshairHudTag = forge.constants.weaponHudInterfaces.monitorCrosshair
    assert(monitorCrosshairHudTag, "Monitor crosshair HUD tag not found")
    monitorCrosshairHudData =
        getTagData(monitorCrosshairHudTag.handle.value, "weapon_hud_interface")
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
local weaponHudInterfaces = forge.constants.weaponHudInterfaces

--- Pack channels into EngineColorARGBInt (0xAARRGGBB).
---@param alpha integer
---@param red integer
---@param green integer
---@param blue integer
---@return integer
local function toArgbInt(alpha, red, green, blue)
    return (((alpha * 256) + red) * 256 + green) * 256 + blue
end

---@param color integer
---@return integer
local function getAlphaChannel(color)
    return math.floor(color / 16777216) % 256
end

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

local crosshairModes = {hidden = 0, idle = 1, selected = 2, holding = 3, bounds = 4}

--- Changes Forge crosshair state
---@param mode "hidden" | "idle" | "selected" | "holding" | "bounds"
function forge.setMonitorMode(mode)
    if type(mode) ~= "string" then
        return
    end

    local state = crosshairModes[mode]
    if state == nil then
        return
    end
    assert(monitorCrosshairHudTag)
    assert(monitorCrosshairHudData)

    local crosshairs = monitorCrosshairHudData.crosshairs
    if not crosshairs or #crosshairs < 1 then
        return
    end
    local crosshair = crosshairs[1]
    if not crosshair then
        return
    end

    local overlays = crosshair.crosshairOverlays
    if not overlays or #overlays < 1 then
        return
    end
    local overlay = overlays[1]
    if not overlay then
        return
    end

    local defaultColor = overlay.defaultColor.parameters.defaultColor
    local alpha = getAlphaChannel(defaultColor)

    if overlay.sequenceIndex == state then
        return
    end

    if state == crosshairModes.bounds then
        overlay.defaultColor.parameters.defaultColor = toArgbInt(alpha, 255, 0, 0)
    elseif state == crosshairModes.selected or state == crosshairModes.holding then
        overlay.defaultColor.parameters.defaultColor = toArgbInt(alpha, 0, 255, 0)
    else
        overlay.defaultColor.parameters.defaultColor = toArgbInt(alpha, 64, 169, 255)
    end

    overlay.sequenceIndex = state
end

function forge.controls()
    for playerIndex = 0, 15 do
        -- Does this player exists?
        if getPlayer(playerIndex) then
            -- We create individual anonymous scripts for each player so that each thread
            -- can sleep independently of other players
            script.create(function()
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
                if forge.mode == "edit" then
                    local isMonitor = playerBiped.tagHandle.value == bipeds.monitor.handle.value
                    local input = playerBiped.unitControlFlags
                    local playerState = getPlayerState(playerIndex)
                    local attachedObjectHandle = playerState.attachedObject

                    if isMonitor and attachedObjectHandle then
                        local attachedObject = getObject(attachedObjectHandle)
                        if not attachedObject or not attachedObject.position then
                            forge.detachAttachedObject(playerIndex, false)
                            forge.setMonitorMode("idle")
                            return
                        end

                        forge.setMonitorMode("holding")

                        if input.light then
                            forge.callbacks.launchMonitorMenu("tools")
                            return
                        end

                        if input.jump then
                            forge.detachAttachedObject(playerIndex, true)
                            forge.setMonitorMode("idle")
                            return
                        end

                        if input.melee then
                            playerState.lockDistance = not playerState.lockDistance
                            logger.debug("Player {} distance lock: {}", playerIndex,
                                         playerState.lockDistance)
                            return
                        end

                        if input.secondaryTrigger or input.action then
                            forge.detachAttachedObject(playerIndex, false)
                            forge.setMonitorMode("idle")
                            return
                        end

                        forge.updateAttachedObjectDistance(playerIndex, playerBiped)
                        if not forge.updateAttachedObjectFromCamera(playerIndex, playerBiped) then
                            forge.setMonitorMode("idle")
                            return
                        end

                        return
                    end

                    if isMonitor then
                        forge.setMonitorMode("idle")
                    end

                    if input.light then
                        if not isMonitor and playerBiped.tagHandle.value ==
                            bipeds.player.handle.value then
                            Balltze.logger.debug("Player {} is pressing light", playerIndex)
                            playerBiped = forge.swapPlayerBiped(playerIndex, "monitor",
                                                                previousPosition)
                            if not playerBiped then
                                return
                            end
                            Balltze.logger.debug("Player {} swapped to monitor", playerIndex)
                            playerBiped.vitals.health = 1
                            playerBiped.vitals.shield = 1
                            -- TODO Restore biped rotation as well
                            forge.setMonitorMode("idle")
                            Balltze.logger.debug("Player {} monitor mode set to idle", playerIndex)
                        else
                            forge.callbacks.launchMonitorMenu(
                                forge.getAttachedObject(playerIndex) and "tools" or "place")
                        end
                    elseif input.crouch then
                        if isMonitor then
                            Balltze.logger.debug("Player {} is pressing crouch", playerIndex)
                            playerBiped = forge.swapPlayerBiped(playerIndex, "player",
                                                                previousPosition)
                            if not playerBiped then
                                return
                            end
                            forge.setMonitorMode("hidden")
                        end
                    end
                end
            end)
        end
    end
end

return forge

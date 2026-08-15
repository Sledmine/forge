local engine = Engine
local core = require "forge.core"
local script = require "script"
local sleep = script.sleep
local getPlayer = engine.player.getPlayer
local getObject = engine.object.getObject
local getTagData = engine.tag.getTagData
local logger = Balltze.logger

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
        launchMonitorMenu = function()
        end
    }
}

local monitorCrosshairHudTag
local monitorCrosshairHudData

function forge.load()
    monitorCrosshairHudTag = forge.constants.weaponHudInterfaces.monitorCrosshair
    assert(monitorCrosshairHudTag, "Monitor crosshair HUD tag not found")
    monitorCrosshairHudData = getTagData(monitorCrosshairHudTag.handle.value, "weapon_hud_interface")
end

--- Build a nested menu tree for all forge-available object tags in the current map.
---@return table menuList @{ root = { ... } }
---@return table objectDatabase @{ [displayName] = tagPath }
function forge.getAvailableForgeObjectsMenu()
    local forgeObjectsTag = forge.constants.tagCollections.forgeObjects
    --logger.debug("Forge objects tag: {}", forgeObjectsTag and forgeObjectsTag.path or "nil")
    local menuList = { root = {} }
    local objectDatabase = {}

    local function addObjectPath(tagPath)
        local displayName = tagPath:match("([^\\]+)$") or tagPath
        objectDatabase[displayName] = tagPath

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
                addObjectPath(tagPath)
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
    local player = getPlayer(playerIndex)
    if not player then
        return nil
    end

    local targetBiped = bipeds[targetBipedName]
    if not targetBiped then
        return nil
    end

    core.swapBiped(playerIndex, targetBiped.handle.value)
    engine.object.deleteObject(player.unitHandle.value)
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

                    if playerBiped.unitControlFlags.light then
                        if not isMonitor and playerBiped.tagHandle.value ==
                            bipeds.player.handle.value then
                            Balltze.logger.debug("Player {} is pressiwng light", playerIndex)
                            playerBiped = forge.swapPlayerBiped(playerIndex,
                                                                  "monitor",
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
                            forge.callbacks.launchMonitorMenu()
                        end
                    elseif playerBiped.unitControlFlags.crouch then
                        if isMonitor then
                            Balltze.logger.debug("Player {} is pressing crouch", playerIndex)
                            playerBiped = forge.swapPlayerBiped(playerIndex,
                                                                  "player",
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

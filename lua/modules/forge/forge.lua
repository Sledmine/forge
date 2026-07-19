local engine = Engine
local constants = require "forge.constants"
local core = require "forge.core"
local getPlayer = engine.gameState.getPlayer
local getObject = engine.gameState.getObject
local objectType = engine.tag.objectType
local constants = require "forge.constants"
local bipeds = constants.bipeds

local forge = {
    ---@type "edit" | "normal"
    mode = "normal"
}

local monitorCrosshairHudTag = constants.weaponHudInterfaces.monitorCrosshair
local crosshairModes = {hidden = 0, idle = 1, selected = 2, holding = 3, bounds = 4}

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

    local crosshairs = monitorCrosshairHudTag.data.crosshairs
    if not crosshairs or crosshairs.count < 1 then
        return
    end
    local crosshair = crosshairs.elements[1]
    if not crosshair then
        return
    end

    local overlays = crosshair.crosshairOverlays
    if not overlays or overlays.count < 1 then
        return
    end
    local overlay = overlays.elements[1]
    if not overlay then
        return
    end

    local defaultColor = overlay.defaultColor
    local alpha = getAlphaChannel(defaultColor)

    if overlay.sequenceIndex == state then
        return
    end

    if state == crosshairModes.bounds then
        overlay.defaultColor = toArgbInt(alpha, 255, 0, 0)
    elseif state == crosshairModes.selected or state == crosshairModes.holding then
        overlay.defaultColor = toArgbInt(alpha, 0, 255, 0)
    else
        overlay.defaultColor = toArgbInt(alpha, 64, 169, 255)
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
                local playerBiped = getObject(player.objectHandle.value, objectType.biped)
                if not playerBiped then
                    return
                end
                local previousPosition = {
                    x = playerBiped.position.x,
                    y = playerBiped.position.y,
                    z = playerBiped.position.z
                }
                if playerBiped.unitControlFlags.light and forge.mode == "edit" then
                    if playerBiped.tagHandle.value == bipeds.spartan.handle.value then
                        logger:debug("Player {} is pressing light", playerIndex)
                        core.swapBiped(playerIndex, bipeds.monitor.handle.value)
                        engine.gameState.deleteObject(player.objectHandle)
                        sleep(1)
                        sleep(function()
                            playerBiped = core.getPlayerObject(playerIndex)
                            return playerBiped ~= nil
                        end)
                        core.teleportPlayer(playerIndex, previousPosition.x, previousPosition.y,
                                            previousPosition.z)
                        playerBiped.vitals.health = 1
                        playerBiped.vitals.shield = 1
                        -- TODO Restore biped rotation as well
                        forge.setMonitorMode("idle")
                    end
                elseif playerBiped.unitControlFlags.crouch then
                    logger:debug("Player {} is pressing crouch", playerIndex)
                    if playerBiped.tagHandle.value == bipeds.monitor.handle.value then
                        core.swapBiped(playerIndex, bipeds.spartan.handle.value)
                        engine.gameState.deleteObject(player.objectHandle)
                        sleep(1)
                        sleep(function()
                            return core.getPlayerObject(playerIndex) ~= nil
                        end)
                        core.teleportPlayer(playerIndex, previousPosition.x, previousPosition.y,
                                            previousPosition.z)
                        forge.setMonitorMode("hidden")
                    end
                end
            end)
        end
    end
end

return forge

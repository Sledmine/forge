local engine = Engine
local core = require "forge.core"
local script = require "script"
local sleep = script.sleep
local constants = require "forge.constants"
local bipeds = constants.bipeds
local getPlayer = engine.player.getPlayer
local getObject = engine.object.getObject
local component = require "ui.component"
local list = require "ui.list"
local button = require "ui.button"
component.callbacks()

local forgeMenu = component.new(constants.menus.forge.handle.value)
local forgeOptions = list.new(forgeMenu:get("category"), 2)
local forgeFirstButton = button.new(forgeOptions:get("_1"))
Balltze.logger.debug("Forge first button text: {}", forgeFirstButton:getText())
forgeFirstButton:setText("Forge First Button")
forgeFirstButton:onClick(function()
    Balltze.logger.debug("Forge first button clicked")
    forgeFirstButton:setText(string.reverse(tostring(math.random(1000000, 9999999))))
end)

forgeMenu:onOpen(function()
    Balltze.logger.debug("Forge menu opened")
    -- Add random string just to test if the button is working
end)

forgeOptions:setItems({
    {label = "Option 1", value = 1},
    {label = "Option 2", value = 2},
    {label = "Option 3", value = 3},
    {label = "Option 4", value = 4},
    {label = "Option 5", value = 5},
    {label = "Option 6", value = 6},
    {label = "Option 7", value = 7}
})


local forge = {
    ---@type "edit" | "normal"
    mode = "edit"
}

local monitorCrosshairHudTag = constants.weaponHudInterfaces.monitorCrosshair
local monitorCrosshairHudData = monitorCrosshairHudTag and monitorCrosshairHudTag:getData()
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
                        if not isMonitor and
                            playerBiped.tagHandle.value == bipeds.spartan.handle.value then
                            Balltze.logger.debug("Player {} is pressiwng light", playerIndex)
                            core.swapBiped(playerIndex, bipeds.monitor.handle.value)
                            engine.object.deleteObject(player.unitHandle.value)
                            sleep(1)
                            sleep(function()
                                playerBiped = core.getPlayerObject(playerIndex)
                                return playerBiped ~= nil
                            end)
                            core.teleportPlayer(playerIndex, previousPosition.x,
                                                previousPosition.y, previousPosition.z)
                            Balltze.logger.debug("Player {} swapped to monitor", playerIndex)
                            playerBiped.vitals.health = 1
                            playerBiped.vitals.shield = 1
                            -- TODO Restore biped rotation as well
                            forge.setMonitorMode("idle")
                            Balltze.logger.debug("Player {} monitor mode set to idle", playerIndex)
                        else
                            forgeMenu:launch()
                        end
                    elseif playerBiped.unitControlFlags.crouch then
                        if isMonitor then
                            Balltze.logger.debug("Player {} is pressing crouch", playerIndex)
                            core.swapBiped(playerIndex, bipeds.spartan.handle.value)
                            engine.object.deleteObject(player.unitHandle.value)
                            sleep(1)
                            sleep(function()
                                return core.getPlayerObject(playerIndex) ~= nil
                            end)
                            core.teleportPlayer(playerIndex, previousPosition.x,
                                                previousPosition.y, previousPosition.z)
                            forge.setMonitorMode("hidden")
                        end
                    end
                end
            end)
        end
    end
end

return forge

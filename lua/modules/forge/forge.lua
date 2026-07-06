local engine = Engine
local constants = require "forge.constants"

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

return forge

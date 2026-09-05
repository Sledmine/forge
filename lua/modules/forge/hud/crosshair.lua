local engine = Engine
local getObject = engine.object.getObject
local getTagEntry = engine.tag.getTagEntry
local getTagData = engine.tag.getTagData

local crosshair = {
    crosshairModes = {hidden = 0, idle = 1, selected = 2, holding = 3, bounds = 4},
    highlightShaderGroups = {
        shader_environment = true,
        shader_transparent_glass = true,
        shader_transparent_plasma = true
    },
    highlightModeColors = {
        selected = {r = 0, g = 1, b = 0},
        holding = {r = 1, g = 1, b = 0}
    },
    monitorCrosshairHudTag = nil,
    monitorCrosshairHudData = nil,
    activeHighlightShaderHandle = nil,
    activeHighlightShaderHandleValue = nil,
    activeHighlightMode = nil,
    cachedHighlightShaderColors = {}
}

local function toArgbInt(alpha, red, green, blue)
    return (((alpha * 256) + red) * 256 + green) * 256 + blue
end

local function getAlphaChannel(color)
    return math.floor(color / 16777216) % 256
end

local function copyRgbColor(color)
    if not color then
        return nil
    end
    return {r = color.r, g = color.g, b = color.b}
end

local function applyRgbColor(targetColor, sourceColor)
    if not targetColor or not sourceColor then
        return
    end
    targetColor.r = sourceColor.r
    targetColor.g = sourceColor.g
    targetColor.b = sourceColor.b
end

function crosshair.init(weaponHudInterfaceTag)
    crosshair.monitorCrosshairHudTag = weaponHudInterfaceTag
    assert(crosshair.monitorCrosshairHudTag, "Monitor crosshair HUD tag not found")
    crosshair.monitorCrosshairHudData =
        getTagData(crosshair.monitorCrosshairHudTag.handle.value, "weapon_hud_interface")
end

function crosshair.getHighlightShaderData(objectHandle)
    if not objectHandle then
        return nil, nil, nil
    end

    local object = getObject(objectHandle)
    if not object or not object.tagHandle or not object.tagHandle.value then
        return nil, nil, nil
    end
    if object.tagHandle:isNull() then
        return nil, nil, nil
    end

    local tagEntry = getTagEntry(object.tagHandle.value)
    if not tagEntry or tagEntry.group ~= "scenery" then
        return nil, nil, nil
    end

    local sceneryTag = getTagData(object.tagHandle.value, "scenery")
    if not sceneryTag or not sceneryTag.modifierShader or not sceneryTag.modifierShader.tagHandle then
        return nil, nil, nil
    end

    local shaderHandle = sceneryTag.modifierShader.tagHandle
    if not shaderHandle or not shaderHandle.value then
        return nil, nil, nil
    end

    local shaderTagEntry = getTagEntry(shaderHandle.value)
    if not shaderTagEntry or not crosshair.highlightShaderGroups[shaderTagEntry.group] then
        return nil, nil, nil
    end

    local ok, shaderData = pcall(function()
        return getTagData(shaderHandle, shaderTagEntry.group)
    end)
    if not ok then
        return nil, nil, nil
    end

    if not shaderData or not shaderData.perpendicularTintColor or not shaderData.parallelTintColor then
        return nil, nil, nil
    end

    return shaderHandle, shaderHandle.value, shaderData
end

function crosshair.restoreActiveHighlightShaderTint()
    if not crosshair.activeHighlightShaderHandle or not crosshair.activeHighlightShaderHandleValue then
        return
    end

    local shaderTagEntry = getTagEntry(crosshair.activeHighlightShaderHandle)
    local originalColors = crosshair.cachedHighlightShaderColors[crosshair.activeHighlightShaderHandleValue]
    if not shaderTagEntry or not originalColors then
        crosshair.activeHighlightShaderHandle = nil
        crosshair.activeHighlightShaderHandleValue = nil
        crosshair.activeHighlightMode = nil
        return
    end

    local ok, shaderData = pcall(function()
        return getTagData(crosshair.activeHighlightShaderHandle, shaderTagEntry.group)
    end)
    if not ok then
        crosshair.activeHighlightShaderHandle = nil
        crosshair.activeHighlightShaderHandleValue = nil
        crosshair.activeHighlightMode = nil
        return
    end

    if shaderData then
        applyRgbColor(shaderData.perpendicularTintColor, originalColors.perpendicularTintColor)
        applyRgbColor(shaderData.parallelTintColor, originalColors.parallelTintColor)
    end

    crosshair.activeHighlightShaderHandle = nil
    crosshair.activeHighlightShaderHandleValue = nil
    crosshair.activeHighlightMode = nil
end

function crosshair.updateMonitorHighlightTint(mode, state)
    local targetColor = crosshair.highlightModeColors[mode]
    local objectHandle

    if mode == "holding" then
        objectHandle = state and state.player and state.player.attachedObject
    elseif mode == "selected" then
        objectHandle = state and state.player and state.player.highlightedObject
    end

    local shaderHandle
    local shaderHandleValue
    local shaderData
    if targetColor and objectHandle then
        shaderHandle, shaderHandleValue, shaderData = crosshair.getHighlightShaderData(objectHandle)
    end

    if crosshair.activeHighlightShaderHandle and
        (crosshair.activeHighlightShaderHandleValue ~= shaderHandleValue or crosshair.activeHighlightMode ~= mode) then
        crosshair.restoreActiveHighlightShaderTint()
    end

    if not shaderHandle or not shaderData or not targetColor then
        return
    end

    if shaderHandleValue == nil then
        return
    end
    local shaderCacheKey = shaderHandleValue

    if not crosshair.cachedHighlightShaderColors[shaderCacheKey] then
        crosshair.cachedHighlightShaderColors[shaderCacheKey] = {
            perpendicularTintColor = copyRgbColor(shaderData.perpendicularTintColor),
            parallelTintColor = copyRgbColor(shaderData.parallelTintColor)
        }
    end

    applyRgbColor(shaderData.perpendicularTintColor, targetColor)
    applyRgbColor(shaderData.parallelTintColor, targetColor)
    crosshair.activeHighlightShaderHandle = shaderHandle
    crosshair.activeHighlightShaderHandleValue = shaderCacheKey
    crosshair.activeHighlightMode = mode
end

function crosshair.setMode(mode, state)
    if type(mode) ~= "string" then
        return
    end

    local crosshairState = crosshair.crosshairModes[mode]
    if crosshairState == nil then
        return
    end
    assert(crosshair.monitorCrosshairHudTag)
    assert(crosshair.monitorCrosshairHudData)

    local crosshairs = crosshair.monitorCrosshairHudData.crosshairs
    if not crosshairs or #crosshairs < 1 then
        return
    end
    local crosshairEntry = crosshairs[1]
    if not crosshairEntry then
        return
    end

    local overlays = crosshairEntry.crosshairOverlays
    if not overlays or #overlays < 1 then
        return
    end
    local overlay = overlays[1]
    if not overlay then
        return
    end

    crosshair.updateMonitorHighlightTint(mode, state)

    local defaultColor = overlay.defaultColor.parameters.defaultColor
    local alpha = getAlphaChannel(defaultColor)

    if crosshairState == crosshair.crosshairModes.bounds then
        overlay.defaultColor.parameters.defaultColor = toArgbInt(alpha, 255, 0, 0)
    elseif crosshairState == crosshair.crosshairModes.selected or crosshairState == crosshair.crosshairModes.holding then
        overlay.defaultColor.parameters.defaultColor = toArgbInt(alpha, 0, 255, 0)
    elseif crosshairState == crosshair.crosshairModes.idle or crosshairState == crosshair.crosshairModes.hidden then
        overlay.defaultColor.parameters.defaultColor = toArgbInt(alpha, 64, 169, 255)
    end

    if overlay.sequenceIndex == crosshairState then
        return
    end

    overlay.sequenceIndex = crosshairState
end

return crosshair

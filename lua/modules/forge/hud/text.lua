local engine = Engine
local getObject = engine.object.getObject
local getTagEntry = engine.tag.getTagEntry

local hud = {
    hudTextColor = {a = 0.8, r = 0.890, g = 0.949, b = 0.992},
    centerHudText = nil,
    centerHudTextValue = nil,
    rightHudText = nil,
    rightHudTextValue = nil,
    hudNoticeState = {
        untilTick = 0,
        primary = nil,
        secondary = nil
    },
    constants = {
        ---@type TagEntry?
        fontTag = nil
    }
}

local function formatHudLines(primary, secondary)
    if type(primary) ~= "string" or primary == "" then
        return nil
    end
    if type(secondary) == "string" and secondary ~= "" then
        --return string.format("%s\r\n%s", primary, secondary)
        return string.format("%s\n%s", primary, secondary)
    end
    return primary
end

local function removeCenterHud()
    if hud.centerHudText then
        hud.centerHudText:remove()
        hud.centerHudText = nil
    end
    hud.centerHudTextValue = nil
end

local function removeRightHud()
    if hud.rightHudText then
        hud.rightHudText:remove()
        hud.rightHudText = nil
    end
    hud.rightHudTextValue = nil
end

---@param text string?
---@param x integer
---@param y integer
---@param options InterfaceTextOptions
local function setCenterHud(text, x, y, options)
    if not (engine.interface and engine.interface.addText) then
        return
    end

    if type(text) ~= "string" or text == "" then
        removeCenterHud()
        return
    end

    if not hud.centerHudText then
        hud.centerHudText = engine.interface.addText(text, x, y, options)
        hud.centerHudTextValue = text
        return
    end

    if hud.centerHudTextValue ~= text then
        hud.centerHudText:setText(text)
        hud.centerHudTextValue = text
    end
end

---@param text string?
---@param x integer
---@param y integer
---@param options InterfaceTextOptions
local function setRightHud(text, x, y, options)
    if not (engine.interface and engine.interface.addText) then
        return
    end

    if type(text) ~= "string" or text == "" then
        removeRightHud()
        return
    end

    if not hud.rightHudText then
        hud.rightHudText = engine.interface.addText(text, x, y, options)
        hud.rightHudTextValue = text
        return
    end

    if hud.rightHudTextValue ~= text then
        hud.rightHudText:setText(text)
        hud.rightHudTextValue = text
    end
end

function hud.clearMonitorHud()
    removeCenterHud()
    removeRightHud()
end

function hud.setHudNotice(primary, secondary, durationTicks)
    local ticks = tonumber(durationTicks) or 30
    local nowTick = engine.game.getTickCount() or 0
    hud.hudNoticeState.primary = primary
    hud.hudNoticeState.secondary = secondary
    hud.hudNoticeState.untilTick = nowTick + ticks
end

function hud.getObjectHudName(objectHandle)
    if not objectHandle then
        return nil
    end

    local object = getObject(objectHandle)
    if not object or not object.tagHandle or object.tagHandle:isNull() then
        return nil
    end

    local tagEntry = engine.tag.getTagEntry(object.tagHandle.value)
    if not tagEntry or not tagEntry.path then
        return nil
    end

    local leafName = tagEntry.path:match("([^\\]+)$") or tagEntry.path
    leafName = leafName:gsub("_", " "):upper()
    return leafName
end

function hud.updateMonitorHud(playerIndex, player, isMonitor, attachedObjectHandle, aimedObjectHandle)
    local localPlayer = engine.player.getPlayer()
    if not localPlayer then
        if playerIndex ~= 0 then
            return
        end
    elseif player and player.handle and localPlayer.handle and player.handle.value and
        localPlayer.handle.value then
        if player.handle.value ~= localPlayer.handle.value then
            return
        end
    elseif player and player.unitHandle and localPlayer.unitHandle and player.unitHandle.value and
        localPlayer.unitHandle.value then
        if player.unitHandle.value ~= localPlayer.unitHandle.value then
            return
        end
    elseif playerIndex ~= 0 then
        return
    end

    local rightPrimary
    local rightSecondary
    local centerPrimary
    local centerSecondary

    local nowTick = engine.game.getTickCount() or 0
    local hasNotice = hud.hudNoticeState.primary and nowTick <= (hud.hudNoticeState.untilTick or 0)

    if isMonitor then
        if attachedObjectHandle then
            rightPrimary = "FLASHLIGHT KEY - OBJECT PROPERTIES"
            rightSecondary = "JUMP KEY - DELETE OBJECT"
            local objectName = hud.getObjectHudName(attachedObjectHandle)
            if objectName then
                centerPrimary = objectName
            end
        else
            rightPrimary = "FLASHLIGHT KEY - OBJECTS MENU"
            rightSecondary = "CROUCH KEY - SPARTAN MODE"
            if aimedObjectHandle then
                local objectName = hud.getObjectHudName(aimedObjectHandle)
                if objectName then
                    centerPrimary = objectName
                else
                    centerPrimary = "UNKNOWN OBJECT"
                end
                --centerSecondary = "PRESS FIRE KEY TO PICK UP OBJECT"
            end
        end
    end

    if hasNotice then
        centerPrimary = hud.hudNoticeState.primary
        centerSecondary = hud.hudNoticeState.secondary
    elseif hud.hudNoticeState.primary and not hasNotice then
        hud.hudNoticeState.primary = nil
        hud.hudNoticeState.secondary = nil
        hud.hudNoticeState.untilTick = 0
    end

    setRightHud(formatHudLines(rightPrimary, rightSecondary), 24, 82, {
        color = hud.hudTextColor,
        layer = "hud",
        style = "plain",
        justification = "right",
        anchor = "bottomRight",
        shadow = true,
        font = hud.constants.fontTag.handle
    })

    setCenterHud(formatHudLines(centerPrimary, centerSecondary), 0, 94, {
        color = hud.hudTextColor,
        layer = "hud",
        style = "plain",
        justification = "center",
        anchor = "center",
        shadow = true,
        font = hud.constants.fontTag.handle
    })

    if not isMonitor and not hasNotice then
        hud.clearMonitorHud()
    end
end

function hud.init(fontTag)
    hud.constants.fontTag = fontTag
    assert(hud.constants.fontTag, "Font tag not found")
end

return hud

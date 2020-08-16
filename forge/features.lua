------------------------------------------------------------------------------
-- Forge Features
-- Author: Sledmine
-- Version: 1.0
-- Forging features
------------------------------------------------------------------------------
local constants = require "forge.constants"

local features = {}

-- Internal functions for rotation calculation
local function rotate(x, y, alpha)
    local cosAlpha = math.cos(math.rad(alpha))
    local sinAlpha = math.sin(math.rad(alpha))
    local t1 = x[1] * sinAlpha
    local t2 = x[2] * sinAlpha
    local t3 = x[3] * sinAlpha
    x[1] = x[1] * cosAlpha + y[1] * sinAlpha
    x[2] = x[2] * cosAlpha + y[2] * sinAlpha
    x[3] = x[3] * cosAlpha + y[3] * sinAlpha
    y[1] = y[1] * cosAlpha - t1
    y[2] = y[2] * cosAlpha - t2
    y[3] = y[3] * cosAlpha - t3
end

-- Internal functions for rotation calculation
function features.convertDegrees(yaw, pitch, roll)
    local F = {1, 0, 0}
    local L = {0, 1, 0}
    local T = {0, 0, 1}
    rotate(F, L, yaw)
    rotate(F, T, pitch)
    rotate(T, L, roll)
    return {F[1], -L[1], -T[1], -F[3], L[3], T[3]}
end

--- Changes default crosshair values
---@param state number
function features.setCrosshairState(state)
    local forgeCrosshairAddress = get_tag("weapon_hud_interface",
                                          constants.weaponHudInterfaces.forgeCrosshair)
    if (state == 0) then
        blam.weaponHudInterface(forgeCrosshairAddress, {
            defaultRed = 64,
            defaultGreen = 169,
            defaultBlue = 255,
            sequenceIndex = 1,
        })
    elseif (state == 1) then
        blam.weaponHudInterface(forgeCrosshairAddress, {
            defaultRed = 0,
            defaultGreen = 255,
            defaultBlue = 0,
            sequenceIndex = 2,
        })
    elseif (state == 2) then
        blam.weaponHudInterface(forgeCrosshairAddress, {
            defaultRed = 0,
            defaultGreen = 255,
            defaultBlue = 0,
            sequenceIndex = 3,
        })
    elseif (state == 3) then
        blam.weaponHudInterface(forgeCrosshairAddress, {
            defaultRed = 255,
            defaultGreen = 0,
            defaultBlue = 0,
            sequenceIndex = 4,
        })
    else
        blam.weaponHudInterface(forgeCrosshairAddress, {
            defaultRed = 64,
            defaultGreen = 169,
            defaultBlue = 255,
            sequenceIndex = 0,
        })
    end
end

function features.unhighlightAll()
    local forgeObjects = eventsStore:getState().forgeObjects
    for objectId, composedObject in pairs(forgeObjects) do
        local tempObject = blam.object(get_object(objectId))
        -- Object exists
        if (tempObject) then
            local tagType = get_tag_type(tempObject.tagId)
            if (tagType == "scen") then
                blam.object(get_object(objectId), {
                    health = 0,
                })
            end
        end
    end
end

---@param objectId number
---@param transparency number | "0.1" | "0.5" | "1"
function features.highlightObject(objectId, transparency)
    -- Highlight object
    blam.object(get_object(objectId), {
        health = transparency,
    })
end

-- Mod functions
function features.swapBiped()
    features.unhighlightAll()
    if (server_type == "local") then
        -- Avoid annoying low health/shield bug after swaping bipeds
        blam.biped(get_dynamic_player(), {
            health = 100,
            shield = 100,
        })

        -- Needs kinda refactoring, probably splitting this into LuaBlam
        local globalsTagAddress = get_tag("matg", "globals\\globals")
        local globalsTagData = read_dword(globalsTagAddress + 0x14)
        local globalsTagMultiplayerBipedTagIdAddress = globalsTagData + 0x9BC + 0xC
        local currentGlobalsBipedTagId = read_dword(globalsTagMultiplayerBipedTagIdAddress)
        for i = 0, 2043 do
            local tempObject = blam.object(get_object(i))
            if (tempObject and tempObject.tagId == get_tag_id("bipd", constants.bipeds.spartan)) then
                write_dword(globalsTagMultiplayerBipedTagIdAddress,
                            get_tag_id("bipd", constants.bipeds.monitor))
                delete_object(i)
            elseif (tempObject and tempObject.tagId == get_tag_id("bipd", constants.bipeds.monitor)) then
                write_dword(globalsTagMultiplayerBipedTagIdAddress,
                            get_tag_id("bipd", constants.bipeds.spartan))
                delete_object(i)
            end
        end
    else
        dprint("Requesting monitor biped...")
        execute_script("rcon forge #b")
    end
end

--- Forces the game to open a widget given tag path
---@param tagPath string
---@return boolean result susccess
function features.openMenu(tagPath, prevent)
    local newMenuTagId = get_tag_id("DeLa", tagPath)
    if (newMenuTagId) then
        blam.uiWidgetDefinition(get_tag("DeLa",
                                        constants.uiWidgetDefinitions.errorNonmodalFullscreen),
                                {
            tagReference = newMenuTagId,
        })
        if (not prevent) then
            execute_script("multiplayer_map_name lua-blam-rocks")
            execute_script("multiplayer_map_name " .. map)
        end
        return true
    end
    return false
end

--- Print formatted text into HUD message output
---@param message string
---@param optional string
function features.printHUD(message, optional)
    local cleanLimit = 3
    if (optional) then
        cleanLimit = 2
    end
    for i = 1, cleanLimit do
        hud_message("")
    end
    hud_message(message)
    if (optional) then
        hud_message(optional)
    end
end

return features

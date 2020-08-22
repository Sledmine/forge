------------------------------------------------------------------------------
-- Forge Features
-- Author: Sledmine
-- Version: 1.0
-- Forging features
------------------------------------------------------------------------------
local constants = require "forge.constants"

local features = {}

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
        local player = blam.biped(get_dynamic_player())
        if (player) then
            playerStore:dispatch({
                type = "SAVE_POSITION"
            })
        end

        -- Avoid annoying low health/shield bug after swaping bipeds
        blam.biped(get_dynamic_player(), {
            health = 1,
            shield = 1,
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
        execute_script("cls")
    end
    console_out(message)
    if (optional) then
        console_out(optional)
    end
end

return features

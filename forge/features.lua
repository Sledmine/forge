------------------------------------------------------------------------------
-- Forge Features
-- Sledmine
-- Set of different forge features
------------------------------------------------------------------------------
local glue = require "glue"
local color = require "color"

local core = require "forge.core"

local features = {}

--- Changes default crosshair values
---@param state number
function features.setCrosshairState(state)
    local forgeDefaultInterface = blam.weaponHudInterface(constants.weaponHudInterfaces.forgeCrosshair)
    local forgeWeaponInterface = blam.weaponHudInterface(constants.weaponHudInterfaces.forgeWeaponCrosshair)
    if (forgeWeaponInterface) then
        local newCrosshairs = forgeWeaponInterface.crosshairs
        if (state == 0) then
            newCrosshairs[1].overlays[1].sequenceIndex = 1
            --[[blam35.weaponHudInterface(forgeCrosshairAddress, {
                defaultRed = 64,
                defaultGreen = 169,
                defaultBlue = 255,
                sequenceIndex = 1
            })]]
        elseif (state == 1) then
            newCrosshairs[1].overlays[1].sequenceIndex = 2
            --[[blam35.weaponHudInterface(forgeCrosshairAddress, {
                defaultRed = 0,
                defaultGreen = 255,
                defaultBlue = 0,
                sequenceIndex = 2
            })]]
        elseif (state == 2) then
            newCrosshairs[1].overlays[1].sequenceIndex = 3
            --[[blam35.weaponHudInterface(forgeCrosshairAddress, {
                defaultRed = 0,
                defaultGreen = 255,
                defaultBlue = 0,
                sequenceIndex = 3
            })]]
        elseif (state == 3) then
            newCrosshairs[1].overlays[1].sequenceIndex = 4
            --[[blam35.weaponHudInterface(forgeCrosshairAddress, {
                defaultRed = 255,
                defaultGreen = 0,
                defaultBlue = 0,
                sequenceIndex = 4
            })]]
        else
            newCrosshairs[1].overlays[1].sequenceIndex = 0
            --[[blam35.weaponHudInterface(forgeCrosshairAddress, {
                defaultRed = 64,
                defaultGreen = 169,
                defaultBlue = 255,
                sequenceIndex = 0
            })]]
        end
        forgeWeaponInterface.crosshairs = newCrosshairs
        forgeDefaultInterface.crosshairs = newCrosshairs
    end
end

function features.unhighlightAll(exceptionId)
    local forgeObjects = eventsStore:getState().forgeObjects
    for objectIndex, composedObject in pairs(forgeObjects) do
        if (objectIndex ~= exceptionId) then
            local tempObject = blam.object(get_object(objectIndex))
            -- Object exists
            if (tempObject) then
                local tempTag = blam.getTag(tempObject.tagId)
                if (tempTag and tempTag.class == tagClasses.scenery) then
                    local tempObject = blam.object(get_object(objectIndex))
                    tempObject.health = 0
                end
            end
        end
    end
end

---@param objectId number
---@param transparency number | "0.1" | "0.5" | "1"
function features.highlightObject(objectId, transparency)
    -- Highlight object
    local tempObject = blam.object(get_object(objectId))
    tempObject.health = transparency
end

--- Execute a player swap between biped and monitor
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
        player.health = 1
        player.shield = 1

        -- Needs kinda refactoring, probably splitting this into LuaBlam
        local globalsTagAddress = get_tag(tagClasses.globals, "globals\\globals")
        local globalsTagData = read_dword(globalsTagAddress + 0x14)
        local globalsTagMultiplayerBipedTagIdAddress = globalsTagData + 0x9BC + 0xC
        for objectNumber, objectIndex in pairs(blam.getObjects()) do
            local tempObject = blam.object(get_object(objectIndex))
            if (tempObject) then
                local spartanTag = blam.getTag(constants.bipeds.spartan, tagClasses.biped)
                local monitorTag = blam.getTag(constants.bipeds.monitor, tagClasses.biped)
                if (tempObject.tagId == spartanTag.id) then
                    write_dword(globalsTagMultiplayerBipedTagIdAddress, monitorTag.id)
                    delete_object(objectIndex)
                elseif (tempObject.tagId == monitorTag.id) then
                    write_dword(globalsTagMultiplayerBipedTagIdAddress, spartanTag.id)
                    delete_object(objectIndex)
                end
            end
        end
    else
        dprint("Requesting monitor biped...")
        -- // TODO Replace this with a send request function
        execute_script("rcon forge #b")
    end
end

--- Forces the game to open a widget given tag path
---@param tagPath string
---@return boolean result susccess
function features.openMenu(tagPath, prevent)
    local uiWidgetTagId = blam.getTag(tagPath, tagClasses.uiWidgetDefinition).id
    if (uiWidgetTagId) then
        load_ui_widget(tagPath)
        return true
    end
    return false
end

--- Print formatted text into HUD message output
---@param message string
---@param optional string
function features.printHUD(message, optional, forcedTickCount)
    textRefreshCount = forcedTickCount or 0
    local color = {1, 0.890, 0.949, 0.992}
    if (optional) then
        drawTextBuffer = {
            message:upper() .. "\r" .. optional:upper(),
            0,
            290,
            640,
            480,
            constants.hudFontTagId,
            "center",
            table.unpack(color)
        }
    else
        drawTextBuffer = {
            message:upper(),
            0,
            285,
            640,
            480,
            constants.hudFontTagId,
            "center",
            table.unpack(color)
        }
    end
end

function features.animateForgeLoading()
    local bitmapPath = constants.bitmaps.mapLoading0
    if (loadingFrame == 0) then
        bitmapPath = constants.bitmaps.mapLoading1
    else
        bitmapPath = constants.bitmaps.mapLoading0
    end

    -- Animate Forge loading image
    local uiWidget = blam.uiWidgetDefinition(constants.uiWidgetDefinitions.loadingAnimation)
    local bitmapTag = blam.getTag(bitmapPath, tagClasses.bitmap)
    uiWidget.backgroundBitmap = bitmapTag.id
    return true
end

--- Get information from the mouse input in the game
---@return mouseInput
function features.getMouseInput()
    ---@class mouseInput
    local mouseInput = {
        scroll = tonumber(read_char(constants.mouseInputAddress + 8))
    }
    return mouseInput
end

function features.setObjectColor(hexColor, object)
    local r, g, b = color.hex(hexColor)
    object.redA = r
    object.greenA = g
    object.blueA = b
end

function features.getObjectMenuFunctions()
    local playerState = playerStore:getState()
    local elementFunctions = {
        ["rotate 5"] = function()
            local newRotationStep = 5
            playerStore:dispatch({
                type = "SET_ROTATION_STEP",
                payload = {step = newRotationStep}
            })
            playerStore:dispatch({
                type = "STEP_ROTATION_DEGREE"
            })
            playerStore:dispatch({
                type = "ROTATE_OBJECT"
            })
        end,
        ["rotate 45"] = function()
            local newRotationStep = 45
            playerStore:dispatch({
                type = "SET_ROTATION_STEP",
                payload = {step = newRotationStep}
            })
            playerStore:dispatch({
                type = "STEP_ROTATION_DEGREE"
            })
            playerStore:dispatch({
                type = "ROTATE_OBJECT"
            })
        end,
        ["rotate 90"] = function()
            local newRotationStep = 90
            playerStore:dispatch({
                type = "SET_ROTATION_STEP",
                payload = {step = newRotationStep}
            })
            playerStore:dispatch({
                type = "STEP_ROTATION_DEGREE"
            })
            playerStore:dispatch({
                type = "ROTATE_OBJECT"
            })
        end,
        ["reset rotation"] = function()
            playerStore:dispatch({
                type = "RESET_ROTATION"
            })
            playerStore:dispatch({
                type = "ROTATE_OBJECT"
            })
        end,
        ["snap mode"] = function()
            configuration.forge.snapMode = not configuration.forge.snapMode
        end,
        ["white"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#FFFFFF", tempObject)
        end,
        ["black"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#000000", tempObject)
        end,
        ["red"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#FE0000", tempObject)
        end,
        ["blue"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#0201E3", tempObject)
        end,
        ["gray"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#707E71", tempObject)
        end,
        ["yellow"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#FFFF01", tempObject)
        end,
        ["green"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#00FF01", tempObject)
        end,
        ["pink"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#FF56B9", tempObject)
        end,
        ["purple"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#AB10F4", tempObject)
        end,
        ["cyan"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#01FFFF", tempObject)
        end,
        ["cobalt"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#6493ED", tempObject)
        end,
        ["orange"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#FF7F00", tempObject)
        end,
        ["teal"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#1ECC91", tempObject)
        end,
        ["sage"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#006401", tempObject)
        end,
        ["brown"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#603814", tempObject)
        end,
        ["tan"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#C69C6C", tempObject)
        end,
        ["maroon"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#9D0B0E", tempObject)
        end,
        ["salmon"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor("#F5999E", tempObject)
        end
    }
    return elementFunctions
end

return features

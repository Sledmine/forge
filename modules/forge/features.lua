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
    local forgeDefaultInterface = blam.weaponHudInterface(
                                      constants.weaponHudInterfaces.forgeCrosshairTagId)
    if (forgeDefaultInterface) then
        local newCrosshairs = forgeDefaultInterface.crosshairs
        if (state and state < 5) then
            if (newCrosshairs[1].overlays[1].sequenceIndex ~= state) then
                if (state == 4) then
                    newCrosshairs[1].overlays[1].defaultColorR = 255
                    newCrosshairs[1].overlays[1].defaultColorG = 0
                    newCrosshairs[1].overlays[1].defaultColorB = 0
                elseif (state == 2 or state == 3) then
                    newCrosshairs[1].overlays[1].defaultColorR = 0
                    newCrosshairs[1].overlays[1].defaultColorG = 255
                    newCrosshairs[1].overlays[1].defaultColorB = 0
                else
                    newCrosshairs[1].overlays[1].defaultColorR = 64
                    newCrosshairs[1].overlays[1].defaultColorG = 169
                    newCrosshairs[1].overlays[1].defaultColorB = 255
                end
                newCrosshairs[1].overlays[1].sequenceIndex = state
                forgeDefaultInterface.crosshairs = newCrosshairs
            end
        end
    end
end

function features.unhighlightAll()
    local forgeObjects = eventsStore:getState().forgeObjects
    for objectIndex, forgeObject in pairs(forgeObjects) do
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
            playerStore:dispatch({type = "SAVE_POSITION"})
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
                if (tempObject.tagId == constants.bipeds.spartanTagId) then
                    write_dword(globalsTagMultiplayerBipedTagIdAddress,
                                constants.bipeds.monitorTagId)
                    delete_object(objectIndex)
                elseif (tempObject.tagId == constants.bipeds.monitorTagId) then
                    write_dword(globalsTagMultiplayerBipedTagIdAddress,
                                constants.bipeds.spartanTagId)
                    delete_object(objectIndex)
                end
            end
        end
        -- else
        -- dprint("Requesting monitor biped...")
        -- // TODO Replace this with a send request function
        -- execute_script("rcon forge #b")
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
    local bitmapFrameTagId = constants.bitmaps.forgingIconFrame0TagId
    if (loadingFrame == 0) then
        bitmapFrameTagId = constants.bitmaps.forgeIconFrame1TagId
        loadingFrame = 1
    else
        bitmapFrameTagId = constants.bitmaps.forgingIconFrame0TagId
        loadingFrame = 0
    end

    -- Animate Forge loading image
    local uiWidget = blam.uiWidgetDefinition(constants.uiWidgetDefinitions
                                                 .loadingAnimation.id)
    uiWidget.backgroundBitmap = bitmapFrameTagId
    return true
end

--- Get information from the mouse input in the game
---@return mouseInput
function features.getMouseInput()
    ---@class mouseInput
    local mouseInput = {scroll = tonumber(read_char(constants.mouseInputAddress + 8))}
    return mouseInput
end

-- // TODO Refactor this to execute all the needed steps in just one function
function features.setObjectColor(hexColor, blamObject)
    if (blamObject) then
        local r, g, b = color.hex(hexColor)
        blamObject.redA = r
        blamObject.greenA = g
        blamObject.blueA = b
    end
end

function features.openForgeObjectPropertiesMenu()
    ---@type forgeState
    local forgeState = forgeStore:getState()
    forgeState.forgeMenu.currentPage = 1
    forgeState.forgeMenu.desiredElement = "root"
    forgeState.forgeMenu.elementsList =
        {
            root = {
                ["colors (beta)"] = {
                    ["white (default)"] = {},
                    black = {},
                    red = {},
                    blue = {},
                    gray = {},
                    yellow = {},
                    green = {},
                    pink = {},
                    purple = {},
                    cyan = {},
                    cobalt = {},
                    orange = {},
                    teal = {},
                    sage = {},
                    brown = {},
                    tan = {},
                    maroon = {},
                    salmon = {}
                },
                ["channel"] = {
                    alpha = {},
                    bravo = {},
                    charly = {},
                },
                ["reset rotation"] = {},
                ["rotate 45"] = {},
                ["rotate 90"] = {},
                ["snap mode"] = {}
            }
        }
    forgeStore:dispatch({
        type = "UPDATE_FORGE_ELEMENTS_LIST",
        payload = {forgeMenu = forgeState.forgeMenu}
    })
    features.openMenu(constants.uiWidgetDefinitions.forgeMenu.path)
end

function features.getObjectMenuFunctions()
    local playerState = playerStore:getState()
    local elementFunctions = {
        ["rotate 45"] = function()
            local newRotationStep = 45
            playerStore:dispatch({
                type = "SET_ROTATION_STEP",
                payload = {step = newRotationStep}
            })
            playerStore:dispatch({type = "STEP_ROTATION_DEGREE"})
            playerStore:dispatch({type = "ROTATE_OBJECT"})
        end,
        ["rotate 90"] = function()
            local newRotationStep = 90
            playerStore:dispatch({
                type = "SET_ROTATION_STEP",
                payload = {step = newRotationStep}
            })
            playerStore:dispatch({type = "STEP_ROTATION_DEGREE"})
            playerStore:dispatch({type = "ROTATE_OBJECT"})
        end,
        ["reset rotation"] = function()
            playerStore:dispatch({type = "RESET_ROTATION"})
            playerStore:dispatch({type = "ROTATE_OBJECT"})
        end,
        ["snap mode"] = function()
            configuration.forge.snapMode = not configuration.forge.snapMode
        end,
        ["alpha"] = function()
            playerStore:dispatch({type = "SET_OBJECT_CHANNEL", payload = {channel = constants.teleportersChannels.alpha}})
        end,
        ["bravo"] = function()
            playerStore:dispatch({type = "SET_OBJECT_CHANNEL", payload = {channel = constants.teleportersChannels.bravo}})
        end,
        ["charly"] = function()
            playerStore:dispatch({type = "SET_OBJECT_CHANNEL", payload = {channel = constants.teleportersChannels.charly}})
        end,
        ["white (default)"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.white, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.white
            })
        end,
        ["black"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.black, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.black
            })
        end,
        ["red"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.red, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.red
            })
        end,
        ["blue"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.blue, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.blue
            })
        end,
        ["gray"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.gray, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.gray
            })
        end,
        ["yellow"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.yellow, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.yellow
            })
        end,
        ["green"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.green, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.green
            })
        end,
        ["pink"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.pink, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.pink
            })
        end,
        ["purple"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.purple, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.purple
            })
        end,
        ["cyan"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.cyan, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.cyan
            })
        end,
        ["cobalt"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.cobalt, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.cobalt
            })
        end,
        ["orange"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.orange, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.orange
            })
        end,
        ["teal"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.teal, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.teal
            })
        end,
        ["sage"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.sage, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.sage
            })
        end,
        ["brown"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.brown, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.brown
            })
        end,
        ["tan"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.tan, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.tan
            })
        end,
        ["maroon"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.maroon, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.maroon
            })
        end,
        ["salmon"] = function()
            local tempObject = blam.object(get_object(playerState.attachedObjectId))
            features.setObjectColor(constants.colors.salmon, tempObject)
            playerStore:dispatch({
                type = "SET_OBJECT_COLOR",
                payload = constants.colors.salmon
            })
        end
    }
    return elementFunctions
end

-- TODO Migrate this to a separate module, like glue
local function stringHas(str, list)
    for k, v in pairs(list) do
        if (str:find(v)) then
            return true
        end
    end
    return false
end

--- Hide or unhide forge reflection objects for gameplay purposes
---@param hide boolean
function features.hideReflectionObjects(hide)
    if (not configuration.forge.debugMode) then
        ---@type eventsState
        local eventsStore = eventsStore:getState()
        for objectIndex, forgeObject in pairs(eventsStore.forgeObjects) do
            if (forgeObject and forgeObject.reflectionId) then
                local tempObject = blam.object(get_object(objectIndex))
                if (tempObject) then
                    local tempTag = blam.getTag(tempObject.tagId)
                    if (not stringHas(tempTag.path, constants.hideObjectsExceptions)) then
                        if (hide) then
                            -- Hide objects by setting null permutation
                            tempObject.z = constants.minimumZSpawnPoint * 4
                            tempObject.regionPermutation1 = -1
                            tempObject.regionPermutation2 = -1
                        else
                            tempObject.z = forgeObject.z
                            tempObject.regionPermutation1 = 0
                            tempObject.regionPermutation2 = 0
                        end
                    end
                end
            end
        end
    end
end

return features

------------------------------------------------------------------------------
-- Forge Features
-- Sledmine
-- Set of different forge features
------------------------------------------------------------------------------
local glue = require "glue"
local color = require "color"

local core = require "forge.core"

local features = {
    state = {}
}

--- Changes default crosshair values
---@param state number
function features.setCrosshairState(state)
    local forgeDefaultInterface = blam.weaponHudInterface(
                                      const.weaponHudInterfaces.forgeCrosshairTagId)
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

function features.unhighlightObject(objectIndex)
    if (objectIndex) then
        local object = blam.object(get_object(objectIndex))
        -- Object exists
        if (object) then
            -- It is a scenery
            -- FIXME We probably do not need this verification
            local tag = blam.getTag(object.tagId)
            if (tag and tag.class == tagClasses.scenery) then
                object.health = 0
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
---@param desiredBipedTagId number
function features.swapBiped(desiredBipedTagId)
    features.unhighlightAll()
    if (server_type == "local") then
        -- If player is alive save his last position
        local playerBiped = blam.biped(get_dynamic_player())
        if (playerBiped) then
            playerStore:dispatch({type = "SAVE_POSITION"})
        end

        -- Avoid annoying low health/shield bug after swaping bipeds
        playerBiped.health = 1
        playerBiped.shield = 1

        -- Find monitor and alternative spartan biped
        local monitorTagId = const.bipeds.monitorTagId
        local spartanTagId
        for bipedPropertyName, bipedTagId in pairs(const.bipeds) do
            if (not bipedPropertyName:find("monitor")) then
                spartanTagId = bipedTagId
                break
            end
        end
        local globals = blam.globalsTag()
        if (globals) then
            local player = blam.player(get_player())
            local playerObject = blam.object(get_object(player.objectId))
            if (player and playerObject) then
                if (playerObject.tagId == monitorTagId) then
                    local newMultiplayerInformation = globals.multiplayerInformation
                    newMultiplayerInformation[1].unit = spartanTagId
                    -- Update globals tag data to set new biped
                    globals.multiplayerInformation = newMultiplayerInformation
                else
                    local newMultiplayerInformation = globals.multiplayerInformation
                    newMultiplayerInformation[1].unit = monitorTagId
                    -- Update globals tag data to set new biped
                    globals.multiplayerInformation = newMultiplayerInformation
                end
                if (desiredBipedTagId) then
                    local newMultiplayerInformation = globals.multiplayerInformation
                    newMultiplayerInformation[1].unit = desiredBipedTagId
                    -- Update globals tag data to set new biped
                    globals.multiplayerInformation = newMultiplayerInformation
                end
                -- Erase player object to force biped respawn
                delete_object(player.objectId)
            end
        end
    end
end

local defaultFirstPersonHands = nil
function features.swapFirstPerson()
    local player = blam.player(get_player())
    local playerObject = blam.object(get_object(player.objectId))
    local globals = blam.globalsTag()
    if (player and playerObject and globals) then
        local bipedTag = blam.getTag(playerObject.tagId)
        if (bipedTag) then
            local tagPathSplit = glue.string.split(bipedTag.path, "\\")
            local bipedName = tagPathSplit[#tagPathSplit]
            local fpModelTagId = const.firstPersonHands[bipedName]
            if (fpModelTagId) then
                -- Save default first person hands model
                if (not defaultFirstPersonHands) then
                    defaultFirstPersonHands = fpModelTagId
                end
                local newFirstPersonInterface = globals.firstPersonInterface
                newFirstPersonInterface[1].firstPersonHands = fpModelTagId
                globals.firstPersonInterface = newFirstPersonInterface
            elseif (defaultFirstPersonHands) then
                local newFirstPersonInterface = globals.firstPersonInterface
                newFirstPersonInterface[1].firstPersonHands = defaultFirstPersonHands
                globals.firstPersonInterface = newFirstPersonInterface
            end
        end
    end
end

--- Forces the game to open a widget given tag path
---@param tagPath string
---@return boolean result susccess
function features.openMenu(tagPath, prevent)
    local uiWidgetTagId = blam.getTag(tagPath, tagClasses.uiWidgetDefinition).id
    if (uiWidgetTagId) then
        return load_ui_widget(tagPath)
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
            const.hudFontTagId,
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
            const.hudFontTagId,
            "center",
            table.unpack(color)
        }
    end
end

--- Print formatted text into HUD message output
---@param message string
---@param optional string
function features.printHUDRight(message, optional, forcedTickCount)
    textRefreshCount = forcedTickCount or 0
    local color = {1, 0.890, 0.949, 0.992}
    if (optional) then
        drawTextBuffer = {
            message:upper() .. "\r" .. optional:upper(),
            -60,
            380,
            640,
            480,
            const.hudFontTagId,
            "right",
            table.unpack(color)
        }
    end
end

function features.animateForgeLoading()
    local bitmapFrameTagId = const.bitmaps.forgingIconFrame0TagId
    if (loadingFrame == 0) then
        bitmapFrameTagId = const.bitmaps.forgeIconFrame1TagId
        loadingFrame = 1
    else
        bitmapFrameTagId = const.bitmaps.forgingIconFrame0TagId
        loadingFrame = 0
    end

    -- Animate Forge loading image
    local uiWidget = blam.uiWidgetDefinition(const.uiWidgetDefinitions.loadingAnimation.id)
    uiWidget.backgroundBitmap = bitmapFrameTagId
    return true
end

function features.animateDialogLoading()
    local bitmap = blam.bitmap(const.bitmaps.dialogIconsTagId)
    if (bitmap) then
        local newSequences = bitmap.sequences
        if (newSequences[1].firstBitmapIndex < 5) then
            newSequences[1].firstBitmapIndex = newSequences[1].firstBitmapIndex + 1
        else
            newSequences[1].firstBitmapIndex = 0
        end
        bitmap.sequences = newSequences
    else
        error("Error, at animating loading dialog bitmap.")
    end
end

--- Get information from the mouse input in the game
---@return mouseInput
function features.getMouseInput()
    ---@class mouseInput
    local mouseInput = {scroll = tonumber(read_char(const.mouseInputAddress + 8))}
    return mouseInput
end

-- TODO Refactor this to execute all the needed steps in just one function
function features.setObjectColor(hexColor, blamObject)
    if (blamObject) then
        local r, g, b = color.hex(hexColor)
        blamObject.redA = r
        blamObject.greenA = g
        blamObject.blueA = b
    end
end

function features.openForgeObjectPropertiesMenu()
    local forgeState = actions.getForgeState()
    forgeState.forgeMenu.currentPage = 1
    forgeState.forgeMenu.desiredElement = "root"
    forgeState.forgeMenu.elementsList = {
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
            ["channel"] = {},
            ["reset rotation"] = {},
            ["rotate 45"] = {},
            ["rotate 90"] = {},
            ["snap mode"] = {}
        }
    }
    for channelIndex, channelName in pairs(const.teleportersChannels) do
        forgeState.forgeMenu.elementsList.root["channel"][channelName] = {}
    end
    forgeStore:dispatch({
        type = "UPDATE_FORGE_ELEMENTS_LIST",
        payload = {forgeMenu = forgeState.forgeMenu}
    })
    features.openMenu(const.uiWidgetDefinitions.forgeMenu.path)
end

function features.getObjectMenuFunctions()
    local playerState = playerStore:getState()
    local elementFunctions = {
        ["rotate 45"] = function()
            local newRotationStep = 45
            playerStore:dispatch({type = "SET_ROTATION_STEP", payload = {step = newRotationStep}})
            playerStore:dispatch({type = "STEP_ROTATION_DEGREE"})
            playerStore:dispatch({type = "ROTATE_OBJECT"})
        end,
        ["rotate 90"] = function()
            local newRotationStep = 90
            playerStore:dispatch({type = "SET_ROTATION_STEP", payload = {step = newRotationStep}})
            playerStore:dispatch({type = "STEP_ROTATION_DEGREE"})
            playerStore:dispatch({type = "ROTATE_OBJECT"})
        end,
        ["reset rotation"] = function()
            playerStore:dispatch({type = "RESET_ROTATION"})
            playerStore:dispatch({type = "ROTATE_OBJECT"})
        end,
        ["snap mode"] = function()
            config.forge.snapMode = not config.forge.snapMode
        end
    }
    for colorName, colorValue in pairs(const.colors) do
        -- Hardcode button white label
        if (colorName == "white") then
            colorName = "white (default)"
        end
        elementFunctions[colorName] = function()
            actions.setObjectColor(colorValue)
        end
    end
    for channelIndex, channelName in pairs(const.teleportersChannels) do
        elementFunctions[channelName] = function()
            actions.setObjectChannel(channelIndex)
        end
    end
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
function features.hideReflectionObjects()
    if (not config.forge.debugMode) then
        ---@type eventsState
        local eventsStore = eventsStore:getState()
        for objectIndex, forgeObject in pairs(eventsStore.forgeObjects) do
            if (forgeObject and forgeObject.reflectionId) then
                local object = blam.object(get_object(objectIndex))
                if (object) then
                    local tag = blam.getTag(object.tagId)
                    if (not stringHas(tag.path, const.hideObjectsExceptions)) then
                        -- Hide objects by setting different properties
                        if (core.isPlayerMonitor()) then
                            object.isGhost = false
                            object.z = forgeObject.z
                        else
                            object.isGhost = true
                            object.z = const.minimumZSpawnPoint * 4
                        end
                    end
                end
            end
        end
    end
end

--- Attempt to play a sound given tag path and optionally a gain number
function features.playSound(tagPath, gain)
    local player = blam.player(get_player())
    if (player) then
        local playSoundCommand = const.hsc.playSound:format(tagPath, player.index, gain or 1.0)
        execute_script(playSoundCommand)
    end
end

local landedRecently = false
features.state.playerCriticalHealth = false
local lastGrenadeType = nil
--- Apply some special effects to the HUD like sounds, blips, etc
function features.hudUpgrades()
    local player = blam.biped(get_dynamic_player())
    -- Player must exist
    if (player) then
        local isPlayerOnMenu = read_byte(blam.addressList.gameOnMenus) == 0
        if (not isPlayerOnMenu) then
            local localPlayer = read_dword(const.localPlayerAddress)
            local currentGrenadeType = read_word(localPlayer + 202)
            if (not blam.isNull(currentGrenadeType)) then
                if (not lastGrenadeType) then
                    lastGrenadeType = currentGrenadeType
                end
                if (lastGrenadeType ~= currentGrenadeType) then
                    lastGrenadeType = currentGrenadeType
                    if (lastGrenadeType == 1) then
                        features.playSound(const.sounds.uiForwardPath .. "2", 1)
                    else
                        features.playSound(const.sounds.uiForwardPath, 1)
                    end
                end
            end
            -- When player is on critical health show blur effect
            if (player.health <= 0.25 and player.shield <= 0 and blam.isNull(player.vehicleObjectId)) then
                if (not features.state.playerCriticalHealth) then
                    features.state.playerCriticalHealth = true
                    execute_script([[(begin
                        (cinematic_screen_effect_start true)
                        (cinematic_screen_effect_set_convolution 2 1 1 1 5)
                        (cinematic_screen_effect_start false)
                    )]])
                end
            else
                if (features.state.playerCriticalHealth) then
                    execute_script([[(begin
                    (cinematic_screen_effect_set_convolution 2 1 1 0 1)(cinematic_screen_effect_start false)
                    (sleep 45)
                    (cinematic_stop)
                )]])
                end
                features.state.playerCriticalHealth = false
            end
            -- Get hud background bitmap
            local visorBitmap = blam.bitmap(const.bitmaps.unitHudBackgroundTagId)
            if (visorBitmap) then
                -- Player is not in a vehicle
                if (blam.isNull(player.vehicleObjectId)) then
                    -- Unhide hud background bitmap when not in vehicles
                    visorBitmap.type = 0
                else
                    -- Hide hud background bitmap when on vehicles
                    -- Set to interface bitmap type
                    visorBitmap.type = 4
                end
            end
        end
        -- Player is not in a vehicle
        if (blam.isNull(player.vehicleObjectId)) then
            -- Landing hard
            if (player.landing == 1) then
                if (not landedRecently) then
                    landedRecently = true
                    -- Play sound using hsc scripts
                    features.playSound(const.sounds.landHardPlayerDamagePath, 0.8)
                end
            else
                landedRecently = false
            end
        end
    end
end

--- Regenerate players health on low shield using game ticks
---@param playerIndex number
function features.regenerateHealth(playerIndex)
    if (server_type == "sapp" or server_type == "local") then
        local player
        if (playerIndex) then
            player = blam.biped(get_dynamic_player(playerIndex))
        else
            player = blam.biped(get_dynamic_player())
        end
        if (player) then
            -- Fix muted audio shield sync
            if (server_type == "local") then
                if (player.health <= 0) then
                    player.health = 0.000000001
                end
            end
            if (player.health < 1 and player.shield >= 1) then
                local newPlayerHealth = player.health + const.healthRegenerationAmount
                if (newPlayerHealth > 1) then
                    player.health = 1
                else
                    player.health = newPlayerHealth
                end
            end
        end
    end
end

--- Update forge keys text on pause menu
function features.showForgeKeys()
    local controlsStrings = blam.unicodeStringList(const.unicodeStrings.forgeControlsTagId)
    if (controlsStrings) then
        if (core.isPlayerMonitor()) then
            local newStrings = controlsStrings.stringList
            -- E key
            newStrings[1] = "Change rotation angle"
            -- Q key
            newStrings[2] = "Open Forge objects menu"
            -- F key
            newStrings[3] = "Swap Push N Pull mode"
            -- Control key
            newStrings[4] = "Get back into spartan mode"
            controlsStrings.stringList = newStrings
        else
            local newStrings = controlsStrings.stringList
            -- E key
            newStrings[1] = "No Forge action"
            -- Q key
            newStrings[2] = "Get into monitor mode"
            -- F key
            newStrings[3] = "No Forge action"
            -- Control key
            newStrings[4] = "No Forge action"
            controlsStrings.stringList = newStrings
        end
    end
end

--- Prevent players from getting out of map limits
---@param playerIndex number
function features.mapLimit(playerIndex)
    local playerBiped
    if (playerIndex) then
        playerBiped = blam.biped(get_dynamic_player(playerIndex))
    else
        playerBiped = blam.biped(get_dynamic_player())
    end
    if (playerBiped and playerBiped.z < const.minimumZMapLimit) then
        if (server_type == "local") then
            local player = blam.player(get_player())
            delete_object(player.objectId)
        elseif (server_type == "sapp") then
            kill(playerIndex)
        end
    end
end

--- Dynamically modify the general menu to reflect Forge settings
function features.createSettingsMenu(open)
    generalMenuStore:dispatch({
        type = "SET_MENU",
        payload = {
            title = "Forge Settings",
            elements = {
                "Enable debug mode",
                "Constantly save current map",
                "Enable object snap mode",
                "Cast dynamic shadows on objects"
            },
            values = {
                config.forge.objectsCastShadow,
                config.forge.autoSave,
                config.forge.debugMode,
                config.forge.snapMode,
            },
            format = "settings"
        }
    })
    if (open and not features.openMenu(const.uiWidgetDefinitions.generalMenu.path)) then
        dprint("Error, at trying to open general menu!")
    end
end

--- Dynamically modify the general menu to reflect biped selection
function features.createBipedsMenu(open)
    generalMenuStore:dispatch({
        type = "SET_MENU",
        payload = {title = "Bipeds Selection", elements = glue.keys(const.bipedNames), format = "bipeds"}
    })
    if (open and not features.openMenu(const.uiWidgetDefinitions.generalMenu.path)) then
        dprint("Error, at trying to open general menu!")
    end
end

--- Get the widget id of the current ui open in the game
---@return number
function features.getCurrentWidget()
    local widgetIdAddress = read_dword(const.currentWidgetIdAddress)
    if (widgetIdAddress and widgetIdAddress ~= 0) then
        local widgetId = read_dword(widgetIdAddress)
        local tag = blam.getTag(widgetId)
        if (tag) then
            local isPlayerOnMenu = read_byte(blam.addressList.gameOnMenus) == 0
            if (isPlayerOnMenu) then
                --dprint("Current widget: " .. tag.path)
            end
            return tag.id
        end
    end
    return nil
end

function features.overrideDialog(title, message, type)
    local dialogStrings = blam.unicodeStringList(const.unicodeStrings.dialogStringsId)
    local newStrings = dialogStrings.stringList
    newStrings[1] = title
    newStrings[2] = message
    dialogStrings.stringList = newStrings
    -- TODO Refactor this method to allow ids instead of path strings
    features.openMenu(const.uiWidgetDefinitions.warningDialog.path)
end

--[[function core.getPlayerFragGrenade()
    for objectNumber, objectIndex in pairs(blam.getObjects()) do
        local projectile = blam.projectile(get_object(objectIndex))
        local selectedObjIndex
        if (projectile and projectile.type == objectClasses.projectile) then
            local projectileTag = blam.getTag(projectile.tagId)
            if (projectileTag and projectileTag.index ==
                constants.fragGrenadeProjectileTagIndex) then
                local player = blam.biped(get_dynamic_player())
                if (projectile.armingTimer > 1) then
                    player.x = projectile.x
                    player.y = projectile.y
                    player.z = projectile.z
                    delete_object(objectIndex)
                end
            end
        end
    end
end]]

--[[function core.getPlayerAimingSword()
    for objectNumber, objectIndex in pairs(blam.getObjects()) do
        local projectile = blam.projectile(get_object(objectIndex))
        local selectedObjIndex
        if (projectile and projectile.type == objectClasses.projectile) then
            local projectileTag = blam.getTag(projectile.tagId)
            if (projectileTag and projectileTag.index == constants.swordProjectileTagIndex) then
                if (projectile.attachedToObjectId) then
                    local selectedObject = blam.object(
                                               get_object(projectile.attachedToObjectId))
                    if (selectedObject) then
                        dprint(projectile.attachedToObjectId)
                        return projectile, objectIndex
                    end
                end
            end
        end
    end
end]]

--[[
                -- local projectile, projectileIndex = core.getPlayerAimingSword()
            -- Melee magnetisim concept
            for _, objectIndex in pairs(blam.getObjects()) do
                local object = blam.object(get_object(objectIndex))
                if (object and object.type == objectClasses.biped and not object.isHealthEmpty) then
                    local isPlayerOnAim = core.playerIsAimingAt(objectIndex, 0.11, 0.2, 1.4)
                    if (isPlayerOnAim) then
                        if (player.meleeKey) then
                            dprint(player.cameraX .. " " .. player.cameraY .. " " .. player.cameraZ)
                            -- Add velocity to current velocity
                            player.yVel = player.yVel + player.cameraY * 0.13
                            player.xVel = player.xVel + player.cameraX * 0.13
                            player.zVel = player.zVel + player.cameraZ * 0.04

                            -- Replace velocity with camera position
                            -- player.yVel = player.cameraY * 0.15
                            -- player.xVel = player.cameraX * 0.15
                            -- player.zVel = player.cameraZ * 0.06
                        end
                    end
                end
            end
]]

return features

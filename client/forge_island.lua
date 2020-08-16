------------------------------------------------------------------------------
-- Forge Island Client Script
-- Author: Sledmine
-- Version: 4.0
-- Client side script for Forge Island
------------------------------------------------------------------------------
clua_version = 2.042

-- Lua libraries
local redux = require "lua-redux"
local glue = require "glue"
local json = require "json"

-- Halo Custom Edition libraries
blam = require "nlua-blam"
blam = blam.compat35()
local maethrillian = require "maethrillian"
hfs = require "hcefs"

-- Forge modules
local triggers = require "forge.triggers"
local hook = require "forge.hook"
local menu = require "forge.menu"
local features = require "forge.features"
local commands = require "forge.commands"
local constants = require "forge.constants"
local core = require "forge.core"

-- Reducers importation
local playerReducer = require "forge.reducers.playerReducer"
local eventsReducer = require "forge.reducers.eventsReducer"
local forgeReducer = require "forge.reducers.forgeReducer"
local votingReducer = require "forge.reducers.votingReducer"

-- Reflectors importation
local forgeReflector = require "forge.reflectors.forgeReflector"
local votingReflector = require "forge.reflectors.votingReflector"

-- Default debug mode state
debugMode = glue.readfile("forge_debug_mode.dbg", "t")

-- Forge default configuration
-- DO NOT MODIFY ON SCRIPT!! use json config file instead
configuration = {
    snapMode = false,
    objectsCastShadow = false,
}

-- Internal functions
debugBuffer = ""

--- Function to send debug messages to console output
---@param message string
---@param color string | "'category'" | "'warning'" | "'error'" | "'success'"
function dprint(message, color)
    debugBuffer = debugBuffer .. message .. "\n"
    if (debugMode) then
        if (color == "category") then
            console_out(message, 0.31, 0.631, 0.976)
        elseif (color == "warning") then
            console_out(message)
        elseif (color == "error") then
            console_out(message)
        elseif (color == "success") then
            console_out(message, 0.235, 0.82, 0)
        else
            console_out(message)
        end
    end
end

---@return boolean
function validateMapName()
    return map == "forge_island_local" or map == "forge_island" or map == "forge_island_beta"
end

function loadForgeConfiguration()
    local configurationFile = glue.readfile(configurationFolder .. "\\forge_island.json")
    if (configurationFile) then
        configuration = json.decode(configurationFile)
    end
end

function loadForgeMaps()
    local mapsList = {}
    for file in hfs.dir(forgeMapsFolder) do
        if (file ~= "." and file ~= "..") then
            local splitFileName = glue.string.split(file, ".")
            local extFile = splitFileName[#splitFileName]
            -- Only load files with extension .fmap
            if (extFile == "fmap") then
                local mapName = string.gsub(file, ".fmap", "")
                glue.append(mapsList, mapName)
            end
        end
    end
    -- Dispatch state modification!
    local data = {mapsList = mapsList}
    forgeStore:dispatch({
        type = "UPDATE_MAP_LIST",
        payload = data,
    })
end

function onMapLoad()
    -- Like Redux we have some kind of store baby!! the rest is pure magic..
    playerStore = redux.createStore(playerReducer)
    forgeStore = redux.createStore(forgeReducer) -- Isolated store for all the Forge 'app' data
    eventsStore = redux.createStore(eventsReducer) -- Unique store for all the Forge Objects
    votingStore = redux.createStore(votingReducer) -- Storage for all the state of map voting

    local forgeState = forgeStore:getState()

    local tagCollectionAddress = get_tag("tag_collection", constants.scenerysTagCollectionPath)
    local tagCollection = blam.tagCollection(tagCollectionAddress)

    -- TO DO: Refactor this entire loop, has been implemented from the old script!!!
    -- Iterate over all the sceneries available in the sceneries tag collection
    for i = 1, tagCollection.count do
        local sceneryPath = get_tag_path(tagCollection.tagList[i])
        local sceneriesSplit = glue.string.split(sceneryPath, "\\")
        local sceneryFolderIndex
        for j, n in pairs(sceneriesSplit) do
            if (n == "scenery") then
                sceneryFolderIndex = j + 1
            end
        end
        local fixedSplittedPath = {}
        for l = sceneryFolderIndex, #sceneriesSplit do
            fixedSplittedPath[#fixedSplittedPath + 1] = sceneriesSplit[l]
        end
        sceneriesSplit = fixedSplittedPath
        forgeState.forgeMenu.objectsDatabase[sceneriesSplit[#sceneriesSplit]] = sceneryPath
        -- Set first level as the root of available current objects
        -- Make a tree iteration to append sceneries
        local treePosition = forgeState.forgeMenu.objectsList.root
        for k, v in pairs(sceneriesSplit) do
            if (v:sub(1, 1) == "_") then
                v = glue.string.fromhex(tostring((0x2))) .. v:sub(2, -1)
            end
            if (not treePosition[v]) then
                treePosition[v] = {}
            end
            treePosition = treePosition[v]
        end
    end

    local availableForgeObjects = #glue.keys(forgeState.forgeMenu.objectsDatabase)
    dprint("Scenery database has " .. availableForgeObjects .. " objects.")

    -- Subscribed function to refresh forge state into the game!
    forgeStore:subscribe(forgeReflector)

    -- Dispatch forge objects list update
    forgeStore:dispatch({
        type = "UPDATE_FORGE_OBJECTS_LIST",
        payload = {
            forgeMenu = forgeState.forgeMenu,
        },
    })

    local testVoteMaps = {
        {mapName = "Forge", gametype = "Slayer"},
        {mapName = "Forge", gametype = "Slayer"},
        {mapName = "Forge", gametype = "Slayer"},
        {mapName = "Forge", gametype = "Slayer"},
    }

    votingStore:subscribe(votingReflector)

    -- Dispatch forge objects list update
    votingStore:dispatch({
        type = "UPDATE_VOTE_LIST",
        payload = {mapsList = testVoteMaps},
    })

    local isForgeMap = validateMapName()
    if (isForgeMap) then
        -- Forge folders creation
        forgeMapsFolder = hfs.currentdir() .. "\\fmaps"
        local alreadyForgeMapsFolder = not hfs.mkdir(forgeMapsFolder)
        if (not alreadyForgeMapsFolder) then
            dprint("Forge maps folder has been created!")
        end

        configurationFolder = hfs.currentdir() .. "\\config"
        local alreadyConfigurationFolder = not hfs.mkdir(configurationFolder)
        if (not alreadyConfigurationFolder) then
            dprint("Configuratin folder has been created!")
        end

        loadForgeConfiguration()
        loadForgeMaps()

        set_callback("tick", "onTick")
        set_callback("rcon message", "onRcon")
        set_callback("command", "onCommand")
    else
        error("This is not a compatible Forge map!!!")
    end
end

-- Where the magick happens, tiling!
function onTick()
    -- Get player object
    local player = blam.biped(get_dynamic_player())
    local playerState = playerStore:getState()
    if (player) then
        if (core.isPlayerMonitor()) then

            -- Provide better movement to monitors
            if (not player.ignoreCollision) then
                blam.biped(get_dynamic_player(), {
                    ignoreCollision = true,
                })
            end

            -- Calculate player point of view
            playerStore:dispatch({
                type = "UPDATE_OFFSETS",
            })

            -- Check if monitor has an object attached
            local attachedObjectId = playerState.attachedObjectId
            if (attachedObjectId) then
                -- Change rotation angle
                if (player.flashlightKey) then
                    playerStore:dispatch({
                        type = "CHANGE_ROTATION_ANGLE",
                    })
                    features.printHUD("Rotating in " .. playerState.currentAngle)
                elseif (player.actionKeyHold or player.actionKey) then
                    playerStore:dispatch({
                        type = "STEP_ROTATION_DEGREE",
                    })
                    features.printHUD(playerState.currentAngle:upper() .. ": " ..
                                          playerState[playerState.currentAngle])

                    playerStore:dispatch({
                        type = "ROTATE_OBJECT",
                    })
                elseif (player.crouchHold) then
                    playerStore:dispatch({
                        type = "RESET_ROTATION",
                    })
                    playerStore:dispatch({
                        type = "ROTATE_OBJECT",
                    })
                elseif (player.meleeKey) then
                    playerStore:dispatch({
                        type = "SET_LOCK_DISTANCE",
                        payload = {
                            lockDistance = not playerState.lockDistance,
                        },
                    })
                    features.printHUD("Distance from object is " ..
                                          tostring(glue.round(playerState.distance)) .. " units.")
                    if (playerState.lockDistance) then
                        features.printHUD("Push n pull.")
                    else
                        features.printHUD("Closer or further.")
                    end
                end

                if (not playerState.lockDistance) then
                    playerStore:dispatch({
                        type = "UPDATE_DISTANCE",
                    })
                    playerStore:dispatch({
                        type = "UPDATE_OFFSETS",
                    })
                end

                -- Unhighlight objects
                features.unhighlightAll()

                -- Update crosshair
                features.setCrosshairState(2)

                -- This was disabled because now objects can be spawned everywhere!
                --[[if (playerState.zOffset < constants.minimumZSpawnPoint) then
                    -- Set crosshair to not allowed
                    features.setCrosshairState(3)
                end]]

                -- Update object position
                blam.object(get_object(attachedObjectId), {
                    x = playerState.xOffset,
                    y = playerState.yOffset,
                    z = playerState.zOffset,
                })
                if (player.jumpHold) then
                    playerStore:dispatch({
                        type = "DESTROY_OBJECT",
                    })
                elseif (player.weaponSTH) then
                    playerStore:dispatch({
                        type = "DETACH_OBJECT",
                    })
                end
            else
                -- Open Forge menu by pressing 'Q'
                if (player.flashlightKey) then
                    dprint("Opening Forge menu...")
                    features.openMenu(constants.uiWidgetDefinitions.forgeMenu)
                elseif (player.crouchHold) then
                    features.swapBiped()
                    playerStore:dispatch({
                        type = "DETACH_OBJECT",
                    })
                end

                -- Set crosshair to not selected state
                features.setCrosshairState(0)

                -- Unhighlight objects
                features.unhighlightAll()

                local forgeObjects = eventsStore:getState().forgeObjects

                -- Get if player is looking at some object
                for objectId, composedObject in pairs(forgeObjects) do
                    -- Object exists
                    if (composedObject) then
                        local tagType = get_tag_type(composedObject.object.tagId)
                        if (tagType == tagClasses.scenery) then
                            local isPlayerLookingAt = core.playerIsLookingAt(objectId, 0.047, 0)
                            if (isPlayerLookingAt) then

                                -- Get and parse object name
                                local objectPath =
                                    glue.string.split(get_tag_path(composedObject.object.tagId),
                                                      "\\")
                                local objectName = objectPath[#objectPath - 1]
                                local objectCategory = objectPath[#objectPath - 2]

                                if (objectCategory:sub(1, 1) == "_") then
                                    objectCategory = objectCategory:sub(2, -1)
                                end

                                objectName = objectName:gsub("^%l", string.upper)
                                objectCategory = objectCategory:gsub("^%l", string.upper)

                                features.printHUD("NAME:  " .. objectName,
                                                  "CATEGORY:  " .. objectCategory)

                                -- Update crosshair state
                                if (features.setCrosshairState) then
                                    features.setCrosshairState(1)
                                end

                                -- Hightlight the object that the player is looking at
                                if (features.highlightObject) then
                                    features.highlightObject(objectId, 1)
                                end

                                -- Player is taking the object
                                if (player.weaponPTH) then
                                    -- Set lock distance to true, to take object from perspective
                                    playerStore:dispatch(
                                        {
                                            type = "ATTACH_OBJECT",
                                            payload = {
                                                objectId = objectId,
                                                fromPerspective = true,
                                            },
                                        })
                                elseif (player.actionKey) then
                                    playerStore:dispatch(
                                        {
                                            type = "SET_ROTATION_DEGREES",
                                            payload = {
                                                yaw = composedObject.yaw,
                                                pitch = composedObject.pitch,
                                                roll = composedObject.roll,
                                            },
                                        })
                                    local tagId = composedObject.object.tagId
                                    playerStore:dispatch(
                                        {
                                            type = "CREATE_AND_ATTACH_OBJECT",
                                            payload = {
                                                path = get_tag_path(tagId),
                                            },
                                        })
                                end

                                -- Stop searching for other objects
                                break
                            end
                        end
                    end
                end
            end
        else
            -- Convert into monitor
            if (player.flashlightKey) then
                features.swapBiped()
            elseif (player.actionKey and player.crouchHold and server_type == "local") then
                core.cspawn_object(tagClasses.biped, constants.bipeds.spartan, player.x, player.y,
                                   player.z)
            end
        end
    end

    -- Menu buttons interpcetion

    -- Trigger prefix and how many triggers are being read
    local mapsMenuPressedButton = triggers.get("maps_menu", 10)
    if (mapsMenuPressedButton) then
        if (mapsMenuPressedButton == 9) then
            -- Dispatch an event to increment current page
            forgeStore:dispatch({
                type = "DECREMENT_MAPS_MENU_PAGE",
            })
        elseif (mapsMenuPressedButton == 10) then
            -- Dispatch an event to decrement current page
            forgeStore:dispatch({
                type = "INCREMENT_MAPS_MENU_PAGE",
            })
        else
            local mapName = blam.unicodeStringList(
                                get_tag("unicode_string_list", constants.unicodeStrings.mapsList))
                                .stringList[mapsMenuPressedButton]
            core.loadForgeMap(mapName)
        end
        dprint("Maps menu:")
        dprint("Button " .. mapsMenuPressedButton .. " was pressed!", "category")
    end

    -- Trigger prefix and how many triggers are being read
    local forgeMenuPressedButton = triggers.get("forge_menu", 9)
    if (forgeMenuPressedButton) then
        local forgeState = forgeStore:getState()
        if (forgeMenuPressedButton == 9) then
            if (forgeState.forgeMenu.desiredElement ~= "root") then
                if (playerState.attachedObjectId) then
                    playerStore:dispatch({
                        type = "DESTROY_OBJECT",
                    })
                else
                    forgeStore:dispatch({
                        type = "UPWARD_NAV_FORGE_MENU",
                    })
                end
            else
                dprint("Closing Forge menu...")
                menu.close(constants.uiWidgetDefinitions.forgeMenu)
            end
        elseif (forgeMenuPressedButton == 8) then
            forgeStore:dispatch({
                type = "INCREMENT_FORGE_MENU_PAGE",
            })
        elseif (forgeMenuPressedButton == 7) then
            forgeStore:dispatch({
                type = "DECREMENT_FORGE_MENU_PAGE",
            })
        else
            local desiredElement = blam.unicodeStringList(
                                       get_tag(tagClasses.unicodeStringList,
                                               constants.unicodeStrings.forgeList)).stringList[forgeMenuPressedButton]
            local sceneryPath = forgeState.forgeMenu.objectsDatabase[desiredElement]
            if (sceneryPath) then
                dprint(" -> [ Forge Menu ]")
                playerStore:dispatch({
                    type = "CREATE_AND_ATTACH_OBJECT",
                    payload = {path = sceneryPath},
                })
            else
                forgeStore:dispatch({
                    type = "DOWNWARD_NAV_FORGE_MENU",
                    payload = {
                        desiredElement = desiredElement,
                    },
                })
            end
        end
        dprint(" -> [ Forge Menu ]")
        dprint("Button " .. forgeMenuPressedButton .. " was pressed!", "category")
    end

    -- Trigger prefix and how many triggers are being read
    local voteMapMenuPressedButton = triggers.get("map_vote_menu", 5)
    if (voteMapMenuPressedButton) then
        execute_script("rcon forge #v," .. voteMapMenuPressedButton)
        dprint("Vote Map menu:")
        dprint("Button " .. voteMapMenuPressedButton .. " was pressed!", "category")
    end

    -- Attach respective hooks for menus!
    hook.attach("maps_menu", menu.stop, constants.uiWidgetDefinitions.mapsList)
    hook.attach("forge_menu", menu.stop, constants.uiWidgetDefinitions.forgeList)
    hook.attach("forge_menu_close", menu.stop, constants.uiWidgetDefinitions.forgeMenu)
    hook.attach("loading_menu_close", menu.stop, constants.uiWidgetDefinitions.loadingMenu)

end

-- This is not a mistake... right?
function forgeAnimation()
    if (not lastImage) then
        lastImage = 0
    else
        if (lastImage == 0) then
            lastImage = 1
        else
            lastImage = 0
        end
    end

    -- Animate forge logo
    blam.uiWidgetDefinition(get_tag("ui_widget_definition",
                                    constants.uiWidgetDefinitions.loadingAnimation), {
        backgroundBitmap = get_tag_id("bitm", constants.bitmaps["forgeLoadingProgress" ..
                                          tostring(lastImage)]),
    })
    return true
end

function onRcon(message)
    local request = string.gsub(message, "'", "")
    local splitData = glue.string.split(request, ",")
    local requestType = constants.requestTypes[splitData[1]]
    if (requestType) then
        dprint("Decoding incoming " .. requestType .. " ...", "warning")

        local requestObject = maethrillian.convertRequestToObject(request,
                                                                  constants.requestFormats[requestType])

        if (requestObject) then
            dprint("Done.", "success")
        else
            dprint("Error at converting request.", "error")
            return false, nil
        end

        dprint("Decompressing ...", "warning")
        local compressionFormat = constants.compressionFormats[requestType]
        requestObject = maethrillian.decompressObject(requestObject, compressionFormat)

        if (requestObject) then
            dprint("Done.", "success")
        else
            dprint("Error at decompressing request.", "error")
            return false, nil
        end

        if (not ftestingMode) then
            eventsStore:dispatch({
                type = requestType,
                payload = {
                    requestObject = requestObject,
                },
            })
        end
        return false, requestObject
    end
    return true
end

-- Allows the script to run by just reloading it
if (server_type == "local") then
    onMapLoad()
end

function onCommand(command)
    return commands(command)
end

function onUnload()
    -- Flush all the forge objects
    core.flushForge()

    -- Save configuration
    glue.writefile(configurationFolder .. "\\forge_island.json", json.encode(configuration))
end

-- Prepare event callbacks
set_callback("map load", "onMapLoad")
set_callback("unload", "onUnload")

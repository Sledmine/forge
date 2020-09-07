------------------------------------------------------------------------------
-- Forge Island Client Script
-- Sledmine
-- Version 1.0
-- Client side script for Forge Island
------------------------------------------------------------------------------
clua_version = 2.042

-- Lua libraries
local inspect = require "inspect"
local redux = require "lua-redux"
local glue = require "glue"
local json = require "json"

-- Halo Custom Edition libraries
blam = require "nlua-blam"
-- Bind legacy console out to better lua-blam printing function
console_out = blam.consoleOutput
-- Create global reference to tagClasses
objectClasses = blam.objectClasses
tagClasses = blam.tagClasses
-- Bring old api compatibility
blam35 = blam.compat35()
hfs = require "hcefs"

-- Forge modules
local triggers = require "forge.triggers"
local hook = require "forge.hook"
local menu = require "forge.menu"
local features = require "forge.features"
local commands = require "forge.commands"
local core = require "forge.core"

-- Reducers importation
local playerReducer = require "forge.reducers.playerReducer"
local eventsReducer = require "forge.reducers.eventsReducer"
local forgeReducer = require "forge.reducers.forgeReducer"
local votingReducer = require "forge.reducers.votingReducer"

-- Reflectors importation
local forgeReflector = require "forge.reflectors.forgeReflector"
local votingReflector = require "forge.reflectors.votingReflector"

-- Forge default configuration
-- DO NOT MODIFY ON SCRIPT!! use json config file instead
configuration = {
    debugMode = false,
    autoSave = false,
    autoSaveTime = 15000,
    snapMode = false,
    objectsCastShadow = false
}

-- Internal functions
debugBuffer = ""
textRefreshCount = 0

--- Function to send debug messages to console output
---@param message string
---@param color string | "'category'" | "'warning'" | "'error'" | "'success'"
function dprint(message, color)
    if (type(message) == "table") then
        return console_out(inspect(message))
    end
    debugBuffer = debugBuffer .. message .. "\n"
    if (debugMode) then
        if (color == "category") then
            console_out(message, 0.31, 0.631, 0.976)
        elseif (color == "warning") then
            console_out(message, blam.consoleColors.warning)
        elseif (color == "error") then
            console_out(message, blam.consoleColors.error)
        elseif (color == "success") then
            console_out(message, blam.consoleColors.success)
        else
            console_out(message)
        end
    end
end

---@return boolean
function validateMapName()
    return map == "forge_island_dev" or map == "forge_island" or map == "forge_island_beta"
end

function loadForgeConfiguration()
    local configurationFolder = hfs.currentdir() .. "\\config"
    local configurationFile = glue.readfile(configurationFolder .. "\\forge_island.json")
    if (configurationFile) then
        configuration = json.decode(configurationFile)
    end
end

loadForgeConfiguration()

debugMode = configuration.debugMode

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
        payload = data
    })
end

function autoSaveForgeMap()
    if (configuration.autoSave and core.isPlayerMonitor()) then
        ---@type forgeState
        local forgeState = forgeStore:getState()
        local currentMapName = forgeState.currentMap.name
        if (currentMapName and currentMapName ~= "Unsaved") then
            core.saveForgeMap()
        end
    end
end

function OnMapLoad()
    -- Dinamically load constansts for the current forge map
    constants = require "forge.constants"
    constants.scenarioPath = "[shm]\\halo_4\\maps\\forge_island\\forge_island"
    constants.scenerysTagCollectionPath = "[shm]\\halo_4\\maps\\forge_island\\forge_island_scenerys"

    -- Like Redux we have some kind of store baby!! the rest is pure magic..
    playerStore = redux.createStore(playerReducer)
    forgeStore = redux.createStore(forgeReducer) -- Isolated store for all the Forge 'app' data
    eventsStore = redux.createStore(eventsReducer) -- Unique store for all the Forge Objects
    votingStore = redux.createStore(votingReducer) -- Storage for all the state of map voting

    local forgeState = forgeStore:getState()

    local tagCollectionAddress = get_tag(tagClasses.tagCollection,
                                         constants.scenerysTagCollectionPath)
    local tagCollection = blam35.tagCollection(tagCollectionAddress)

    -- // TODO: Refactor this entire loop, has been implemented from the old script!!!
    -- Iterate over all the sceneries available in the sceneries tag collection
    for i = 1, tagCollection.count do
        local sceneryPath = get_tag_path(tagCollection.tagList[i])

        local sceneriesSplit = glue.string.split(sceneryPath, "\\")
        local sceneryFolderIndex
        for folderNameIndex, folderName in pairs(sceneriesSplit) do
            if (folderName == "scenery") then
                sceneryFolderIndex = folderNameIndex + 1
            end
        end
        local fixedSplittedPath = {}
        for l = sceneryFolderIndex, #sceneriesSplit do
            fixedSplittedPath[#fixedSplittedPath + 1] = sceneriesSplit[l]
        end
        sceneriesSplit = fixedSplittedPath
        local sceneriesSplitLast = sceneriesSplit[#sceneriesSplit]

        forgeState.forgeMenu.objectsDatabase[sceneriesSplitLast] = sceneryPath
        -- Set first level as the root of available current objects
        -- Make a tree iteration to append sceneries
        local treePosition = forgeState.forgeMenu.objectsList.root
        for currentLevel, categoryLevel in pairs(sceneriesSplit) do
            if (categoryLevel:sub(1, 1) == "_") then
                categoryLevel = glue.string.fromhex(tostring((0x2))) .. categoryLevel:sub(2, -1)
            end
            if (not treePosition[categoryLevel]) then
                treePosition[categoryLevel] = {}
            end
            treePosition = treePosition[categoryLevel]
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
            forgeMenu = forgeState.forgeMenu
        }
    })

    votingStore:subscribe(votingReflector)

    -- Dispatch forge objects list update
    votingStore:dispatch({
        type = "FLUSH_MAP_VOTES"
    })
    --[[votingStore:dispatch({
        type = "APPEND_MAP_VOTE",
        payload = {
            map = {
                name = "Forge",
                gametype = "Slayer"
            }
        }
    })]]

    local isForgeMap = validateMapName()
    if (isForgeMap) then
        -- Forge folders creation
        forgeMapsFolder = hfs.currentdir() .. "\\fmaps"
        local alreadyForgeMapsFolder = not hfs.mkdir(forgeMapsFolder)
        if (not alreadyForgeMapsFolder) then
            console_out("Forge maps folder has been created!")
        end

        configurationFolder = hfs.currentdir() .. "\\config"
        local alreadyConfigurationFolder = not hfs.mkdir(configurationFolder)
        if (not alreadyConfigurationFolder) then
            console_out("Configuratin folder has been created!")
        end

        -- Load all the forge stuff
        loadForgeConfiguration()
        loadForgeMaps()

        -- Start autosave timer
        if (not autoSaveTimer and server_type == "local") then
            autoSaveTimer = set_timer(configuration.autoSaveTime, "autoSaveForgeMap")
        end

        set_callback("tick", "OnTick")
        set_callback("preframe", "OnPreFrame")
        set_callback("rcon message", "OnRcon")
        set_callback("command", "onCommand")

    else
        error("This is not a compatible Forge map!!!")
    end
end

function OnPreFrame()
    local gameOnMenus = read_byte(blam.addressList.gameOnMenus) == 0
    if (drawTextBuffer and not gameOnMenus) then
        draw_text(table.unpack(drawTextBuffer))
    end
end

-- Where the magick happens, tiling!
function OnTick()
    -- Get player object
    ---@type biped
    local player = blam.biped(get_dynamic_player())

    -- Get player forge state
    ---@type playerState
    local playerState = playerStore:getState()
    if (player) then
        local oldPosition = playerState.position
        if (oldPosition) then
            blam35.biped(get_dynamic_player(), {
                x = oldPosition.x,
                y = oldPosition.y,
                z = oldPosition.z + 0.1
            })
            playerStore:dispatch({
                type = "RESET_POSITION"
            })
        end
        if (core.isPlayerMonitor()) then
            -- Provide better movement to monitors
            if (not player.ignoreCollision) then
                blam35.biped(get_dynamic_player(), {
                    ignoreCollision = true
                })
            end

            -- Calculate player point of view
            playerStore:dispatch({
                type = "UPDATE_OFFSETS"
            })

            -- Check if monitor has an object attached
            local attachedObjectId = playerState.attachedObjectId
            if (attachedObjectId) then
                -- Change rotation angle
                if (player.flashlightKey) then
                    playerStore:dispatch({
                        type = "CHANGE_ROTATION_ANGLE"
                    })
                    features.printHUD("Rotating in " .. playerState.currentAngle)
                elseif (player.actionKeyHold or player.actionKey) then
                    playerStore:dispatch({
                        type = "STEP_ROTATION_DEGREE"
                    })
                    features.printHUD(playerState.currentAngle:upper() .. ": " ..
                                          playerState[playerState.currentAngle])

                    playerStore:dispatch({
                        type = "ROTATE_OBJECT"
                    })
                elseif (player.crouchHold) then
                    playerStore:dispatch({
                        type = "RESET_ROTATION"
                    })
                    playerStore:dispatch({
                        type = "ROTATE_OBJECT"
                    })
                elseif (player.weaponPTH and player.jumpHold) then
                    local forgeObjects = eventsStore:getState().forgeObjects
                    local forgeObject = forgeObjects[attachedObjectId]
                    if (forgeObject) then
                        -- Update object position
                        blam35.object(get_object(attachedObjectId), {
                            x = forgeObject.x,
                            y = forgeObject.y,
                            z = forgeObject.z
                        })
                        core.rotateObject(attachedObjectId, forgeObject.yaw, forgeObject.pitch,
                                          forgeObject.roll)
                        playerStore:dispatch({
                            type = "DETACH_OBJECT",
                            payload = {
                                undo = true
                            }
                        })
                        return true
                    end
                elseif (player.meleeKey) then
                    playerStore:dispatch({
                        type = "SET_LOCK_DISTANCE",
                        payload = {
                            lockDistance = not playerState.lockDistance
                        }
                    })
                    features.printHUD("Distance from object is " ..
                                          tostring(glue.round(playerState.distance)) .. " units.")
                    if (playerState.lockDistance) then
                        features.printHUD("Push n pull.")
                    else
                        features.printHUD("Closer or further.")
                    end
                elseif (player.jumpHold) then
                    playerStore:dispatch({
                        type = "DESTROY_OBJECT"
                    })
                elseif (player.weaponSTH) then
                    playerStore:dispatch({
                        type = "DETACH_OBJECT"
                    })
                end

                
                if (not playerState.lockDistance) then
                    playerStore:dispatch({
                        type = "UPDATE_DISTANCE"
                    })
                    playerStore:dispatch({
                        type = "UPDATE_OFFSETS"
                    })
                end
                
                -- Update object position
                blam35.object(get_object(attachedObjectId), {
                    x = playerState.xOffset,
                    y = playerState.yOffset,
                    z = playerState.zOffset
                })
                
                -- Unhighlight objects
                features.unhighlightAll()

                -- Update crosshair
                features.setCrosshairState(2)

                -- This was disabled because now objects can be spawned everywhere!
                -- if (playerState.zOffset < constants.minimumZSpawnPoint) then
                -- Set crosshair to not allowed
                --    features.setCrosshairState(3)
                -- end

            else

                -- Set crosshair to not selected state
                features.setCrosshairState(0)

                -- Unhighlight objects
                features.unhighlightAll()

                local forgeObjects = eventsStore:getState().forgeObjects

                -- Get if player is looking at some object
                for objectId, composedObject in pairs(forgeObjects) do
                    -- Object exists
                    if (composedObject) then
                        local tempObject = blam35.object(get_object(objectId))
                        local tagType = get_tag_type(tempObject.tagId)
                        if (tagType == tagClasses.scenery) then
                            local isPlayerLookingAt = core.playerIsLookingAt(objectId, 0.047, 0)
                            if (isPlayerLookingAt) then

                                -- Get and parse object name
                                local objectPath =
                                    glue.string.split(get_tag_path(tempObject.tagId), "\\")
                                local objectName = objectPath[#objectPath - 1]
                                local objectCategory = objectPath[#objectPath - 2]

                                if (objectCategory:sub(1, 1) == "_") then
                                    objectCategory = objectCategory:sub(2, -1)
                                end

                                objectName = objectName:gsub("^%l", string.upper)
                                objectCategory = objectCategory:gsub("^%l", string.upper)

                                features.printHUD("NAME:  " .. objectName,
                                                  "CATEGORY:  " .. objectCategory, 25)

                                -- Update crosshair state
                                if (features.setCrosshairState) then
                                    features.setCrosshairState(1)
                                end

                                -- Hightlight the object that the player is looking at
                                if (features.highlightObject) then
                                    features.highlightObject(objectId, 1)
                                end

                                -- Player is taking the object
                                if (player.weaponPTH and not player.jumpHold) then
                                    -- Set lock distance to true, to take object from perspective
                                    playerStore:dispatch(
                                        {
                                            type = "ATTACH_OBJECT",
                                            payload = {
                                                objectId = objectId,
                                                fromPerspective = true
                                            }
                                        })
                                elseif (player.actionKey) then
                                    playerStore:dispatch(
                                        {
                                            type = "SET_ROTATION_DEGREES",
                                            payload = {
                                                yaw = composedObject.yaw,
                                                pitch = composedObject.pitch,
                                                roll = composedObject.roll
                                            }
                                        })
                                    local tagId = blam35.object(get_object(objectId)).tagId
                                    playerStore:dispatch(
                                        {
                                            type = "CREATE_AND_ATTACH_OBJECT",
                                            payload = {
                                                path = get_tag_path(tagId)
                                            }
                                        })
                                end
                                -- Stop searching for other objects
                                break
                            end
                        end
                    end
                end
                -- Open Forge menu by pressing 'Q'
                if (player.flashlightKey) then
                    dprint("Opening Forge menu...")
                    features.openMenu(constants.uiWidgetDefinitions.forgeMenu)
                elseif (player.crouchHold) then
                    features.swapBiped()
                    playerStore:dispatch({
                        type = "DETACH_OBJECT"
                    })
                end
            end
        else
            -- Convert into monitor
            if (player.flashlightKey) then
                features.swapBiped()
            elseif (player.actionKey and player.crouchHold and server_type == "local") then
                core.spawnObject(tagClasses.biped, constants.bipeds.spartan, player.x, player.y,
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
                type = "DECREMENT_MAPS_MENU_PAGE"
            })
        elseif (mapsMenuPressedButton == 10) then
            -- Dispatch an event to decrement current page
            forgeStore:dispatch({
                type = "INCREMENT_MAPS_MENU_PAGE"
            })
        else
            local mapName = blam35.unicodeStringList(
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
                        type = "DESTROY_OBJECT"
                    })
                else
                    forgeStore:dispatch({
                        type = "UPWARD_NAV_FORGE_MENU"
                    })
                end
            else
                dprint("Closing Forge menu...")
                menu.close(constants.uiWidgetDefinitions.forgeMenu)
            end
        elseif (forgeMenuPressedButton == 8) then
            forgeStore:dispatch({
                type = "INCREMENT_FORGE_MENU_PAGE"
            })
        elseif (forgeMenuPressedButton == 7) then
            forgeStore:dispatch({
                type = "DECREMENT_FORGE_MENU_PAGE"
            })
        else
            local desiredElement = blam35.unicodeStringList(
                                       get_tag(tagClasses.unicodeStringList,
                                               constants.unicodeStrings.forgeList)).stringList[forgeMenuPressedButton]
            local sceneryPath = forgeState.forgeMenu.objectsDatabase[desiredElement]
            if (sceneryPath) then
                dprint(" -> [ Forge Menu ]")
                playerStore:dispatch({
                    type = "CREATE_AND_ATTACH_OBJECT",
                    payload = {path = sceneryPath}
                })
            else
                forgeStore:dispatch({
                    type = "DOWNWARD_NAV_FORGE_MENU",
                    payload = {
                        desiredElement = desiredElement
                    }
                })
            end
        end
        dprint(" -> [ Forge Menu ]")
        dprint("Button " .. forgeMenuPressedButton .. " was pressed!", "category")
    end

    -- Trigger prefix and how many triggers are being read
    local voteMapMenuPressedButton = triggers.get("map_vote_menu", 5)
    if (voteMapMenuPressedButton) then
        local voteMapRequest = {
            requestType = constants.requests.sendMapVote.requestType,
            mapVoted = voteMapMenuPressedButton
        }
        core.sendRequest(core.createRequest(voteMapRequest))
        dprint("Vote Map menu:")
        dprint("Button " .. voteMapMenuPressedButton .. " was pressed!", "category")
    end

    -- Attach respective hooks for menus
    hook.attach("maps_menu", menu.stop, constants.uiWidgetDefinitions.mapsList)
    hook.attach("forge_menu", menu.stop, constants.uiWidgetDefinitions.objectsList)
    hook.attach("forge_menu_close", menu.stop, constants.uiWidgetDefinitions.forgeMenu)
    hook.attach("loading_menu_close", menu.stop, constants.uiWidgetDefinitions.loadingMenu)

    textRefreshCount = textRefreshCount + 1
    -- We need to draw new text this time
    if (textRefreshCount > 30) then
        textRefreshCount = 0
        drawTextBuffer = nil
    end
end

-- This is not a mistake... right?
function forgeAnimation()
    -- // TODO: Update this logic, it is awful!
    if (not lastImage) then
        lastImage = 0
    else
        if (lastImage == 0) then
            lastImage = 1
        else
            lastImage = 0
        end
    end
    -- // TODO: Split this in a better way, it looks horrible!
    -- Animate forge logo
    blam35.uiWidgetDefinition(get_tag("ui_widget_definition",
                                      constants.uiWidgetDefinitions.loadingAnimation), {
        backgroundBitmap = get_tag_id("bitm", constants.bitmaps["forgeLoadingProgress" ..
                                          tostring(lastImage)])
    })
    return true
end

function OnRcon(message)
    local request = string.gsub(message, "'", "")
    local splitData = glue.string.split(request, "|")
    local incomingRequest = splitData[1]
    local actionType
    local currentRequest
    for requestName, request in pairs(constants.requests) do
        if (incomingRequest and incomingRequest == request.requestType) then
            currentRequest = request
            actionType = request.actionType
        end
    end
    if (actionType) then
        return core.processRequest(actionType, request, currentRequest)
    end
    return true
end

function onCommand(command)
    return commands(command)
end

function OnMapUnload()
    -- Flush all the forge objects
    core.flushForge()

    -- Save configuration
    glue.writefile(configurationFolder .. "\\forge_island.json", json.encode(configuration))
end

-- Prepare event callbacks
set_callback("map load", "OnMapLoad")
set_callback("unload", "OnMapUnload")

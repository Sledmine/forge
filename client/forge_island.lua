------------------------------------------------------------------------------
-- Forge Island Client Script
-- Sledmine
-- Version 1.0
-- Client side script for Forge Island
------------------------------------------------------------------------------
-- Constants
clua_version = 2.042
-- Script name must be the base script name, without variants or extensions
scriptName = script_name:gsub(".lua", ""):gsub("_dev", ""):gsub("_beta", "")
defaultConfigurationPath = "config"
defaultMapsPath = "fmaps"

-- Lua libraries
local inspect = require "inspect"
local redux = require "lua-redux"
local glue = require "glue"
local ini = require "lua-ini"

-- Halo Custom Edition libraries
blam = require "nlua-blam"
-- Bind legacy Chimera printing to lua-blam printing
console_out = blam.consoleOutput
-- Create global reference to tagClasses
objectClasses = blam.objectClasses
tagClasses = blam.tagClasses
cameraTypes = blam.cameraTypes
-- Bring old api compatibility
blam35 = blam.compat35()

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
configuration = {}

configuration.forge = {
    debugMode = false,
    autoSave = false,
    autoSaveTime = 15000,
    snapMode = false,
    objectsCastShadow = false
}

-- Load forge configuration at script load time
core.loadForgeConfiguration()

-- Internal functions and variables
-- Buffer to store all the debug printing
debugBuffer = ""
-- Tick counter until next text draw refresh
textRefreshCount = 0
-- Object used to store mouse input across pre frame update
mouse = {}

--- Function to send debug messages to console output
---@param message string
---@param color string | "'category'" | "'warning'" | "'error'" | "'success'"
function dprint(message, color)
    if (type(message) == "table") then
        return console_out(inspect(message))
    end
    debugBuffer = debugBuffer .. message .. "\n"
    if (configuration.forge.debugMode) then
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

--- Function to automatically save a current Forge map
function autoSaveForgeMap()
    if (configuration.forge.autoSave and core.isPlayerMonitor()) then
        ---@type forgeState
        local forgeState = forgeStore:getState()
        local currentMapName = forgeState.currentMap.name
        if (currentMapName and currentMapName ~= "Unsaved") then
            core.saveForgeMap()
        end
    end
end

function OnMapLoad()
    -- Dinamically load constants for the current Forge map
    constants = require "forge.constants"
    constants.scenarioPath = "[shm]\\halo_4\\maps\\forge_island\\forge_island"
    constants.scenerysTagCollectionPath = "[shm]\\halo_4\\maps\\forge_island\\forge_island_scenerys"

    -- Like Redux we have some kind of store baby!! the rest is pure magic..
    playerStore = redux.createStore(playerReducer)
    forgeStore = redux.createStore(forgeReducer) -- Isolated store for all the Forge 'app' data
    eventsStore = redux.createStore(eventsReducer) -- Unique store for all the Forge Objects
    votingStore = redux.createStore(votingReducer) -- Storage for all the state of map voting

    local forgeState = forgeStore:getState()

    local tagCollection = blam.tagCollection(constants.scenerysTagCollectionPath)

    -- // TODO Refactor this entire loop, has been implemented from the old script!!!
    -- Iterate over all the sceneries available in the sceneries tag collection
    for i = 1, tagCollection.count do
        local sceneryPath = get_tag_path(tagCollection.tagList[i])

        local sceneriesSplit = glue.string.split(sceneryPath, "\\")
        local sceneryFolderIndex
        for folderNameIndex, folderName in pairs(sceneriesSplit) do
            if (folderName == "scenery") then
                sceneryFolderIndex = folderNameIndex + 1
                break
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
            -- // TODO This is horrible, remove this "sort" implementation
            if (categoryLevel:sub(1, 1) == "_") then
                categoryLevel = glue.string.fromhex(tostring((0x2))) .. categoryLevel:sub(2, -1)
            end
            if (not treePosition[categoryLevel]) then
                treePosition[categoryLevel] = {}
            end
            treePosition = treePosition[categoryLevel]
        end
    end

    -- Set current menu elements to objects list
    forgeState.forgeMenu.elementsList = glue.deepcopy(forgeState.forgeMenu.objectsList)

    local availableForgeObjects = #glue.keys(forgeState.forgeMenu.objectsDatabase)
    dprint("Forge database has " .. availableForgeObjects .. " objects.")

    -- Subscribed function to refresh forge state into the game!
    forgeStore:subscribe(forgeReflector)

    -- Dispatch forge objects list update
    forgeStore:dispatch({
        type = "UPDATE_FORGE_ELEMENTS_LIST",
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

    local isForgeMap = core.isForgeMap(map)
    if (isForgeMap) then

        -- //TODO Add folder creation if does not exist

        -- Load all the forge stuff
        core.loadForgeConfiguration()
        core.loadForgeMaps()

        -- Start autosave timer
        if (not autoSaveTimer and server_type == "local") then
            autoSaveTimer = set_timer(configuration.forge.autoSaveTime, "autoSaveForgeMap")
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
    playerIsOnMenu = read_byte(blam.addressList.gameOnMenus) == 0
    if (drawTextBuffer and not playerIsOnMenu) then
        draw_text(table.unpack(drawTextBuffer))
    end
    if (playerIsOnMenu) then
        -- Get player forge state
        ---@type playerState
        local playerState = playerStore:getState()
        -- Menu, UI Handling
        -- Trigger prefix and how many triggers are being read
        -- triggers.get("hsc_trigger_example_name", 10)
        menuPressedButton = triggers.get("maps_menu", 10)
        mouse = features.getMouseInput()
        if mouse.scroll ~= 0 then
            dprint(inspect(mouse))
        end
        if (mouse.scroll > 0) then
            menuPressedButton = 10
        elseif (mouse.scroll < 0) then
            menuPressedButton = 9
        end
        if (menuPressedButton) then
            if (menuPressedButton == 9) then
                -- Dispatch an event to increment current page
                forgeStore:dispatch({
                    type = "DECREMENT_MAPS_MENU_PAGE"
                })
            elseif (menuPressedButton == 10) then
                -- Dispatch an event to decrement current page
                forgeStore:dispatch({
                    type = "INCREMENT_MAPS_MENU_PAGE"
                })
            else
                local elementsList = blam.unicodeStringList(constants.unicodeStrings.mapsList)
                local mapName = elementsList.stringList[menuPressedButton]:gsub(" ", "_")
                core.loadForgeMap(mapName)
            end
            dprint("Maps menu:")
            dprint("Button " .. menuPressedButton .. " was pressed!", "category")
        end

        menuPressedButton = triggers.get("forge_menu", 9)
        mouse = features.getMouseInput()
        if mouse.scroll ~= 0 then
            dprint(inspect(mouse))
        end
        if (mouse.scroll > 0) then
            menuPressedButton = 8
        elseif (mouse.scroll < 0) then
            menuPressedButton = 7
        end
        if (menuPressedButton) then
            dprint(" -> [ Forge Menu ]")
            local forgeState = forgeStore:getState()
            if (menuPressedButton == 9) then
                if (forgeState.forgeMenu.desiredElement ~= "root") then
                    forgeStore:dispatch({
                        type = "UPWARD_NAV_FORGE_MENU"
                    })
                else
                    dprint("Closing Forge menu...")
                    menu.close(constants.uiWidgetDefinitions.forgeMenu)
                end
            elseif (menuPressedButton == 8) then
                forgeStore:dispatch({
                    type = "INCREMENT_FORGE_MENU_PAGE"
                })
            elseif (menuPressedButton == 7) then
                forgeStore:dispatch({
                    type = "DECREMENT_FORGE_MENU_PAGE"
                })
            else
                if (playerState.attachedObjectId) then
                    local elementsList = blam.unicodeStringList(constants.unicodeStrings.forgeList)
                    local selectedElement = elementsList.stringList[menuPressedButton]
                    local elementsFunctions = {
                        ["rotate 5"] = function()
                            local newRotationStep = 5
                            playerStore:dispatch({
                                type = "SET_ROTATION_STEP",
                                payload = {
                                    step = newRotationStep
                                }
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
                                payload = {
                                    step = newRotationStep
                                }
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
                                payload = {
                                    step = newRotationStep
                                }
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
                        ["blue"] = function()
                            local tempObject = blam.object(get_object(playerState.attachedObjectId))
                            tempObject.redA = 0
                            tempObject.greenA = 0
                            tempObject.blueA = 1
                        end,
                        ["green"] = function()
                            local tempObject = blam.object(get_object(playerState.attachedObjectId))
                            tempObject.redA = 0
                            tempObject.greenA = 1
                            tempObject.blueA = 0
                        end,
                        ["red"] = function()
                            local tempObject = blam.object(get_object(playerState.attachedObjectId))
                            tempObject.redA = 1
                            tempObject.greenA = 0
                            tempObject.blueA = 0
                        end
                    }
                    if (selectedElement) then
                        local buttonFunction = elementsFunctions[selectedElement]
                        if (buttonFunction) then
                            buttonFunction()
                        else
                            forgeStore:dispatch({
                                type = "DOWNWARD_NAV_FORGE_MENU",
                                payload = {
                                    desiredElement = selectedElement
                                }
                            })
                        end
                    end
                else
                    local elementsList = blam.unicodeStringList(constants.unicodeStrings.forgeList)
                    local selectedSceneryName = elementsList.stringList[menuPressedButton]
                    local sceneryPath = forgeState.forgeMenu.objectsDatabase[selectedSceneryName]
                    if (sceneryPath) then
                        playerStore:dispatch({
                            type = "CREATE_AND_ATTACH_OBJECT",
                            payload = {
                                path = sceneryPath
                            }
                        })
                        menu.close(constants.uiWidgetDefinitions.forgeMenu)
                    else
                        forgeStore:dispatch({
                            type = "DOWNWARD_NAV_FORGE_MENU",
                            payload = {
                                desiredElement = selectedSceneryName
                            }
                        })
                    end
                end
            end
            dprint(" -> [ Forge Menu ]")
            dprint("Button " .. menuPressedButton .. " was pressed!", "category")

        end

        menuPressedButton = triggers.get("map_vote_menu", 5)
        if (menuPressedButton) then
            local voteMapRequest = {
                requestType = constants.requests.sendMapVote.requestType,
                mapVoted = menuPressedButton
            }
            core.sendRequest(core.createRequest(voteMapRequest))
            dprint("Vote Map menu:")
            dprint("Button " .. menuPressedButton .. " was pressed!", "category")
        end
    else
        -- Get player forge state
        ---@type playerState
        local playerState = playerStore:getState()
        if (playerState.attachedObjectId) then
            mouse = features.getMouseInput()
            if (mouse.scroll > 0) then
                playerStore:dispatch({
                    type = "STEP_ROTATION_DEGREE",
                    payload = {
                        substraction = true,
                        multiplier = mouse.scroll
                    }
                })
                playerStore:dispatch({
                    type = "ROTATE_OBJECT"
                })
                features.printHUD(playerState.currentAngle:upper() .. ": " ..
                                      playerState[playerState.currentAngle])
            elseif (mouse.scroll < 0) then
                playerStore:dispatch({
                    type = "STEP_ROTATION_DEGREE",
                    payload = {
                        substraction = false,
                        multiplier = mouse.scroll
                    }
                })
                playerStore:dispatch({
                    type = "ROTATE_OBJECT"
                })
                features.printHUD(playerState.currentAngle:upper() .. ": " ..
                                      playerState[playerState.currentAngle])
            end
        end
    end
end

-- Where the magick happens, tiling!
function OnTick()

    -- Get player object
    local player = blam.biped(get_dynamic_player())

    -- Get player forge state
    ---@type playerState
    local playerState = playerStore:getState()
    if (player) then
        local oldPosition = playerState.position
        if (oldPosition) then
            player.x = oldPosition.x
            player.y = oldPosition.y
            player.z = oldPosition.z + 0.1
            playerStore:dispatch({
                type = "RESET_POSITION"
            })
        end
        if (core.isPlayerMonitor()) then
            -- Provide better movement to monitors
            if (not player.ignoreCollision) then
                player.ignoreCollision = true
            end

            -- Check if monitor has an object attached
            local playerAttachedObjectId = playerState.attachedObjectId
            if (playerAttachedObjectId) then
                -- Calculate player point of view
                playerStore:dispatch({
                    type = "UPDATE_OFFSETS"
                })
                -- Change rotation angle
                if (player.flashlightKey) then
                    ---@type forgeState
                    local forgeState = forgeStore:getState()
                    forgeState.forgeMenu.currentPage = 1
                    forgeState.forgeMenu.desiredElement = "root"
                    forgeState.forgeMenu.elementsList =
                        {
                            root = {
                                ["colors (beta)"] = {
                                    blue = {},
                                    red = {},
                                    green = {}
                                },
                                ["reset rotation"] = {},
                                ["rotate 5"] = {},
                                ["rotate 45"] = {},
                                ["rotate 90"] = {},
                                ["snap mode"] = {}
                            }
                        }
                    forgeStore:dispatch({
                        type = "UPDATE_FORGE_ELEMENTS_LIST",
                        payload = {
                            forgeMenu = forgeState.forgeMenu
                        }
                    })
                    features.openMenu(constants.uiWidgetDefinitions.forgeMenu)
                elseif (player.actionKey) then
                    playerStore:dispatch({
                        type = "CHANGE_ROTATION_ANGLE"
                    })
                    features.printHUD("Rotating in " .. playerState.currentAngle)
                elseif (player.weaponPTH and player.jumpHold) then
                    local forgeObjects = eventsStore:getState().forgeObjects
                    local forgeObject = forgeObjects[playerAttachedObjectId]
                    if (forgeObject) then
                        -- Update object position
                        local tempObject = blam.object(get_object(playerAttachedObjectId))
                        tempObject.x = forgeObject.x
                        tempObject.y = forgeObject.y
                        tempObject.z = forgeObject.z
                        core.rotateObject(playerAttachedObjectId, forgeObject.yaw,
                                          forgeObject.pitch, forgeObject.roll)
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
                end

                -- Update object position
                local tempObject = blam.object(get_object(playerAttachedObjectId))
                tempObject.x = playerState.xOffset
                tempObject.y = playerState.yOffset
                tempObject.z = playerState.zOffset

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
                for objectNumber, objectIndex in pairs(get_objects()) do
                    local projectile = blam.object(get_object(objectIndex))
                    local composedObject
                    local selectedObjIndex
                    if (projectile and projectile.type == objectClasses.projectile) then
                        local projectileTag = blam.getTag(projectile.tagId)
                        if (projectileTag and projectileTag.index == constants.forgeProjectile) then
                            if (projectile.attachedObjectId) then
                                local selectedObject = blam.object(get_object(projectile.attachedObjectId))
                                selectedObjIndex = core.getIndexById(projectile.attachedObjectId)
                                composedObject = forgeObjects[selectedObjIndex]
                                if (composedObject and selectedObject) then
                                    dprint("attachedObjId: " .. projectile.attachedObjectId)
                                    -- Player is taking the object
                                    if (player.weaponPTH and not player.jumpHold) then
                                        -- Hightlight the object that the player is looking at
                                        if (features.highlightObject) then
                                            features.highlightObject(projectile.attachedObjectId, 1)
                                        end
                                        dprint(projectile.x .. " " .. projectile.y .. " " ..
                                                   projectile.z)
                                        playerStore:dispatch(
                                            {
                                                type = "ATTACH_OBJECT",
                                                payload = {
                                                    objectId = selectedObjIndex,
                                                    attach = {
                                                        x = 0,--projectile.x,
                                                        y = 0,--projectile.y,
                                                        z = 0--projectile.z
                                                    },
                                                    fromPerspective = false
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
                                        local tagId = blam.object(get_object(objectIndex)).tagId
                                        playerStore:dispatch(
                                            {
                                                type = "CREATE_AND_ATTACH_OBJECT",
                                                payload = {
                                                    path = get_tag_path(tagId)
                                                }
                                            })
                                    end
                                end
                            end
                        end
                    end
                end
                --[[for objectId, composedObject in pairs(forgeObjects) do
                    -- Object exists
                    if (composedObject) then
                        local tempObject = blam.object(get_object(objectId))
                        local tagType = get_tag_type(tempObject.tagId)
                        if (tagType == tagClasses.scenery) then
                            local isPlayerLookingAt = core.playerIsLookingAt(objectId, 0.047, 0)
                            if (isPlayerLookingAt) then

                                -- Get and parse object name
                                local objectPath =
                                    glue.string.split(get_tag_path(tempObject.tagId), "\\")
                                local objectName = objectPath[#objectPath - 1]
                                local objectCategory = objectPath[#objectPath - 2]

                                -- // FIXME This is totally not oook!
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
                                    local tagId = blam.object(get_object(objectId)).tagId
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
                end]]
                -- Open Forge menu by pressing "Q"
                if (player.flashlightKey) then
                    dprint("Opening Forge menu...")
                    local forgeState = forgeStore:getState()
                    forgeState.forgeMenu.elementsList =
                        glue.deepcopy(forgeState.forgeMenu.objectsList)
                    forgeStore:dispatch({
                        type = "UPDATE_FORGE_ELEMENTS_LIST",
                        payload = {
                            forgeMenu = forgeState.forgeMenu
                        }
                    })
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
                                 player.z + 3)
            end
        end
    end

    -- Attach respective hooks for menus
    hook.attach("maps_menu", menu.stop, constants.uiWidgetDefinitions.mapsList)
    hook.attach("forge_menu", menu.stop, constants.uiWidgetDefinitions.objectsList)
    hook.attach("forge_menu_close", menu.stop, constants.uiWidgetDefinitions.forgeMenu)
    hook.attach("loading_menu_close", menu.stop, constants.uiWidgetDefinitions.loadingMenu)

    -- Update tick count
    textRefreshCount = textRefreshCount + 1

    -- We need to draw new text, erase the older one
    if (textRefreshCount > 30) then
        textRefreshCount = 0
        drawTextBuffer = nil
    end
end

function OnRcon(message)
    local request = string.gsub(message, "'", "")
    local splitData = glue.string.split(request, constants.requestSeparator)
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
    write_file(defaultConfigurationPath .. "\\forge_island.ini", ini.encode(configuration))
end

-- Prepare event callbacks
set_callback("map load", "OnMapLoad")
set_callback("unload", "OnMapUnload")

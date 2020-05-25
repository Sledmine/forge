------------------------------------------------------------------------------
-- Forge Island Client Script
-- Author: Sledmine
-- Version: 4.0
-- Client side script for Forge Island
------------------------------------------------------------------------------
clua_version = 2.042

-- Lua libraries
inspect = require 'inspect'
json = require 'json'
glue = require 'glue'
redux = require 'lua-redux'

-- Specific Halo Custom Edition libraries
blam = require 'lua-blam'
maethrillian = require 'maethrillian'
hfs = require 'hcefs'

-- Forge modules
triggers = require 'forge.triggers'
hook = require 'forge.hook'
constants = require 'forge.constants'
menu = require 'forge.menu'
features = require 'forge.features'
tests = require 'forge.tests'
core = require 'forge.core'

-- Default debug mode state
debugMode = glue.readfile('forge_debug_mode.dbg', 't')

-- Internal functions
local debugBuffer = ''

--- Function to send debug messages to console output
---@param message string
---@param color string | "'category'" | "'warning'" | "'error'" | "'success'"
function dprint(message, color)
    debugBuffer = debugBuffer .. message .. '\n'
    if (debugMode) then
        if (color == 'category') then
            console_out(message, 0.31, 0.631, 0.976)
        elseif (color == 'warning') then
            console_out(message)
        elseif (color == 'error') then
            console_out(message)
        elseif (color == 'success') then
            console_out(message, 0.235, 0.82, 0)
        else
            console_out(message)
        end
    end
end

-- Forge flusing mapping
-- Needed to map callback to this module function
flushForge = core.flushForge

-- Prepare event callbacks
set_callback('map load', 'onMapLoad')
set_callback('unload', 'flushForge')

---@return boolean
function validateMapName()
    return map == 'forge_island_local' or map == 'forge_island' or map ==
               'forge_island_beta'
end

-- Reducers importation
require 'forge.playerReducer'
require 'forge.eventsReducer'
require 'forge.forgeReducer'

-- Update internal state along the time
function onTick()
    -- Get player object
    local player = blam.biped(get_dynamic_player())
    local playerState = playerStore:getState()
    if (player) then
        player.isMonitor = features.isPlayerMonitor()
        -- dprint(player.x .. ' ' .. player.y .. ' ' .. player.z)
        if (player.isMonitor) then

            -- Provide better movement to monitors
            if (not player.ignoreCollision) then
                blam.biped(get_dynamic_player(), {ignoreCollision = true})
            end

            -- Calculate player point of view
            playerStore:dispatch({
                type = 'UPDATE_OFFSETS',
                payload = {player = player}
            })

            -- Check if monitor has an object attached
            local attachedObjectId = playerState.attachedObjectId
            if (attachedObjectId) then
                -- Change rotation angle
                if (player.flashlightKey) then
                    playerStore:dispatch({type = 'CHANGE_ROTATION_ANGLE'})
                    hud_message('Rotating in: ' .. playerState.currentAngle)
                elseif (player.actionKeyHold or player.actionKey) then
                    -- Convert into spartan
                    playerStore:dispatch({type = 'STEP_ROTATION_DEGREE'})
                    hud_message(playerState.currentAngle .. ': ' ..
                                    playerState[playerState.currentAngle])

                    playerStore:dispatch({type = 'ROTATE_OBJECT'})
                elseif (player.crouchHold) then
                    playerStore:dispatch({type = 'RESET_ROTATION'})
                    playerStore:dispatch({type = 'ROTATE_OBJECT'})
                elseif (player.meleeKey) then
                    playerStore:dispatch(
                        {
                            type = 'SET_LOCK_DISTANCE',
                            payload = {
                                lockDistance = not playerState.lockDistance
                            }
                        })
                    hud_message('Distance from object is ' ..
                                    tostring(glue.round(playerState.distance)) ..
                                    ' units.')
                    if (playerState.lockDistance) then
                        hud_message('Push n pull.')
                    else
                        hud_message('Closer or further.')
                    end
                end

                if (not playerState.lockDistance) then
                    playerStore:dispatch(
                        {type = 'UPDATE_DISTANCE', payload = {player = player}})
                    playerStore:dispatch(
                        {type = 'UPDATE_OFFSETS', payload = {player = player}})
                end

                -- Unhighlight objects
                features.unhighlightAll()

                -- Update crosshair
                features.setCrosshairState(2)

                -- This was disabled because now every object can be spawned everywhere!
                --[[if (playerState.zOffset < constants.minimumZSpawnPoint) then
                    -- Set crosshair to not allowed
                    features.setCrosshairState(3)
                end]]

                -- Update object position
                blam.object(get_object(attachedObjectId), {
                    x = playerState.xOffset,
                    y = playerState.yOffset,
                    z = playerState.zOffset
                    -- TODO: Object color customization!
                    --[[redA = math.random(0,1),
                        greenA = math.random(0,1),
                        blueA = math.random(0,1)]]
                })
                if (player.jumpHold) then
                    playerStore:dispatch({type = 'DESTROY_OBJECT'})
                elseif (player.weaponSTH) then
                    playerStore:dispatch({type = 'DETACH_OBJECT'})
                end
            else
                -- Open Forge menu by pressing 'Q'
                if (player.flashlightKey) then
                    dprint('Opening Forge menu...')
                    features.openMenu(constants.widgetDefinitions.forgeMenu)
                elseif (player.crouchHold) then
                    features.swapBiped()
                    playerStore:dispatch({type = 'DETACH_OBJECT'})
                end

                -- Set crosshair to not selected states
                features.setCrosshairState(0)

                -- Unhighlight objects
                features.unhighlightAll()

                local forgeObjects = eventsStore:getState().forgeObjects

                -- Get if player is looking at some object
                for objectId, composedObject in pairs(forgeObjects) do
                    -- Object exists
                    if (composedObject) then
                        local tagType =
                            get_tag_type(composedObject.object.tagId)
                        if (tagType == 'scen') then
                            local isPlayerLookingAt =
                                features.playerIsLookingAt(objectId, 0.047, 0)
                            if (isPlayerLookingAt) then
                                --dprint(get_tag_path(composedObject.object.tagId))
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
                                    -- Set lock distance to true, this will help to take the object from persepective
                                    playerStore:dispatch(
                                        {
                                            type = 'SET_LOCK_DISTANCE',
                                            payload = {lockDistance = false}
                                        })
                                    playerStore:dispatch(
                                        {
                                            type = 'ATTACH_OBJECT',
                                            payload = {objectId = objectId}
                                        })
                                elseif (player.actionKey) then
                                    playerStore:dispatch(
                                        {
                                            type = 'SET_LOCK_DISTANCE',
                                            payload = {lockDistance = false}
                                        })
                                    playerStore:dispatch(
                                        {
                                            type = 'SET_ROTATION_DEGREES',
                                            payload = {
                                                yaw = composedObject.yaw,
                                                pitch = composedObject.pitch,
                                                roll = composedObject.roll
                                            }
                                        })
                                    local tagId = composedObject.object.tagId
                                    playerStore:dispatch(
                                        {
                                            type = 'CREATE_AND_ATTACH_OBJECT',
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
            end
        else
            -- Convert into monitor
            if (player.flashlightKey) then
                features.swapBiped()
            elseif (player.actionKey and player.crouchHold and server_type ==
                'local') then
                core.cspawn_object(tagClasses.biped,
                                   constants.bipeds.spartan, player.x, player.y,
                                   player.z)
            elseif (player.crouchHold) then
                -- dprint(features.openMenu(constants.widgetDefinitions.loadingMenu))
            end
        end
    end

    -- Trigger prefix and how many triggers are being read
    local mapsMenuPressedButton = triggers.get('maps_menu', 10)
    if (mapsMenuPressedButton) then
        if (mapsMenuPressedButton == 9) then
            -- Dispatch an event to increment current page
            forgeStore:dispatch({type = 'DECREMENT_MAPS_MENU_PAGE'})
        elseif (mapsMenuPressedButton == 10) then
            -- Dispatch an event to decrement current page
            forgeStore:dispatch({type = 'INCREMENT_MAPS_MENU_PAGE'})
        else
            local mapName = blam.unicodeStringList(
                                get_tag('unicode_string_list',
                                        constants.unicodeStrings.mapsList))
                                .stringList[mapsMenuPressedButton]
            dprint(mapName)
            core.loadForgeMap(mapName:gsub('.fmap', ''))
        end
        dprint('Maps menu:')
        dprint('Button ' .. mapsMenuPressedButton .. ' was pressed!', 'category')
    end

    local forgeMenuPressedButton = triggers.get('forge_menu', 9)
    if (forgeMenuPressedButton) then
        local forgeState = forgeStore:getState()
        if (forgeMenuPressedButton == 9) then
            if (forgeState.forgeMenu.desiredElement ~= 'root') then
                forgeStore:dispatch({type = 'UPWARD_NAV_FORGE_MENU'})
            else
                dprint('Closing Forge menu...')
                menu.close(constants.widgetDefinitions.forgeMenu)
            end
        elseif (forgeMenuPressedButton == 8) then
            forgeStore:dispatch({type = 'INCREMENT_FORGE_MENU_PAGE'})
        elseif (forgeMenuPressedButton == 7) then
            forgeStore:dispatch({type = 'DECREMENT_FORGE_MENU_PAGE'})
        else
            local desiredElement = blam.unicodeStringList(
                                       get_tag('unicode_string_list',
                                               constants.unicodeStrings
                                                   .forgeList)).stringList[forgeMenuPressedButton]
            local sceneryPath =
                forgeState.forgeMenu.objectsDatabase[desiredElement]
            if (sceneryPath) then
                dprint(' -> [ Forge Menu ]')
                playerStore:dispatch({
                    type = 'CREATE_AND_ATTACH_OBJECT',
                    payload = {path = sceneryPath}
                })
            else
                forgeStore:dispatch({
                    type = 'DOWNWARD_NAV_FORGE_MENU',
                    payload = {desiredElement = desiredElement}
                })
            end
        end
        dprint(' -> [ Forge Menu ]')
        dprint('Button ' .. forgeMenuPressedButton .. ' was pressed!',
               'category')
    end

    -- Attach respective hooks!
    hook.attach('maps_menu', menu.stopUpdate,
                constants.widgetDefinitions.mapsList)
    hook.attach('forge_menu', menu.stopUpdate,
                constants.widgetDefinitions.forgeList)
    hook.attach('forge_menu_close', menu.stopClose,
                constants.widgetDefinitions.forgeMenu)
    hook.attach('loading_menu_close', menu.stopClose,
                constants.widgetDefinitions.loadingMenu)
end

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
    blam.uiWidgetDefinition(get_tag('ui_widget_definition',
                                    constants.widgetDefinitions.loadingAnimation),
                            {
        backgroundBitmap = get_tag_id('bitm',
                                      constants.bitmaps['forgeLoadingProgress' ..
                                          tostring(lastImage)])
    })
    return true
end

function onMapLoad()
    -- Like Redux we have some kind of store baby!! the rest is pure magic..
    playerStore = redux.createStore(playerReducer)
    forgeStore = redux.createStore(forgeReducer) -- Isolated store for all the Forge 'app' data
    eventsStore = redux.createStore(eventsReducer) -- Unique store for all the Forge Objects

    local forgeState = forgeStore:getState()
    local scenario = blam.scenario(get_tag(0))

    -- TO DO: Refactor this entire loop, has been implemented from the old script!!!
    for i = 1, #scenario.sceneryPaletteList do -- Iterate over all the sceneries available in the map scenario
        local sceneryPath = get_tag_path(scenario.sceneryPaletteList[i])
        local sceneriesSplit = glue.string.split('\\', sceneryPath)
        --[[ Example:

			[shm]\halo_4\scenery\structures\natural\tree small\tree small
			---------------------> "structures\natural\tree small\tree small"
			
			[shm]\halo_4\scenery\barricades\barricade large\barricade large
			---------------------> "barricades\barricade large\barricade large"
		]]
        local sceneryFolderIndex
        for j, n in pairs(sceneriesSplit) do
            if (n == 'scenery') then sceneryFolderIndex = j + 1 end
        end
        local fixedSplittedPath = {}
        for l = sceneryFolderIndex, #sceneriesSplit do
            fixedSplittedPath[#fixedSplittedPath + 1] = sceneriesSplit[l]
        end
        sceneriesSplit = fixedSplittedPath
        forgeState.forgeMenu.objectsDatabase[sceneriesSplit[#sceneriesSplit]] =
            sceneryPath
        -- Set first level as the root of available current objects
        -- THIS IS CALLED BY REFERENCE TO MODIFY availableObjects

        -- Make a tree iteration to append sceneries
        local treePosition = forgeState.forgeMenu.objectsList.root
        for k, v in pairs(sceneriesSplit) do
            if (not treePosition[v]) then treePosition[v] = {} end
            treePosition = treePosition[v]
        end
    end
    dprint('Scenery database has ' ..
               #glue.keys(forgeState.forgeMenu.objectsDatabase) .. ' objects.')

    -- Subscribed function to refresh forge state into the game!
    -- TO DO: The subscribed function can be isolated from the map loading
    -- This is probably not that bad (?)... needs more testing.
    forgeStore:subscribe(function()
        -- Get current forge state
        local forgeState = forgeStore:getState()

        local currentObjectsList =
            forgeState.forgeMenu.currentObjectsList[forgeState.forgeMenu
                .currentPage]

        -- Prevent errors objects does not exist
        if (not currentObjectsList) then
            dprint('Current objects list is empty.', 'warning')
            currentObjectsList = {}
        end

        -- Forge Menu
        blam.unicodeStringList(get_tag('unicode_string_list',
                                       constants.unicodeStrings.forgeList),
                               {stringList = currentObjectsList})
        menu.update(constants.widgetDefinitions.forgeList, #currentObjectsList)

        local paginationTextAddress = get_tag('unicode_string_list',
                                              constants.unicodeStrings
                                                  .pagination)
        if (paginationTextAddress) then
            local pagination = blam.unicodeStringList(paginationTextAddress)
            local paginationStringList = pagination.stringList
            paginationStringList[2] = tostring(forgeState.forgeMenu.currentPage)
            paginationStringList[4] = tostring(
                                          #forgeState.forgeMenu
                                              .currentObjectsList)
            blam.unicodeStringList(paginationTextAddress,
                                   {stringList = paginationStringList})
        end

        -- Budget count
        -- Update unicode string with current budget value
        local budgetCountAddress = get_tag('unicode_string_list',
                                           constants.unicodeStrings.budgetCount)
        local currentBudget = blam.unicodeStringList(budgetCountAddress)

        currentBudget.stringList = {forgeState.forgeMenu.currentBudget}

        -- Refresh budget count
        blam.unicodeStringList(budgetCountAddress, currentBudget)

        -- Refresh budget bar status
        blam.uiWidgetDefinition(get_tag('ui_widget_definition',
                                        constants.widgetDefinitions.amountBar),
                                {width = forgeState.forgeMenu.currentBarSize})

        -- Refresh loading bar size
        blam.uiWidgetDefinition(get_tag('ui_widget_definition',
                                        constants.widgetDefinitions
                                            .loadingProgress),
                                {width = forgeState.loadingMenu.currentBarSize})

        local currentMapsList =
            forgeState.mapsMenu.currentMapsList[forgeState.mapsMenu.currentPage]
            
        -- Prevent errors when maps does not exist
        if (not currentMapsList) then
            dprint('Current maps list is empty.')
            currentMapsList = {}
        end

        -- Refresh available forge maps list
        -- TO DO: Merge unicode string updating with menus updating!
        blam.unicodeStringList(get_tag('unicode_string_list',
                                       constants.unicodeStrings.mapsList),
                               {stringList = currentMapsList})
        -- Wich ui widget will be updated and how many items it will show
        menu.update(constants.widgetDefinitions.mapsList, #currentMapsList)

        -- Refresh fake sidebar in maps menu
        blam.uiWidgetDefinition(get_tag('ui_widget_definition',
                                        constants.widgetDefinitions.sidebar), {
            height = forgeState.mapsMenu.sidebar.height,
            boundsY = forgeState.mapsMenu.sidebar.position
        })

        -- Refresh current forge map information
        blam.unicodeStringList(get_tag('unicode_string_list',
                                       constants.unicodeStrings.pauseGameStrings),
                               {
            stringList = {
                -- Bypass first 3 elements in the string list
                '', '', '', forgeState.currentMap.name,
                forgeState.currentMap.author, forgeState.currentMap.version,
                forgeState.currentMap.description
            }
        })
    end)

    -- Dispatch forge objects list update
    forgeStore:dispatch({
        type = 'UPDATE_FORGE_OBJECTS_LIST',
        payload = {forgeMenu = forgeState.forgeMenu}
    })

    local isForgeMap = validateMapName()
    if (isForgeMap) then
        dprint('Forge has been loaded!')

        -- Forge maps folder creation
        forgeMapsFolder = hfs.currentdir() .. '\\fmaps'
        local alreadyForgeMapsFolder = not hfs.mkdir(forgeMapsFolder)
        if (not alreadyForgeMapsFolder) then
            dprint('Forge maps folder has been created!')
        end

        loadForgeMapsList()

        set_callback('tick', 'onTick')
        set_callback('rcon message', 'onRcon')
        set_callback('command', 'onCommand')
    else
        console_out_error('This is not a compatible Forge map!!!')
    end
end

function onRcon(message)
    dprint('Incoming rcon message:', 'warning')
    dprint(message)
    local request = string.gsub(message, "'", '')
    local splitData = glue.string.split(',', request)
    local requestType = constants.requestTypes[splitData[1]]
    if (requestType) then
        dprint('Decoding incoming ' .. requestType .. ' ...', 'warning')

        local requestObject = maethrillian.convertRequestToObject(request,
                                                                  constants.requestFormats[requestType])

        if (requestObject) then
            dprint('Done.', 'success')
        else
            dprint('Error at converting request.', 'error')
            return false, nil
        end

        dprint('Decompressing ...', 'warning')
        local compressionFormat = constants.compressionFormats[requestType]
        requestObject = maethrillian.decompressObject(requestObject,
                                                      compressionFormat)

        if (requestObject) then
            dprint('Done.', 'success')
        else
            dprint('Error at decompressing request.', 'error')
            return false, nil
        end

        if (not ftestingMode) then
            eventsStore:dispatch({
                type = requestType,
                payload = {requestObject = requestObject}
            })
        end
        return false, requestObject
    end
    return true
end

function loadForgeMapsList()
    local arrayMapsList = {}
    for file in hfs.dir(forgeMapsFolder) do
        if (file ~= '.' and file ~= '..') then
            glue.append(arrayMapsList, file)
        end
    end
    -- Dispatch state modification!
    local data = {mapsList = arrayMapsList}
    forgeStore:dispatch({type = 'UPDATE_MAP_LIST', payload = data})
end

-- Allows the script to run by just reloading it
if (server_type == 'local') then onMapLoad() end

function onCommand(command)
    if (command == 'fdebug') then
        debugMode = not debugMode
        console_out('Debug Forge: ' .. tostring(debugMode))
        return false
    else
        -- Split all the data in the command input
        local splitCommand = glue.string.split(' ', command)

        -- Substract first console command
        local forgeCommand = splitCommand[1]

        if (forgeCommand == 'fstep') then
            local newRotationStep = tonumber(splitCommand[2])
            if (newRotationStep) then
                hud_message('Rotation step now is ' .. newRotationStep ..
                                ' degrees.')
                playerStore:dispatch({
                    type = 'SET_ROTATION_STEP',
                    payload = {step = newRotationStep}
                })
            else
                playerStore:dispatch({
                    type = 'SET_ROTATION_STEP',
                    payload = {step = 3}
                })
            end
            return false
        elseif (forgeCommand == 'fdis' or forgeCommand == 'fdistance') then
            local newDistance = tonumber(splitCommand[2])
            if (newDistance) then
                hud_message('Distance from object has been set to ' ..
                                newDistance .. ' units.')
                -- Force distance object update
                playerStore:dispatch({
                    type = 'SET_LOCK_DISTANCE',
                    payload = {lockDistance = true}
                })
                local distance = glue.round(newDistance)
                playerStore:dispatch({
                    type = 'SET_DISTANCE',
                    payload = {distance = distance}
                })
            else
                local distance = 3
                playerStore:dispatch({
                    type = 'SET_DISTANCE',
                    payload = {distance = distance}
                })
            end
            return false
        elseif (forgeCommand == 'fsave') then
            local mapName = forgeStore:getState().currentMap.name
            if (mapName) then
                core.saveForgeMap(mapName)
            else
                console_out('You must specify a name for your forge map.')
            end
            return false
        elseif (forgeCommand == 'fload') then
            local mapName = table.concat(glue.shift(splitCommand, 1, -1), ' ')
            if (mapName) then
                core.loadForgeMap(mapName)
            else
                console_out('You must specify a forge map name.')
            end
            return false
        elseif (forgeCommand == 'flist') then
            for file in hfs.dir(forgeMapsFolder) do
                if (file ~= '.' and file ~= '..') then
                    console_out(file)
                end
            end
            return false
        elseif (forgeCommand == 'ftest') then
            -- Run unit testing
            tests.run(true)
            return false
        elseif (forgeCommand == 'fobject') then
            local objectId = tonumber(splitCommand[2])
            console_out(tostring(get_object(objectId)))
            local eraseConfirm = splitCommand[3]
            if (eraseConfirm) then delete_object(objectId) end
            return false
        elseif (forgeCommand == 'fdump') then
            glue.writefile('forge_dump.json', inspect(forgeStore:getState()),
                           't')
            glue.writefile('events_dump.json',
                           inspect(eventsStore:getState().forgeObjects), 't')
            glue.writefile('debug_dump.txt', debugBuffer, 't')
            return false
        elseif (forgeCommand == 'fprint') then
            -- Testing rcon communication
            dprint('[Game Objects]', 'category')

            local objects = get_objects()

            -- Debug in game objects count
            dprint('Count: ' .. #objects)

            -- Debug list of all the in game objects
            dprint(inspect(objects))

            dprint('[Objects Store]', 'category')

            local storeObjects = glue.keys(eventsStore:getState().forgeObjects)

            -- Debug store objects count
            dprint('Count: ' .. #storeObjects)

            -- Debug list of all the store objects
            dprint(inspect(storeObjects))

            return false
        elseif (forgeCommand == 'fname') then
            local mapName = table.concat(glue.shift(splitCommand, 1, -1), ' ')
            forgeStore:dispatch({
                type = 'SET_MAP_NAME',
                payload = {mapName = mapName}
            })
            return false
        end
    end
end

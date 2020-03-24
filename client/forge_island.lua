------------------------------------------------------------------------------
-- Forge Island Client Script
-- Author: Sledmine
-- Version: 4.0
-- Client side script for Forge Island
------------------------------------------------------------------------------

clua_version = 2.042

-- Lua libraries
local inspect = require 'inspect'
local json = require 'json'
local glue = require 'glue'
local redux = require 'lua-redux'

-- Specific Halo Custom Edition libraries
local blam = require 'luablam'
local maethrillian = require 'maethrillian'
local hfs = require 'hcefs'

-- Forge modules
local triggers = require 'forge.triggers'
local hook = require 'forge.hook'
local constants = require 'forge.constants'
local menu = require 'forge.menu'

-- Default debug mode state
debugMode = false

-- Internal functions
-- Super function to keep compatibility with SAPP and printing debug messages if needed
local function cprint(message, color)
    if (debugMode) then
        --console_out(message)
        if (color == 'category') then
            console_out(message, 0.31, 0.631, 0.976)
        elseif (color == 'warning') then
            console_out_warning(message)
        elseif (color == 'error') then
            console_out_error(message)
        elseif (color == 'success') then
            console_out(message, 0.235, 0.82, 0)
        else
            console_out(message)
        end
    end
end

local function cspawn_object(type, tagPath, x, y, z)
    cprint(' -> [ Object Spawning ]')
    cprint('Type:', 'category')
    cprint(type)
    cprint('Tag  Path:', 'category')
    cprint(tagPath)
    cprint('Trying to spawn object...', 'warning')
    local objectId = spawn_object(type, tagPath, x, y, z)
    if (objectId) then
        cprint('-> Object succesfully spawned!!!', 'success')
        return objectId
    end
    cprint('Error at trying to spawn object!!!!', 'error')
    return nil
end

local function get_objects()
    local objectsList = {}
    for i = 0, 1023 do
        if (get_object(i)) then
            objectsList[#objectsList + 1] = i
        end
    end
    return objectsList
end

-- Mod functions
local function swapBiped()
    if (server_type == 'local') then
        -- Needs kinda refactoring, probably splitting this into LuaBlam
        local globalsTagAddress = get_tag('matg', 'globals\\globals')
        local globalsTagData = read_dword(globalsTagAddress + 0x14)
        local globalsTagMultiplayerBipedTagIdAddress = globalsTagData + 0x9BC + 0xC
        local currentGlobalsBipedTagId = read_dword(globalsTagMultiplayerBipedTagIdAddress)
        cprint('Globals Biped ID: ' .. currentGlobalsBipedTagId)
        for i = 0, 1023 do
            local tempObject = blam.object(get_object(i))
            if (tempObject and tempObject.tagId == get_tag_id('bipd', constants.bipeds.spartan)) then
                write_dword(globalsTagMultiplayerBipedTagIdAddress, get_tag_id('bipd', constants.bipeds.monitor))
                delete_object(i)
            elseif (tempObject and tempObject.tagId == get_tag_id('bipd', constants.bipeds.monitor)) then
                write_dword(globalsTagMultiplayerBipedTagIdAddress, get_tag_id('bipd', constants.bipeds.spartan))
                delete_object(i)
            end
        end
    else
        execute_script('rcon forge #b')
    end
end

-- Changes default crosshair values
local function setCrosshairState(state)
    local forgeCrosshairAddress = get_tag('weapon_hud_interface', constants.weaponHudInterfaces.forgeCrosshair)
    local forgeCrosshair = blam.weaponHudInterface(forgeCrosshairAddress)
    if (state == 0) then
        blam.weaponHudInterface(
            forgeCrosshairAddress,
            {
                defaultRed = 64,
                defaultGreen = 169,
                defaultBlue = 255,
                sequenceIndex = 1
            }
        )
    elseif (state == 1) then
        blam.weaponHudInterface(
            forgeCrosshairAddress,
            {
                defaultRed = 0,
                defaultGreen = 255,
                defaultBlue = 0,
                sequenceIndex = 2
            }
        )
    elseif (state == 2) then
        blam.weaponHudInterface(
            forgeCrosshairAddress,
            {
                defaultRed = 0,
                defaultGreen = 255,
                defaultBlue = 0,
                sequenceIndex = 3
            }
        )
    elseif (state == 3) then
        blam.weaponHudInterface(
            forgeCrosshairAddress,
            {
                defaultRed = 255,
                defaultGreen = 0,
                defaultBlue = 0,
                sequenceIndex = 4
            }
        )
    else
        blam.weaponHudInterface(
            forgeCrosshairAddress,
            {
                defaultRed = 64,
                defaultGreen = 169,
                defaultBlue = 255,
                sequenceIndex = 0
            }
        )
    end
end

-- Check if current player is using a monitor biped
local function isPlayerMonitor()
    local tempObject = blam.object(get_dynamic_player())
    if (tempObject and tempObject.tagId == get_tag_id('bipd', constants.bipeds.monitor)) then
        return true
    end
    return false
end

-- Global script variables
-- They can be accessed through global script scope but no by libraries!

-- Default rotation step, minimum default distance from an object, distance from object is blocked by default
local rotationStep = 3
local blockDistance = true

-- Prepare event callbacks
set_callback('map postload', 'onMapLoad') -- Thanks Jerry to add this callback!
set_callback('unload', 'onScriptUnload')

function validateMapName()
    return map == 'forge_island_local' or map == 'forge_island' or map == 'forge_island_beta'
end

function playerReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        state = {
            distance = 5,
            attachedObject = nil,
            xOffset = 0,
            yOffset = 0,
            zOffset = 0
        }
    end
    if (action.type == 'ATTACH_OBJECT') then
        if (state.attachedObject) then
            if (get_object(state.attachedObject)) then
                delete_object(state.attachedObject)
                state.attachedObject =
                    cspawn_object('scen', action.payload.path, state.xOffset, state.yOffset, state.zOffset)
            else
                state.attachedObject =
                    cspawn_object('scen', action.payload.path, state.xOffset, state.yOffset, state.zOffset)
            end
        else
            state.attachedObject =
                cspawn_object('scen', action.payload.path, state.xOffset, state.yOffset, state.zOffset)
        end
        return state
    elseif (action.type == 'DETACH_OBJECT') then -- REMINDER TO SEND REQUEST IF NEEDED
        state.attachedObject = nil
        return state
    elseif (action.type == 'DESTROY_OBJECT') then -- REMINDER TO SEND REQUEST IF NEEDED
        if (state.attachedObject) then
            if (get_object(state.attachedObject)) then
                delete_object(state.attachedObject)
            end
        end
        state.attachedObject = nil
        return state
    elseif (action.type == 'UPDATE_OFFSETS') then
        local player = action.payload.player
        state.xOffset = player.x + player.cameraX * state.distance
        state.yOffset = player.y + player.cameraY * state.distance
        state.zOffset = player.z + player.cameraZ * state.distance
        return state
    else
        return state
    end
end

-- Update internal state along the time
function onTick()
    -- Get player object
    local player = blam.biped(get_dynamic_player())
    local playerState = playerStore:getState()
    if (player) then
        player.isMonitor = isPlayerMonitor()
        if (player.isMonitor) then
            playerStore:dispatch({type = 'UPDATE_OFFSETS', payload = {player = player}})

            -- Open Forge menu by pressing 'Q'
            if (player.flashlightKey) then
                cprint('Opening Forge menu...')
                -- TO DO: Create a module to load different UI widgets!
                execute_script('multiplayer_map_name sledisawesome')
                execute_script('multiplayer_map_name ' .. map)
            end

            -- Check if monitor has an object attached
            local attachedObject = playerState.attachedObject
            if (attachedObject) then
                setCrosshairState(2)
                blam.object(
                    get_object(attachedObject),
                    {x = playerState.xOffset, y = playerState.yOffset, z = playerState.zOffset}
                )
                if (player.jumpHold) then
                    playerStore:dispatch({type = 'DESTROY_OBJECT'})
                elseif (player.weaponSTH) then
                    playerStore:dispatch({type = 'DETACH_OBJECT'})
                end
            else
                setCrosshairState(0)
            end

            -- Convert into spartan
            if (player.crouchHold) then
                swapBiped()
            end
        else
            -- Convert into monitor
            if (player.flashlightKey) then
                swapBiped()
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
        end
        cprint('Maps menu:')
        cprint('Button ' .. mapsMenuPressedButton .. ' was pressed!', 'category')
    end

    local forgeMenuPressedButton = triggers.get('forge_menu', 9)
    if (forgeMenuPressedButton) then
        local forgeState = forgeStore:getState()
        if (forgeMenuPressedButton == 9) then
            if (forgeState.forgeMenu.desiredElement ~= 'root') then
                forgeStore:dispatch({type = 'UPWARD_NAV_FORGE_MENU'})
            else
                cprint('Closing Forge menu...')
                menu.close(constants.widgetDefinitions.forgeMenu)
            end
        elseif (forgeMenuPressedButton == 8) then
            forgeStore:dispatch({type = 'INCREMENT_FORGE_MENU_PAGE'})
        elseif (forgeMenuPressedButton == 7) then
            forgeStore:dispatch({type = 'DECREMENT_FORGE_MENU_PAGE'})
        else
            local desiredElement =
                blam.unicodeStringList(get_tag('unicode_string_list', constants.unicodeStrings.forgeList)).stringList[
                forgeMenuPressedButton
            ]
            local sceneryPath = forgeState.forgeMenu.objectsDatabase[desiredElement]
            if (sceneryPath) then
                cprint(' -> [ Forge Menu ]')
                playerStore:dispatch({type = 'ATTACH_OBJECT', payload = {path = sceneryPath}})
            else
                forgeStore:dispatch({type = 'DOWNWARD_NAV_FORGE_MENU', payload = {desiredElement = desiredElement}})
            end
        end
        cprint(' -> [ Forge Menu ]')
        cprint('Button ' .. forgeMenuPressedButton .. ' was pressed!', 'category')
    end

    -- Attach respective hooks!
    hook.attach('maps_menu', menu.stopUpdate, constants.widgetDefinitions.mapsList)
    hook.attach('forge_menu', menu.stopUpdate, constants.widgetDefinitions.forgeList)
    hook.attach('forge_menu_close', menu.stopClose, constants.widgetDefinitions.forgeMenu)
end

function objectsReducer()
end

function forgeReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        state = {
            mapsMenu = {
                mapsList = {},
                currentMapsList = {},
                currentPage = 1,
                sidebar = {
                    height = constants.maximumSidebarSize,
                    position = 0,
                    slice = 0
                }
            },
            forgeMenu = {
                desiredElement = 'root',
                objectsDatabase = {},
                objectsList = {root = {}},
                currentObjectsList = {},
                currentPage = 1
            },
            currentMap = {
                name = 'Unsaved',
                author = 'Author: Unknown',
                version = '1.0',
                description = 'No description given for this map.'
            }
        }
    end
    if (action.type) then
        cprint('Dispatched event:')
        cprint(action.type, 'category')
    end
    if (action.type == 'UPDATE_MAP_LIST') then
        state.mapsMenu.mapsList = action.payload.mapsList
        state.mapsMenu.currentMapsList = glue.chunks(state.mapsMenu.mapsList, 8)
        if (#state.mapsMenu.currentMapsList > 1) then
            local sidebarHeight = glue.floor(constants.maximumSidebarSize / #state.mapsMenu.currentMapsList)
            if (sidebarHeight < constants.minimumSidebarSize) then
                sidebarHeight = constants.minimumSidebarSize
            end
            state.mapsMenu.sidebar.height = sidebarHeight
            state.mapsMenu.sidebar.position = 0
            state.mapsMenu.sidebar.slice =
                glue.round((constants.maximumSidebarSize - sidebarHeight) / (#state.mapsMenu.currentMapsList - 1))
        end
        cprint(inspect(state.mapsMenu))
        return state
    elseif (action.type == 'INCREMENT_MAPS_MENU_PAGE') then
        if (state.mapsMenu.currentPage < #state.mapsMenu.currentMapsList) then
            state.mapsMenu.currentPage = state.mapsMenu.currentPage + 1
            state.mapsMenu.sidebar.height = state.mapsMenu.sidebar.height + state.mapsMenu.sidebar.slice
            state.mapsMenu.sidebar.position = state.mapsMenu.sidebar.position + state.mapsMenu.sidebar.slice
        end
        cprint(state.mapsMenu.currentPage)
        return state
    elseif (action.type == 'DECREMENT_MAPS_MENU_PAGE') then
        if (state.mapsMenu.currentPage > 1) then
            state.mapsMenu.currentPage = state.mapsMenu.currentPage - 1
            state.mapsMenu.sidebar.height = state.mapsMenu.sidebar.height - state.mapsMenu.sidebar.slice
            state.mapsMenu.sidebar.position = state.mapsMenu.sidebar.position - state.mapsMenu.sidebar.slice
        end
        cprint(state.mapsMenu.currentPage)
        return state
    elseif (action.type == 'UPDATE_FORGE_OBJECTS_LIST') then
        state.forgeMenu = action.payload.forgeMenu
        local objectsList = glue.childsByParent(state.forgeMenu.objectsList, state.forgeMenu.desiredElement)
        state.forgeMenu.currentObjectsList = glue.chunks(glue.keys(objectsList), 6)
        cprint(inspect(state.forgeMenu))
        return state
    elseif (action.type == 'INCREMENT_FORGE_MENU_PAGE') then
        cprint('Page:' .. inspect(state.forgeMenu.currentPage))
        if (state.forgeMenu.currentPage < #state.forgeMenu.currentObjectsList) then
            state.forgeMenu.currentPage = state.forgeMenu.currentPage + 1
        end
        return state
    elseif (action.type == 'DECREMENT_FORGE_MENU_PAGE') then
        cprint('Page:' .. inspect(state.forgeMenu.currentPage))
        if (state.forgeMenu.currentPage > 1) then
            state.forgeMenu.currentPage = state.forgeMenu.currentPage - 1
        end
        return state
    elseif (action.type == 'DOWNWARD_NAV_FORGE_MENU') then
        state.forgeMenu.currentPage = 1
        state.forgeMenu.desiredElement = action.payload.desiredElement
        local objectsList = glue.childsByParent(state.forgeMenu.objectsList, state.forgeMenu.desiredElement)
        state.forgeMenu.currentObjectsList = glue.chunks(glue.keys(objectsList), 6)
        cprint(inspect(state.forgeMenu))
        return state
    elseif (action.type == 'UPWARD_NAV_FORGE_MENU') then
        state.forgeMenu.currentPage = 1
        state.forgeMenu.desiredElement = glue.parentByChild(state.forgeMenu.objectsList, state.forgeMenu.desiredElement)
        local objectsList = glue.childsByParent(state.forgeMenu.objectsList, state.forgeMenu.desiredElement)
        state.forgeMenu.currentObjectsList = glue.chunks(glue.keys(objectsList), 6)
        cprint(inspect(state.forgeMenu))
        return state
    elseif (action.type == 'SET_MAP_NAME') then
        state.currentMap.name = action.payload.mapName
        return state
    else
        if (action.type == '@@lua-redux/INIT') then
            cprint('Default state has been created!')
        else
            cprint('ERROR!!! The dispatched event does not exist:', 'error')
        end
        return state
    end
end

function onMapLoad()
    -- Like Redux we have some kind of store baby!! the rest is pure magic..
    playerStore = redux.createStore(playerReducer)
    forgeStore = redux.createStore(forgeReducer) -- Isolated store for all the Forge 'app' data
    objectsStore = redux.createStore(objectsReducer) -- Unique store for all the Forge Objects

    local forgeState = forgeStore:getState()
    local scenario = blam.scenario(get_tag(0))

    -- TO DO: Refactor this entire loop, has been implemented from the old script!!!
    for i = 1, #scenario.sceneryPaletteList do -- Iterate over all the sceneries available in the map scenario
        local sceneryPath = get_tag_path(scenario.sceneryPaletteList[i])
        local sceneriesSplit = glue.string.split('\\', sceneryPath)
        -- Make a tree iteration to append sceneries
        --[[ Example:

			[shm]\halo_4\scenery\structures\natural\tree small\tree small
			---------------------> "structures\natural\tree small\tree small"
			
			[shm]\halo_4\scenery\barricades\barricade large\barricade large
			---------------------> "barricades\barricade large\barricade large"
		]]
        local sceneryFolderIndex
        for j, n in pairs(sceneriesSplit) do
            if (n == 'scenery') then
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
        -- THIS IS CALLED BY REFERENCE TO MODIFY availableObjects
        local treePosition = forgeState.forgeMenu.objectsList.root
        for k, v in pairs(sceneriesSplit) do
            if (not treePosition[v]) then
                treePosition[v] = {}
            end
            treePosition = treePosition[v]
        end
    end
    cprint('Scenery database has ' .. #glue.keys(forgeState.forgeMenu.objectsDatabase) .. ' objects.')

    -- Subscribed function to refresh forge state into the game!
    -- TO DO: The subscribed function can be isolated from the map loading
    -- This is probably not that bad (?)... needs more testing.
    forgeStore:subscribe(
        function()
            -- Get current forge state
            local forgeState = forgeStore:getState()

            local currentObjectsList = forgeState.forgeMenu.currentObjectsList[forgeState.forgeMenu.currentPage]

            -- Prevent errors objects does not exist
            if (not currentObjectsList) then
                cprint('Current objects list is empty.', 'warning')
                currentObjectsList = {}
            end

            -- Sort all the elements in alphabetic order
            table.sort(
                currentObjectsList,
                function(a, b)
                    return a < b
                end
            )

            -- Forge Menu
            blam.unicodeStringList(
                get_tag('unicode_string_list', constants.unicodeStrings.forgeList),
                {stringList = currentObjectsList}
            )
            menu.update(constants.widgetDefinitions.forgeList, #currentObjectsList)

            local paginationTextAddress = get_tag('unicode_string_list', constants.unicodeStrings.pagination)
            if (paginationTextAddress) then
                local pagination = blam.unicodeStringList(paginationTextAddress)
                local paginationStringList = pagination.stringList
                paginationStringList[2] = tostring(forgeState.forgeMenu.currentPage)
                paginationStringList[4] = tostring(#forgeState.forgeMenu.currentObjectsList)
                blam.unicodeStringList(paginationTextAddress, {stringList = paginationStringList})
            end

            local currentMapsList = forgeState.mapsMenu.currentMapsList[forgeState.mapsMenu.currentPage]
            -- Prevent errors when maps does not exist
            if (not currentMapsList) then
                cprint('Current maps list is empty.')
                currentMapsList = {}
            end

            -- Refresh available forge maps list
            -- TO DO: Merge unicode string updating with menus updating!
            blam.unicodeStringList(
                get_tag('unicode_string_list', constants.unicodeStrings.mapsList),
                {stringList = currentMapsList}
            )
            -- Wich ui widget will be updated and how many items it will show
            menu.update(constants.widgetDefinitions.mapsList, #currentMapsList)

            -- Refresh fake sidebar in maps menu
            blam.uiWidgetDefinition(
                get_tag('ui_widget_definition', constants.widgetDefinitions.sidebar),
                {
                    height = forgeState.mapsMenu.sidebar.height,
                    boundsY = forgeState.mapsMenu.sidebar.position
                }
            )

            -- Refresh current forge map information
            blam.unicodeStringList(
                get_tag('unicode_string_list', constants.unicodeStrings.pauseGameStrings),
                {
                    stringList = {
                        -- Bypass first 3 elements in the string list
                        '',
                        '',
                        '',
                        forgeState.currentMap.name,
                        forgeState.currentMap.author,
                        forgeState.currentMap.version,
                        forgeState.currentMap.description
                    }
                }
            )
        end
    )

    -- Dispatch forge objects list update
    forgeStore:dispatch({type = 'UPDATE_FORGE_OBJECTS_LIST', payload = {forgeMenu = forgeState.forgeMenu}})

    local isForgeMap = validateMapName()
    if (isForgeMap) then
        cprint('Forge has been loaded!')

        -- Forge maps folder creation
        forgeMapsFolder = hfs.currentdir() .. '\\fmaps'
        local alreadyForgeMapsFolder = not hfs.mkdir(forgeMapsFolder)
        if (not alreadyForgeMapsFolder) then
            cprint('Forge maps folder has been created!')
        end

        loadForgeMapsList()

        set_callback('tick', 'onTick')
        set_callback('rcon message', 'onRcon')
        set_callback('command', 'onCommand')
    else
        console_out_error('This is not a compatible Forge map!!!')
    end
end

function loadForgeMapsList()
    local mapsList = {}
    for file in hfs.dir(forgeMapsFolder) do
        if (file ~= '.' and file ~= '..') then
            glue.append(mapsList, file)
        end
    end
    -- Dispatch state modification!
    forgeStore:dispatch({type = 'UPDATE_MAP_LIST', payload = {mapsList = mapsList}})
end

-- Allows the script to run by just reloading it
if (server_type == 'local') then
    onMapLoad()
end

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
                hud_message('Rotation step now is ' .. newRotationStep .. ' degrees.')
                rotationStep = glue.round(newRotationStep)
            else
                rotationStep = 3
            end
            return false
        elseif (forgeCommand == 'fdis' or forgeCommand == 'fdistance') then
            local newDistance = tonumber(splitCommand[2])
            if (newDistance) then
                hud_message('Distance from object has been set to ' .. newDistance .. ' units.')
                -- Force distance object update
                blockDistance = true
                distance = glue.round(newDistance)
            else
                distance = 3
            end
            return false
        elseif (forgeCommand == 'fsave') then
            local mapName = splitCommand[2]
            if (mapName) then
                saveForgeMap(mapName)
            else
                console_out('You must specify a name for your forge map.')
            end
            return false
        elseif (forgeCommand == 'fload') then
            local mapName = splitCommand[2]
            if (mapName) then
                loadForgeMap(mapName)
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
        elseif (forgeCommand == 'fdump') then
            --[[console_out('Dumping forge objects store...')
            glue.writefile('fdumpStore.txt', inspect(objectsStore), 't')
            console_out('DONE!, fdumpStore has been created.txt!!')]]
            forgeStore:dispatch({type = 'RESET_FORGE'})
            return false
        elseif (forgeCommand == 'freset') then
            execute_script('object_destroy_all')
            flushScript()
            return false
        elseif (forgeCommand == 'fname') then
            local mapName = table.concat(glue.shift(splitCommand, 1, -1), ' ')
            forgeStore:dispatch(
                {
                    type = 'SET_MAP_NAME',
                    payload = {mapName = mapName}
                }
            )
            return false
        end
    end
end

function onScriptUnload()
    if (#get_objects() > 0) then
        --saveForgeMap('unsaved')
        execute_script('object_destroy_all')
    end
end

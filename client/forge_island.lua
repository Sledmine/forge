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

-- Default debug mode state
debugMode = glue.readfile('forge_debug_mode.dbg', 't')

-- Internal functions

-- Super function to keep compatibility with SAPP and printing debug messages if needed
---@param message string
---@param color string | "'category'" | "'warning'" | "'error'" | "'success'"
function cprint(message, color)
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

-- Super function for debug printing and accurate spawning
---@param type string | "'scen'" | '"bipd"'
---@param tagPath string
---@param x number @param y number @param Z number
---@return number | nil objectId
function cspawn_object(type, tagPath, x, y, z)
    cprint(' -> [ Object Spawning ]')
    cprint('Type:', 'category')
    cprint(type)
    cprint('Tag  Path:', 'category')
    cprint(tagPath)
    cprint('Trying to spawn object...', 'warning')
    -- Prevent objects from phantom spawning!
    -- local variables are accesed first than parameter variables
    local z = z
    if (z < constants.minimumZSpawnPoint) then
        z = constants.minimumZSpawnPoint
    end
    local objectId = spawn_object(type, tagPath, x, y, z)
    if (objectId) then
        cprint('-> Object: ' .. objectId .. ' succesfully spawned!!!', 'success')
        return objectId
    end
    cprint('Error at trying to spawn object!!!!', 'error')
    return nil
end

function getObjectIdByRemoteId(state, remoteId)
    for k, v in pairs(state) do
        if (v.remoteId == remoteId) then
            return k
        end
    end
    return nil
end

-- Global script variables
-- They can be accessed through global script scope but no by libraries!

-- Default rotation step, minimum default distance from an object, distance from object is blocked by default
local rotationStep = 3
local blockDistance = true

-- Prepare event callbacks
set_callback('map load', 'onMapLoad') -- Thanks Jerry to add this callback!
set_callback('unload', 'onScriptUnload')

---@return boolean
function validateMapName()
    return map == 'forge_island_local' or map == 'forge_island' or map == 'forge_island_beta'
end

require 'forge.playerReducer'

-- Update internal state along the time
function onTick()
    -- Get player object
    local player = blam.biped(get_dynamic_player())
    local playerState = playerStore:getState()
    if (player) then
        player.isMonitor = features.isPlayerMonitor()
        --cprint(player.x .. ' ' .. player.y .. ' ' .. player.z)
        if (player.isMonitor) then
            -- Calculate player point of view
            playerStore:dispatch({type = 'UPDATE_OFFSETS', payload = {player = player}})

            -- Open Forge menu by pressing 'Q'
            if (player.flashlightKey) then
                cprint('Opening Forge menu...')
                -- TO DO: Create a module to load different UI widgets!
                execute_script('multiplayer_map_name sledisawesome')
                execute_script('multiplayer_map_name ' .. map)
            end

            -- Check if monitor has an object attached
            local attachedObjectId = playerState.attachedObjectId
            if (attachedObjectId) then
                if (not playerState.lockDistance) then
                    playerStore:dispatch({type = 'UPDATE_DISTANCE', payload = {player = player}})
                    playerStore:dispatch({type = 'UPDATE_OFFSETS', payload = {player = player}})
                end

                -- Unhighlight objects
                features.unhighlightAll()

                -- Update crosshair
                features.setCrosshairState(2)

                if (playerState.zOffset < constants.minimumZSpawnPoint) then
                    -- Set crosshair to not allowed
                    features.setCrosshairState(3)
                end

                -- Update object position
                blam.object(
                    get_object(attachedObjectId),
                    {
                        x = playerState.xOffset,
                        y = playerState.yOffset,
                        z = playerState.zOffset
                        -- TODO: Object color customization!
                        --[[redA = math.random(0,1),
                        greenA = math.random(0,1),
                        blueA = math.random(0,1)]]
                    }
                )
                if (player.jumpHold) then
                    playerStore:dispatch({type = 'DESTROY_OBJECT'})
                elseif (player.weaponSTH) then
                    playerStore:dispatch({type = 'DETACH_OBJECT'})
                end
            else
                
                -- Set crosshair to not selected states
                features.setCrosshairState(0)

                -- Unhighlight objects
                features.unhighlightAll()

                -- Get if player is looking at some object
                for objectId = 0, #get_objects() do
                    local tempObject = blam.object(get_object(objectId))
                    -- Object exists
                    if (tempObject) then
                        local tagType = get_tag_type(tempObject.tagId)
                        if (tagType == 'scen') then
                            local isPlayerLookingAt = features.playerIsLookingAt(objectId, 0.06, 0)
                            if (isPlayerLookingAt) then
                                -- Update crosshair state
                                features.setCrosshairState(1)

                                -- Hightlight object at player view
                                features.highlightObject(objectId, 0.7)

                                -- Player is taking the object
                                if (player.weaponPTH) then
                                    -- Set lock distance to true, this will help to take the object from persepective
                                    playerStore:dispatch({type = 'SET_LOCK_DISTANCE', payload = {lockDistance = false}})
                                    playerStore:dispatch({type = 'ATTACH_OBJECT', payload = {objectId = objectId}})
                                end
                            end
                        end
                    end
                end
            end

            -- Convert into spartan
            if (player.crouchHold) then
                playerStore:dispatch({type = 'DETACH_OBJECT'})
                features.swapBiped()
            elseif (player.meleeKey) then
                playerStore:dispatch({type = 'SET_LOCK_DISTANCE', payload = {lockDistance = not playerState.lockDistance}})
                hud_message('Distance from object is ' .. tostring(glue.round(playerState.distance)) .. ' units.')
                if (playerState.lockDistance) then
                    hud_message('Push n pull.')
                else
                    hud_message('Closer or further.')
                end
            end
        else
            -- Convert into monitor
            if (player.flashlightKey) then
                features.swapBiped()
            end

            if (player.actionKey and player.crouchHold) then
                cspawn_object('bipd', constants.bipeds.spartan, player.x, player.y, player.z)
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
                playerStore:dispatch({type = 'CREATE_AND_ATTACH_OBJECT', payload = {path = sceneryPath}})
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

function objectsReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        state = {}
    end
    if (action.type) then
        cprint('-> [Objects Store]')
        cprint(action.type, 'category')
    end
    if (action.type == constants.actionTypes.SPAWN_OBJECT) then
        cprint('SPAWNING object to store...', 'warning')
        local requestObject = action.payload.composedObject

        local tagPath = get_tag_path(requestObject.tagId)

        -- Get all the existent objects in the game before object spawn
        local objectsBeforeSpawn = get_objects()

        -- Spawn object in the game
        cspawn_object('scen', tagPath, requestObject.x, requestObject.y, requestObject.z)

        -- Get all the existent objects in the game after object spawn
        local objectsAfterSpawn = get_objects()

        -- Tricky way to get object local id, due to Chimera API returning a pointer instead of id
        -- Remember objectId is local to this server
        local localObjectId = glue.arraynv(objectsBeforeSpawn, objectsAfterSpawn)

        -- Clean and prepare entity
        requestObject.object = luablam.object(get_object(localObjectId))
        requestObject.tagId = nil
        requestObject.requestType = nil
        requestObject.objectId = localObjectId

        -- We are the server so the remote id is the local objectId
        if (server_type == 'local') then
            requestObject.remoteId = requestObject.objectId
        end

        cprint('localObjectId: ' .. requestObject.objectId)
        cprint('remoteId: ' .. requestObject.remoteId)

        -- TODO: Create a new object rather than passing it as "reference"
        local composedObject = requestObject

        -- Store the object in our state
        state[localObjectId] = composedObject

        return state
    elseif (action.type == constants.actionTypes.UPDATE_OBJECT) then
        local requestObject = action.payload.composedObject
        cprint(inspect(requestObject))

        local composedObject = state[getObjectIdByRemoteId(state, requestObject.objectId)]

        if (composedObject) then
            cprint('UPDATING object from store...', 'warning')
            composedObject.x = requestObject.x
            composedObject.y = requestObject.y
            composedObject.z = requestObject.z
            composedObject.yaw = requestObject.yaw
            composedObject.pitch = requestObject.pitch
            composedObject.roll = requestObject.roll
            if (composedObject.z < constants.minimumZSpawnPoint) then
                composedObject.z = constants.minimumZSpawnPoint
            end
            blam.object(
                get_object(composedObject.objectId),
                {x = composedObject.x, y = composedObject.y, z = composedObject.z}
            )
        else
            cprint('ERROR!!! The required object does not exist.', 'error')
        end
        cprint(inspect(composedObject))
        return state
    elseif (action.type == constants.actionTypes.DELETE_OBJECT) then
        local requestObject = action.payload.composedObject

        local composedObject = state[getObjectIdByRemoteId(state, requestObject.objectId)]

        if (composedObject) then
            cprint('Deleting object from store...', 'warning')
            delete_object(composedObject.objectId)
            state[getObjectIdByRemoteId(state, requestObject.objectId)] = nil
            cprint('Done.', 'success')
        else
            cprint('ERROR!!! The specified object does not exist.', 'error')
        end
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
                    slice = 0,
                    overflow = 0
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
        cprint('Forge Store, dispatched event:')
        cprint(action.type, 'category')
    end
    if (action.type == 'UPDATE_MAP_LIST') then
        state.mapsMenu.mapsList = action.payload.mapsList
        state.mapsMenu.currentMapsList = glue.chunks(state.mapsMenu.mapsList, 8)
        local totalPages = #state.mapsMenu.currentMapsList
        if (totalPages > 1) then
            local sidebarHeight = glue.floor(constants.maximumSidebarSize / totalPages)
            if (sidebarHeight < constants.minimumSidebarSize) then
                sidebarHeight = constants.minimumSidebarSize
            end
            local spaceLeft = constants.maximumSidebarSize - sidebarHeight
            state.mapsMenu.sidebar.slice = glue.round(spaceLeft / (totalPages - 1))
            local fullSize = sidebarHeight + (state.mapsMenu.sidebar.slice * (totalPages - 1))
            state.mapsMenu.sidebar.overflow = fullSize - constants.maximumSidebarSize
            state.mapsMenu.sidebar.height = sidebarHeight - state.mapsMenu.sidebar.overflow
        end
        cprint(inspect(state.mapsMenu))
        return state
    elseif (action.type == 'INCREMENT_MAPS_MENU_PAGE') then
        if (state.mapsMenu.currentPage < #state.mapsMenu.currentMapsList) then
            state.mapsMenu.currentPage = state.mapsMenu.currentPage + 1
            local newHeight = state.mapsMenu.sidebar.height + state.mapsMenu.sidebar.slice
            local newPosition = state.mapsMenu.sidebar.position + state.mapsMenu.sidebar.slice
            if (state.mapsMenu.currentPage == 3) then
                newHeight = newHeight + state.mapsMenu.sidebar.overflow
            end
            if (state.mapsMenu.currentPage == #state.mapsMenu.currentMapsList - 1) then
                newHeight = newHeight - state.mapsMenu.sidebar.overflow
            end
            state.mapsMenu.sidebar.height = newHeight
            state.mapsMenu.sidebar.position = newPosition
        end
        cprint(state.mapsMenu.currentPage)
        return state
    elseif (action.type == 'DECREMENT_MAPS_MENU_PAGE') then
        if (state.mapsMenu.currentPage > 1) then
            state.mapsMenu.currentPage = state.mapsMenu.currentPage - 1
            local newHeight = state.mapsMenu.sidebar.height - state.mapsMenu.sidebar.slice
            local newPosition = state.mapsMenu.sidebar.position - state.mapsMenu.sidebar.slice
            if (state.mapsMenu.currentPage == 2) then
                newHeight = newHeight - state.mapsMenu.sidebar.overflow
            end
            if (state.mapsMenu.currentPage == #state.mapsMenu.currentMapsList - 2) then
                newHeight = newHeight + state.mapsMenu.sidebar.overflow
            end
            state.mapsMenu.sidebar.height = newHeight
            state.mapsMenu.sidebar.position = newPosition
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

-- Create a request for an object action
---@param composedObject number
---@param requestType string
function createRequest(composedObject, requestType)
    local objectData = {}
    if (composedObject) then
        objectData.requestType = requestType
        if (requestType == constants.requestTypes.SPAWN_OBJECT) then
            objectData.tagId = composedObject.object.tagId
        elseif (requestType == constants.requestTypes.UPDATE_OBJECT) then
            objectData.objectId = composedObject.objectId
        elseif (requestType == constants.requestTypes.DELETE_OBJECT) then
            objectData.objectId = composedObject.objectId
            return objectData
        end
        objectData.x = composedObject.object.x
        objectData.y = composedObject.object.y
        objectData.z = composedObject.object.z
        objectData.yaw = composedObject.yaw
        objectData.pitch = composedObject.pitch
        objectData.roll = composedObject.roll
        return objectData
    end
    return nil
end

-- Send a request to the server throug rcon
---@param data table
---@return boolean success
---@return string request
function sendRequest(data)
    cprint(inspect(data))
    cprint('-> [ Sending request ]')
    local requestType = constants.requestTypes[data.requestType]
    if (requestType) then
        cprint('Type: ' .. requestType, 'category')
        local compressionFormat = constants.compressionFormats[requestType]

        if (not compressionFormat) then
            cprint('There is no format compression for this request!!!!', 'error')
            return false
        end

        cprint('Compression: ' .. inspect(compressionFormat))

        local requestObject = maethrillian.compressObject(data, compressionFormat, true)

        local requestOrder = constants.requestFormats[requestType]
        local request = maethrillian.convertObjectToRequest(requestObject, requestOrder)

        cprint('Request: ' .. request)
        if (server_type == 'local') then
            -- We need to mockup the server response in local mode
            local mockedResponse = string.gsub(string.gsub(request, "rcon forge '", ''), "'", '')
            onRcon(mockedResponse)
            return true, request
        else
            -- Player is connected to a server
            execute_script(request)
            return true, request
        end
    end
    cprint('Error at trying to send request!!!!', 'error')
    return false
end

function onRcon(message)
    cprint('Incoming rcon message:', 'warning')
    cprint(message)
    local request = string.gsub(message, "'", '')
    local splitData = glue.string.split(',', request)
    local requestType = constants.requestTypes[splitData[1]]
    if (requestType) then
        cprint('Decoding incoming ' .. requestType .. ' ...', 'warning')

        local requestObject = maethrillian.convertRequestToObject(request, constants.requestFormats[requestType])

        if (requestObject) then
            cprint('Done.', 'success')
        else
            cprint('Error at converting request.', 'error')
            return false, nil
        end

        cprint('Decompressing ...', 'warning')
        local compressionFormat = constants.compressionFormats[requestType]
        requestObject = maethrillian.decompressObject(requestObject, compressionFormat)

        if (requestObject) then
            cprint('Done.', 'success')
        else
            cprint('Error at decompressing request.', 'error')
            return false, nil
        end

        if (not ftestingMode) then
            objectsStore:dispatch({type = requestType, payload = {composedObject = requestObject}})
        end
        return false, requestObject
    end
    return true
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
        elseif (forgeCommand == 'ftest') then
            -- Run unit testing
            tests.run(true)
            return false
        elseif (forgeCommand == 'fprint') then
            -- Testing rcon communication
            cprint('[Game Objects]', 'category')
            cprint(inspect(get_objects()))
            cprint('[Objects Store]', 'category')
            cprint(inspect(glue.keys(objectsStore:getState())))
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

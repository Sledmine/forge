------------------------------------------------------------------------------
-- Forge Island Client Script
-- Author: Sledmine
-- Version: 3.1
-- Client side script for Forge Island
------------------------------------------------------------------------------

clua_version = 2.042

-- Common Lua libraries
local inspect = require 'inspect'
local json = require 'json'
-- TODO, pure Lua file system based on Windows dir and similar commands!!
local lfs = require 'lfs'
local glue = require 'glue'

-- Specific Halo Custom Edition libraries
local blam = require 'luablam'
local maethrillian = require 'maethrillian'

-- Default debug mode state
local debugMode = true

-- Internal functions
-- Super function to keep compatibility with SAPP and printing debug messages if needed
local function cprint(message)
    if (debugMode) then
        console_out(message)
    end
end

-- Global script variables
-- Object used to store data about the current scenery object attached to Monitor
local localScenery = {}

-- Like Redux we have some kind of store baby!! the rest is pure magic.
local objectsStore = {}

-- Just for local mode purposes
local playerLocalData = {}

-- Faster faster, this object contains info about the latest spawned object
local lastSpawnedObject = {}

-- Default rotation step, minimum default distance from an object, distance from object is blocked by default
local rotationStep = 3
local distance = 5
local blockDistance = true

-- Constants definition
local maximumProgressBarSize = 171
local minimumZSpawnPoint = -18.69

-- Reset all the global variables
local function flushScript()
    localScenery = {}
    objectsStore = {}
    playerLocalData = {}
    lastSpawnedObject = {}
    distance = 5
    blockDistance = true
end

-- Internal mod functions
local function getExistentObjects()
    local objectsList = {}
    for i = 0, 1023 do
        if (get_object(i)) then
            objectsList[#objectsList + 1] = i
        end
    end
    return objectsList
end

local function getObjectByServerId(objectId)
    for k, v in pairs(objectsStore) do
        if (v.serverId == objectId) then
            return k
        end
    end
    return nil
end

local function inSceneryList(tagId, objectList)
    for k, v in pairs(objectList) do
        if (get_tag_id('scen', v) == tagId) then
            return k
        end
    end
    return nil
end

local function rotate(X, Y, alpha)
    local c, s = math.cos(math.rad(alpha)), math.sin(math.rad(alpha))
    local t1, t2, t3 = X[1] * s, X[2] * s, X[3] * s
    X[1], X[2], X[3] = X[1] * c + Y[1] * s, X[2] * c + Y[2] * s, X[3] * c + Y[3] * s
    Y[1], Y[2], Y[3] = Y[1] * c - t1, Y[2] * c - t2, Y[3] * c - t3
end

local function convert(Yaw, Pitch, Roll)
    local F, L, T = {1, 0, 0}, {0, 1, 0}, {0, 0, 1}
    rotate(F, L, Yaw)
    rotate(F, T, Pitch)
    rotate(T, L, Roll)
    return {F[1], -L[1], -T[1], -F[3], L[3], T[3]}
end

-- Biped tag definitions
local bipeds = {
    monitor = '[shm]\\halo_4\\characters\\monitor\\monitor_mp',
    spartan = 'characters\\cyborg_mp\\cyborg_mp'
}

-- Weapon hud tag definitions
local weaponHudInterfaces = {
    forgeCrosshair = '[shm]\\halo_4\\ui\\hud\\forge'
}

-- Unicode string definitions
local unicodeStrings = {
    budgetCount = '[shm]\\halo_4\\ui\\shell\\forge_menu\\strings\\budget_count',
    elementsText = '[shm]\\halo_4\\ui\\shell\\forge_menu\\strings\\elements_text',
    pagination = '[shm]\\halo_4\\ui\\shell\\forge_menu\\strings\\pagination',
    mapList = '[shm]\\halo_4\\ui\\shell\\pause_game\\strings\\maps_name'
}

-- UI widget definitions
local widgetDefinitions = {
    amountBar = '[shm]\\halo_4\\ui\\shell\\forge_menu\\budget_dialog\\budget_progress_bar',
    categoryList = '[shm]\\halo_4\\ui\\shell\\forge_menu\\category_menu\\category_list',
    errorNonmodalFullscreen = 'ui\\shell\\error\\error_nonmodal_fullscreen'
}

-- Spawn objects definitions
local spawnObjects = {
    allGamesGenericSpawnPoint = '[shm]\\halo_4\\scenery\\spawning\\players\\all games\\generic spawn point\\generic spawn point',
    ctfSpawnPointBlueTeam = '[shm]\\halo_4\\scenery\\spawning\\players\\ctf\\ctf spawn point blue team\\ctf spawn point blue team',
    ctfSpawnPointReadTeam = '[shm]\\halo_4\\scenery\\spawning\\players\\ctf\\ctf spawn point red team\\ctf spawn point red team',
    slayerSpawnPointBlueTeam = '[shm]\\halo_4\\scenery\\spawning\\players\\slayer\\slayer spawn point blue team\\slayer spawn point blue team',
    bansheeSpawn = '[shm]\\halo_4\\scenery\\spawning\\vehicles\\banshee spawn\\banshee spawn',
    warthogSpawn = '[shm]\\halo_4\\scenery\\spawning\\vehicles\\warthog spawn\\warthog spawn',
    ghostSpawn = '[shm]\\halo_4\\scenery\\spawning\\vehicles\\ghost spawn\\ghost spawn',
    scorpionSpawn = '[shm]\\halo_4\\scenery\\spawning\\vehicles\\scorpion spawn\\scorpion spawn',
    cTurretSpawn = '[shm]\\halo_4\\scenery\\spawning\\vehicles\\c turret spawn\\c turret spawn'
}

local spawnValues = {
    -- CTF, Blue Team
    ctfSpawnPointBlueTeam = {type = 1, team = 1},
    -- CTF, Red Team
    ctfSpawnPointReadTeam = {type = 1, team = 0},
    -- Generic, Both teams
    slayerSpawnPointBlueTeam = {type = 3, team = 0},
    -- Generic, Both teams
    allGamesGenericSpawnPoint = {type = 12, team = 0},
    bansheeSpawn = {type = 0},
    warthogSpawn = {type = 1},
    ghostSpawn = {type = 2},
    scorpionSpawn = {type = 3},
    cTurretSpawn = {type = 4}
}

-- Changes default crosshair values
local function setCrosshairState(state)
    local forgeCrosshairAddress = get_tag('weapon_hud_interface', weaponHudInterfaces.forgeCrosshair)
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

-- Intercept button signal sent from UI
local function forgeMenuHandle()
    local buttons = 9
    local restoreButtonStates = (function()
        for i = 1, buttons do
            execute_script('set button_' .. i .. ' false')
        end
    end)
    for i = 1, buttons do
        if (get_global('button_' .. i)) then
            cprint('Button ' .. i .. ' was intercepted.')
            restoreButtonStates()
            return i
        end
    end
    return 0
end

local function resetSpawnPoints()
    local scenario = blam.scenario(get_tag(0))

    local mapSpawnCount = scenario.spawnLocationCount
    local vehicleLocationCount = scenario.vehicleLocationCount

    cprint('Found ' .. mapSpawnCount .. ' stock player starting points!')
    cprint('Found ' .. vehicleLocationCount .. ' stock vehicle location points!')
    local mapSpawnPoints = scenario.spawnLocationList
    -- Reset any spawn point, except the first one
    for i = 1, mapSpawnCount do
        -- Disable them by setting type to 0
        mapSpawnPoints[i].type = 0
    end
    local vehicleLocationList = scenario.vehicleLocationList
    for i = 2, vehicleLocationCount do
        vehicleLocationList[i].type = 65535
        execute_script('object_destroy v' .. vehicleLocationList[i].nameIndex)
    end
    blam.scenario(get_tag(0), {spawnLocationList = mapSpawnPoints, vehicleLocationList = vehicleLocationList})
end

--[[
        0 = none
        1 = ctf
        2 = slayer
        3 = oddball
        4 = king of the hill
        5 = race
        6 = terminator
        12 = all games
        13 = all except ctf
        14 = all except race and ctf
    ]]
-- Must be called after adding scenery object to the store!!
-- @return true if found an available spawn
local function createSpawnPoint(objectLocalId, spawnType, teamIndex)
    local scenario = blam.scenario(get_tag(0))
    local mapSpawnCount = scenario.spawnLocationCount
    local mapSpawnPoints = scenario.spawnLocationList

    local spawnObject = objectsStore[objectLocalId]
    -- Object exists, it's synced
    if (spawnObject) then
        if (not spawnObject.reflectedSpawn) then
            for i = 1, mapSpawnCount do
                if (mapSpawnPoints[i].type == 0) then
                    -- Replace spawn point values
                    mapSpawnPoints[i].x = spawnObject.x
                    mapSpawnPoints[i].y = spawnObject.y
                    mapSpawnPoints[i].z = spawnObject.z
                    mapSpawnPoints[i].rotation = math.rad(spawnObject.yaw)
                    mapSpawnPoints[i].teamIndex = teamIndex
                    mapSpawnPoints[i].type = spawnType

                    -- Debug spawn index
                    cprint('Creating spawn replacing index: ' .. i)
                    spawnObject.reflectedSpawn = i

                    -- Stop looking for "available" spawn slots
                    break
                end
            end
        else
            -- Replace spawn point values
            mapSpawnPoints[spawnObject.reflectedSpawn].x = spawnObject.x
            mapSpawnPoints[spawnObject.reflectedSpawn].y = spawnObject.y
            mapSpawnPoints[spawnObject.reflectedSpawn].z = spawnObject.z
            mapSpawnPoints[spawnObject.reflectedSpawn].rotation = math.rad(spawnObject.yaw)
            cprint(mapSpawnPoints[spawnObject.reflectedSpawn].type)
            -- Debug spawn index
            cprint('Updating spawn replacing index: ' .. spawnObject.reflectedSpawn)
        end
        -- Update spawn point list
        blam.scenario(get_tag(0), {spawnLocationList = mapSpawnPoints})
        return true
    end
    return false
end

-- Must be called before deleting scenery object from the store!!
-- @return true if spawn has been deleted
local function deleteSpawnPoint(objectLocalId)
    local scenario = blam.scenario(get_tag(0))
    local mapSpawnCount = scenario.spawnLocationCount
    cprint(mapSpawnCount)
    local mapSpawnPoints = scenario.spawnLocationList

    local spawnObject = objectsStore[objectLocalId]
    -- Object exists, it's synced
    if (spawnObject and spawnObject.reflectedSpawn) then
        if (mapSpawnPoints[spawnObject.reflectedSpawn]) then
            -- Disable or "delete" spawn point by setting type as 0
            mapSpawnPoints[spawnObject.reflectedSpawn].type = 0

            -- Update spawn point list
            blam.scenario(get_tag(0), {spawnLocationList = mapSpawnPoints})

            -- Debug spawn index
            cprint('Deleting spawn replacing index: ' .. spawnObject.reflectedSpawn)
            return true
        end
    end
    return false
end

--[[
    0 = banshee
    1 = warthog
]]
-- Must be called after adding scenery object to the store!!
-- @return true if found an available spawn
local function createVehicleSpawnPoint(objectLocalId, vehicleType)
    -- Get all the scenario data
    local scenario = blam.scenario(get_tag(0))
    local vehicleLocationCount = scenario.vehicleLocationCount
    cprint('Maximum count of vehicle spawn points: ' .. vehicleLocationCount)
    local vehicleLocationList = scenario.vehicleLocationList

    -- Get all the incoming object data
    local spawnObject = objectsStore[objectLocalId]
    -- Object exists, it's synced
    if (spawnObject) then
        if (not spawnObject.reflectedSpawn) then
            for i = 2, vehicleLocationCount do
                if (vehicleLocationList[i].type == 65535) then
                    -- Replace spawn point values
                    vehicleLocationList[i].x = spawnObject.x
                    vehicleLocationList[i].y = spawnObject.y
                    vehicleLocationList[i].z = spawnObject.z
                    vehicleLocationList[i].yaw = math.rad(spawnObject.yaw)
                    vehicleLocationList[i].pitch = math.rad(spawnObject.pitch)
                    vehicleLocationList[i].roll = math.rad(spawnObject.roll)

                    vehicleLocationList[i].type = vehicleType

                    -- Debug spawn index
                    cprint('Creating spawn replacing index: ' .. i)
                    spawnObject.reflectedSpawn = i

                    -- Update spawn point list
                    blam.scenario(get_tag(0), {vehicleLocationList = vehicleLocationList})

                    execute_script('object_create_anew v' .. vehicleLocationList[i].nameIndex)
                    -- Stop looking for "available" spawn slots
                    break
                end
            end
        else
            -- Replace spawn point values
            vehicleLocationList[spawnObject.reflectedSpawn].x = spawnObject.x
            vehicleLocationList[spawnObject.reflectedSpawn].y = spawnObject.y
            vehicleLocationList[spawnObject.reflectedSpawn].z = spawnObject.z
            vehicleLocationList[spawnObject.reflectedSpawn].yaw = math.rad(spawnObject.yaw)
            vehicleLocationList[spawnObject.reflectedSpawn].pitch = math.rad(spawnObject.pitch)
            vehicleLocationList[spawnObject.reflectedSpawn].roll = math.rad(spawnObject.roll)

            -- REMINDER!!! Check vehicle rotation

            -- Debug spawn index
            cprint('Updating spawn replacing index: ' .. spawnObject.reflectedSpawn)

            -- Update spawn point list
            blam.scenario(get_tag(0), {vehicleLocationList = vehicleLocationList})
        end
        return true
    end
    return false
end

-- Must be called before deleting scenery object from the store!!
-- @return true if spawn has been deleted
local function deleteVehicleSpawnPoint(objectLocalId)
    local scenario = blam.scenario(get_tag(0))
    local vehicleLocationCount = scenario.vehicleLocationCount
    local vehicleLocationList = scenario.vehicleLocationList

    local spawnObject = objectsStore[objectLocalId]
    -- Object exists, it's synced
    if (spawnObject and spawnObject.reflectedSpawn) then
        if (vehicleLocationList[spawnObject.reflectedSpawn]) then
            -- Disable or "delete" spawn point by setting type as 0
            vehicleLocationList[spawnObject.reflectedSpawn].type = 65535

            -- Update spawn point list
            blam.scenario(get_tag(0), {vehicleLocationList = vehicleLocationList})

            execute_script('object_destroy v' .. vehicleLocationList[spawnObject.reflectedSpawn].nameIndex)

            -- Debug spawn index
            cprint('Deleting spawn replacing index: ' .. spawnObject.reflectedSpawn)
            return true
        end
    end
    return false
end

-- Update the amount of budget used per scenery object
local function updateBudgetCount()
    local sceneryCount = 0
    for i = 1, 1023 do
        local tempObject = blam.object(get_object(i))

        -- If object exists and is a scenery object
        if (tempObject and tempObject.type == 6) then
            sceneryCount = sceneryCount + 1
        end
    end

    local budgetUsed = (sceneryCount * 50)

    local currentProgressBarSize = glue.round(budgetUsed * maximumProgressBarSize / 10000)
    cprint('Budget Used: ' .. budgetUsed)

    -- Update unicode string with current budget value
    local budgetCountAddress = get_tag('unicode_string_list', unicodeStrings.budgetCount)
    blam.unicodeStringList(budgetCountAddress, {stringList = {tostring(budgetUsed)}})
    local budgetCount = blam.unicodeStringList(budgetCountAddress)

    -- Update unicode string with current budget value
    local amountBarAddress = get_tag('ui_widget_definition', widgetDefinitions.amountBar)
    local amountBar = blam.uiWidgetDefinition(amountBarAddress)
    blam.uiWidgetDefinition(amountBarAddress, {width = currentProgressBarSize})
end

-- Look into game script globals for a hooked UI events
local function UIWidgetsHooks()
    if (get_global('forced_render')) then
        cprint('Stopping FORCED UI re-render!')
        blam.uiWidgetDefinition(get_tag('ui_widget_definition', widgetDefinitions.categoryList), {eventType = 32})
        execute_script('set forced_render false')
    end
    if (get_global('forced_close')) then
        cprint('Stopping FORCED widget close!')
        blam.uiWidgetDefinition(
            get_tag('ui_widget_definition', widgetDefinitions.errorNonmodalFullscreen),
            {eventType = 32}
        )
        execute_script('set forced_close false')
    end
end

-- Load into UI the list of all available sceneries/forge objects to spawn
local function updateForgeMenu(element)
    -- Create an object with all the data of the main scenario in the map
    local scenario = blam.scenario(get_tag(0))

    -- List used to save all the sceneries in the scenario with their respective paths to spawn
    --[[
		Example:
		["barricade large"] = [shm]\halo_4\scenery\barricades\barricade large\barricade large
		["tree small"] = [shm]\halo_4\scenery\structures\natural\tree small\tree small
	]]
    local sceneryDatabase = {}

    -- Object used to store all the objects and their categories as childs/properties
    --[[
		Example:
		["barricade large"] = [shm]\halo_4\scenery\barricades\barricade large\barricade large
		["tree small"] = [shm]\halo_4\scenery\structures\natural\tree small\tree small
	]]
    local availableObjects = {root = {}}

    -- Iterate over all the sceneries available in the map scenario
    for i = 1, #scenario.sceneryPaletteList do
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
        sceneryDatabase[sceneriesSplit[#sceneriesSplit]] = sceneryPath
        -- Set first level as the root of available current objects
        -- THIS IS CALLED BY REFERENCE TO MODIFºY availableObjects
        local treePosition = availableObjects.root
        for k, v in pairs(sceneriesSplit) do
            if (not treePosition[v]) then
                treePosition[v] = {}
            end
            treePosition = treePosition[v]
        end
    end
    cprint('Scenery database has ' .. #glue.keys(sceneryDatabase) .. ' objects.')
    local elementsTextAddress = get_tag('unicode_string_list', unicodeStrings.elementsText)
    local elementsText = blam.unicodeStringList(elementsTextAddress)
    local function updatePages(current, last)
        local paginationTextAddress = get_tag('unicode_string_list', unicodeStrings.pagination)
        if (paginationTextAddress) then
            local pagination = blam.unicodeStringList(paginationTextAddress)
            local paginationStringList = pagination.stringList
            paginationStringList[2] = tostring(current)
            paginationStringList[4] = tostring(last)
            blam.unicodeStringList(paginationTextAddress, {stringList = paginationStringList})
        end
    end
    local function writeMenuList(menuElements, page)
        -- Sort all the elements in the menu
        table.sort(
            menuElements,
            function(a, b)
                return a < b
            end
        )
        if (#menuElements > 0) then
            -- Always set maximum widgets as the same of the elements of the menu
            cprint('Current elements in the list: ' .. #menuElements)
            local newChildWidgetsCount = #menuElements

            -- Split all the elements in the list into chunks of 6 elements
            local newMenuElements = glue.chunks(menuElements, 6)

            local lastPage = #newMenuElements

            cprint('Current page: ' .. page)
            currentPage = page

            -- Update the pages in the current number of pages
            updatePages(page, lastPage)

            -- Maximum amount of pages has been reached, create a new page
            if (newChildWidgetsCount > 6) then
                pagination = {list = menuElements, lastPage = lastPage}

                -- Set widget count to 6 elements plus 2 buttons for page navigation
                newChildWidgetsCount = #newMenuElements[page]

                -- Create a new page for the
                -- cprint('Maximum elements per page, splitting elements into pages.')
                cprint('New number of pages: ' .. #newMenuElements)
            else
                pagination = nil
            end

            -- Update elements list
            blam.unicodeStringList(elementsTextAddress, {stringList = newMenuElements[page]})

            -- We update the quantity of elements in the menu
            -- A new event type is replaced for this widget to force a new render on it
            blam.uiWidgetDefinition(
                get_tag('ui_widget_definition', widgetDefinitions.categoryList),
                {
                    childWidgetsCount = newChildWidgetsCount + 2,
                    eventType = 33
                }
            )
        end
    end
    local newElements
    if (element == 0) then
        -- Get back in to the page list
        newElements = glue.keys(availableObjects.root)
        writeMenuList(newElements, 1)
    elseif (element == 7) then
        -- Get forward in to the page list
        if (pagination) then
            if (currentPage > 1) then
                currentPage = currentPage - 1
            end
            writeMenuList(pagination.list, currentPage)
        end
        cprint('There ARE NOT PAGES TO SHOW!')
    elseif (element == 8) then
        if (pagination) then
            if (currentPage < pagination.lastPage) then
                currentPage = currentPage + 1
            end
            writeMenuList(pagination.list, currentPage)
        end
        cprint('There ARE NOT PAGES TO SHOW!')
    elseif (element == 9) then
        if (lastElement) then
            cprint('Trying to get back in the menu!!!')
            local parent = glue.parentByChild(availableObjects, lastElement)
            if (parent) then
                lastElement = parent
                cprint('Children found in parent: ' .. parent)
                newElements = glue.keys(glue.childsByParent(availableObjects, parent))
                writeMenuList(newElements, 1)
                return nil
            end
        end
        cprint('Trying to close the menu!!!')
        blam.uiWidgetDefinition(
            get_tag('ui_widget_definition', widgetDefinitions.errorNonmodalFullscreen),
            {eventType = 33}
        )
    else
        cprint('Trying to get an object from the selected menu')
        local desiredElement = elementsText.stringList[element]
        -- Selected element is a scenery object
        if (sceneryDatabase[desiredElement]) then
            cprint('You selected a scenery!!')
            -- Close menu
            blam.uiWidgetDefinition(
                get_tag('ui_widget_definition', widgetDefinitions.errorNonmodalFullscreen),
                {eventType = 33}
            )
            return sceneryDatabase[desiredElement]
        else
            -- Selected element is a category
            cprint('You are opening a category!!')
            local elementsList = glue.childsByParent(availableObjects, desiredElement)
            if (elementsList) then
                lastElement = desiredElement
                newElements = glue.keys(elementsList)
                writeMenuList(newElements, 1)
            end
        end
    end
    return nil
end

-- Self explanatory
local function openForgeMenu()
    -- Reset pagination
    pagination = nil
    updateForgeMenu(0)
    execute_script('multiplayer_map_name letsforge')
    execute_script('multiplayer_map_name ' .. map)
end

-- Check if current player is using a monitor biped
local function isPlayerMonitor(playerAddress)
    local tempObject = blam.object(playerAddress)
    if (tempObject and tempObject.tagId == get_tag_id('bipd', bipeds.monitor)) then
        return true
    end
    return false
end

-- Rotate object into desired degrees
local function rotateObject(objectId, yaw, pitch, roll)
    if (yaw > 360) then
        yaw = 0
    elseif (yaw < 0) then
        yaw = 360
    end
    if (pitch > 360) then
        pitch = 0
    elseif (pitch < 0) then
        pitch = 360
    end
    if (roll > 360) then
        roll = 0
    elseif (roll < 0) then
        roll = 360
    end
    -- We are rotating local object
    if (localScenery.id and localScenery.id == objectId) then
        localScenery.yaw = yaw
        localScenery.pitch = pitch
        localScenery.roll = roll
    end
    local rotation = convert(yaw, pitch, roll)
    blam.object(
        get_object(objectId),
        {
            pitch = rotation[1],
            yaw = rotation[2],
            roll = rotation[3],
            xScale = rotation[4],
            yScale = rotation[5],
            zScale = rotation[6]
        }
    )
end

-- Prepare local function to update rotation of local scenery object
local function updateRotation(rate)
    -- Rotation orientation control
    if (localScenery.desiredRotation == 1) then
        -- Yaw +
        localScenery.yaw = localScenery.yaw + rate
    elseif (localScenery.desiredRotation == 2) then
        -- Yaw -
        localScenery.yaw = localScenery.yaw - rate
    end

    if (localScenery.desiredRotation == 3) then
        -- Pitch +
        localScenery.pitch = localScenery.pitch + rate
    elseif (localScenery.desiredRotation == 4) then
        -- Pitch -
        localScenery.pitch = localScenery.pitch - rate
    end

    if (localScenery.desiredRotation == 5) then
        -- Roll +
        localScenery.roll = localScenery.roll + rate
    elseif (localScenery.desiredRotation == 6) then
        -- Roll -
        localScenery.roll = localScenery.roll - rate
    end

    -- Update object rotation values
    rotateObject(localScenery.id, localScenery.yaw, localScenery.pitch, localScenery.roll)

    -- Print current rotation degrees
    hud_message(localScenery.yaw .. ' ' .. localScenery.pitch .. ' ' .. localScenery.roll)
end

-- Attach any previously spawned object to local player
local function attachObjectToPlayer(objectId)
    local previousObjectData = objectsStore[objectId]
    if (previousObjectData) then
        cprint('Object attached has previous spawned data!!!!')
        cprint('serverId: ' .. previousObjectData.serverId)
        cprint('yaw: ' .. previousObjectData.yaw)
        cprint('pitch: ' .. previousObjectData.pitch)
        cprint('roll: ' .. previousObjectData.roll)
        localScenery.id = objectId
        localScenery.object = blam.object(get_object(localScenery.id))
        localScenery.desiredRotation = 1
        localScenery.yaw = previousObjectData.yaw
        localScenery.pitch = previousObjectData.pitch
        localScenery.roll = previousObjectData.roll
    else
        cprint('Object attached is a new object!!!!')
        localScenery.id = objectId
        localScenery.object = blam.object(get_object(localScenery.id))
        localScenery.desiredRotation = 1
        localScenery.yaw = 0
        localScenery.pitch = 0
        localScenery.roll = 0
        updateRotation(0)
    end
end

-- Detach any previously spawned object to local player
local function detachObjectToPlayer(erase)
    if (erase and localScenery.id) then
        if (not objectsStore[localScenery.id]) then
            if (get_object(localScenery.id)) then
                delete_object(localScenery.id)
            end
        end
    end
    localScenery = {}
end

-- Avoid other objects to be highlighted
local function unhighlightObjects()
    for objectLocalId, composedObject in pairs(objectsStore) do
        local objectAddress = get_object(objectLocalId)
        local tempObject = blam.object(objectAddress)
        if (tempObject) then
            -- If object is an scenery
            if (tempObject.type == 6) then
                blam.object(get_object(objectLocalId), {health = 0})
            end
        end
    end
end

-- Swap between monitor and spartan
local function swapForgeBiped()
    unhighlightObjects()
    if (server_type == 'local') then
        setCrosshairState(-1)
        detachObjectToPlayer(true)
        -- Needs kinda refactoring, probably splitting this into LuaBlam
        local globalsTagAddress = get_tag('matg', 'globals\\globals')
        local globalsTagData = read_dword(globalsTagAddress + 0x14)
        local globalsTagMultiplayerBipedTagIdAddress = globalsTagData + 0x9BC + 0xC
        local currentGlobalsBipedTagId = read_dword(globalsTagMultiplayerBipedTagIdAddress)
        cprint('Globals Biped ID: ' .. currentGlobalsBipedTagId)
        for i = 0, 1023 do
            local tempObject = blam.object(get_object(i))
            if (tempObject and tempObject.tagId == get_tag_id('bipd', bipeds.spartan)) then
                playerLocalData.x = tempObject.x
                playerLocalData.y = tempObject.y
                playerLocalData.z = tempObject.z
                write_dword(globalsTagMultiplayerBipedTagIdAddress, get_tag_id('bipd', bipeds.monitor))
                delete_object(i)
            elseif (tempObject and tempObject.tagId == get_tag_id('bipd', bipeds.monitor)) then
                playerLocalData.x = tempObject.x
                playerLocalData.y = tempObject.y
                playerLocalData.z = tempObject.z
                write_dword(globalsTagMultiplayerBipedTagIdAddress, get_tag_id('bipd', bipeds.spartan))
                delete_object(i)
            end
        end
    else
        execute_script('rcon forge #b')
    end
end

-- Spawn object with specific properties and sync it
local function spawnLocalObject(objectProperties)
    cprint('Trying to spawn object with tag id: ' .. objectProperties.tagId)

    -- Fix Z value if object is trying to spawn inside bsp
    local fixedZ = objectProperties.z
    if (fixedZ < minimumZSpawnPoint) then
        fixedZ = minimumZSpawnPoint
    end

    -- Get tag path of the incoming object
    local tagPath = get_tag_path(objectProperties.tagId)

    -- Get current objects
    local objectsBeforeSpawn = getExistentObjects()

    -- Executing new object spawn, TODO: add automatic tag type detection (?)
    spawn_object('scen', tagPath, objectProperties.x, objectProperties.y, fixedZ)

    -- Getting new objects after object spawn action
    local objectsAfterSpawn = getExistentObjects()

    -- Compare previous and new objects and retreive the new one
    -- This is needed because Chimera API returns a different object id than the ones Halo is tracking
    local objectLocalId = glue.arraynv(objectsBeforeSpawn, objectsAfterSpawn)
    if (objectLocalId) then
        -- If spawn is in local mode, then serverId is the same as localId
        if (not objectProperties.serverId) then
            objectProperties.serverId = objectLocalId
        end

        -- Update object Z
        blam.object(get_object(objectLocalId), {z = objectProperties.z})

        -- Update object rotation
        rotateObject(objectLocalId, objectProperties.yaw, objectProperties.pitch, objectProperties.roll)

        -- Sync object with store
        objectsStore[objectLocalId] = objectProperties

        -- Update budget count
        updateBudgetCount()

        -- Reflect spawnpoints
        local objectName = inSceneryList(objectProperties.tagId, spawnObjects)
        if (objectName) then
            cprint(objectName)
            if (objectName:find('SpawnPoint')) then
                local spawnData = spawnValues[objectName]
                -- We are trying to create a player spawn point
                if (not createSpawnPoint(objectLocalId, spawnData.type, spawnData.team)) then
                    cprint('ERROR!!: Spawn point with id: ' .. objectLocalId .. " can't be CREATED!!")
                end
            else
                -- We are trying to create vehicle spawn point
                if (server_type == 'local') then
                    createVehicleSpawnPoint(objectLocalId, spawnValues[objectName].type)
                end
            end
        end

        cprint('Object succesfully spawned with id: ' .. objectLocalId)
    else
        cprint('Error at trying to spawn object!!!')
    end
end

-- Update already existing object
local function updateLocalObject(objectProperties)
    cprint('Trying to update object with server id: ' .. objectProperties.serverId)

    -- Look into local objectsStore for the equivalent one in the server
    local objectLocalId = getObjectByServerId(objectProperties.serverId)
    if (objectLocalId) then
        -- Sync object with store
        objectsStore[objectLocalId].yaw = objectProperties.yaw
        objectsStore[objectLocalId].pitch = objectProperties.pitch
        objectsStore[objectLocalId].roll = objectProperties.roll
        objectsStore[objectLocalId].x = objectProperties.x
        objectsStore[objectLocalId].y = objectProperties.y
        objectsStore[objectLocalId].z = objectProperties.z

        -- Update object position
        blam.object(
            get_object(objectLocalId),
            {
                x = objectProperties.x,
                y = objectProperties.y,
                z = objectProperties.z
            }
        )

        -- Update object rotation
        rotateObject(objectLocalId, objectProperties.yaw, objectProperties.pitch, objectProperties.roll)

        -- Update budget count
        updateBudgetCount()

        -- Get tag properties
        local tempObject = blam.object(get_object(objectLocalId))

        -- Reflect spawnpoints
        local objectName = inSceneryList(tempObject.tagId, spawnObjects)
        if (objectName) then
            if (objectName:find('SpawnPoint')) then
                local spawnData = spawnValues[objectName]
                -- We are trying to UPDATE a player spawn point
                if (not createSpawnPoint(objectLocalId)) then
                    cprint('ERROR!!: Spawn point with id: ' .. objectLocalId .. " can't be UPDATED!!")
                end
            else
                -- We are trying to UPDATE vehicle spawn point
                if (server_type == 'local') then
                    createVehicleSpawnPoint(objectLocalId)
                end
            end
        end
        cprint('Object succesfully updated with local id: ' .. objectLocalId)
    else
        cprint('Error at trying to update object!!!')
    end
end

local function flushForge()
    resetSpawnPoints()
    cprint('FLUSHING ALL THE FORGE STUFFFFFFFFFF')
    for k, v in pairs(objectsStore) do
        if (get_object(k)) then
            delete_object(k)
        end
    end
    objectsStore = {}
end

-- Decode incoming data from the rcon messages
function decodeIncomingData(data)
    cprint('Incoming rcon message: ' .. data)
    data = string.gsub(data, "'", '')
    local splittedData = glue.string.split(',', data)
    local command = splittedData[1]
    if (command == '#s') then
        cprint('Decoding incoming object spawn...')
        cprint(inspect(splittedData))
        local objectProperties = {}
        objectProperties.tagId = string.unpack('I4', glue.fromhex(splittedData[2]))
        objectProperties.x = string.unpack('f', glue.fromhex(splittedData[3]))
        objectProperties.y = string.unpack('f', glue.fromhex(splittedData[4]))
        objectProperties.z = string.unpack('f', glue.fromhex(splittedData[5]))
        objectProperties.yaw = tonumber(splittedData[6])
        objectProperties.pitch = tonumber(splittedData[7])
        objectProperties.roll = tonumber(splittedData[8])
        if (splittedData[9]) then
            objectProperties.serverId = string.unpack('I4', glue.fromhex(splittedData[9]))
        end
        for property, value in pairs(objectProperties) do -- Evaluate all the data
            if (not value) then
                cprint('Incoming object data is in a WRONG format!!!')
                return false
            end
        end
        cprint('Object spawn succesfully decoded!')
        spawnLocalObject(objectProperties)
        return false
    elseif (command == '#u') then
        cprint('Decoding incoming object update...')
        cprint(inspect(splittedData))
        local objectProperties = {}
        objectProperties.serverId = string.unpack('I4', glue.fromhex(splittedData[2]))
        objectProperties.x = string.unpack('f', glue.fromhex(splittedData[3]))
        objectProperties.y = string.unpack('f', glue.fromhex(splittedData[4]))
        objectProperties.z = string.unpack('f', glue.fromhex(splittedData[5]))
        objectProperties.yaw = tonumber(splittedData[6])
        objectProperties.pitch = tonumber(splittedData[7])
        objectProperties.roll = tonumber(splittedData[8])
        for property, value in pairs(objectProperties) do -- Evaluate all the data
            if (not value) then
                cprint('Incoming object data is in a WRONG format!!!')
                return false
            else
                cprint(property .. ' ' .. value)
            end
        end
        cprint('Object update succesfully decoded!')
        updateLocalObject(objectProperties)
        return false
    elseif (command == '#d') then
        cprint('Decoding incoming object deletion...')

        local objectServerId = tonumber(splittedData[2])

        -- There is an object with the required id
        if (objectServerId) then
            -- Get local object id by server id
            local objectLocalId = getObjectByServerId(objectServerId)

            -- Object exists and it's a synced object
            if (objectLocalId and get_object(objectLocalId)) then
                cprint('Deleting object with id: ' .. objectLocalId)

                -- Get object properties
                local tempObject = blam.object(get_object(objectLocalId))

                -- Reflect spawn points
                local objectName = inSceneryList(tempObject.tagId, spawnObjects)
                if (objectName) then
                    if (objectName:find('SpawnPoint')) then
                        if (not deleteSpawnPoint(objectLocalId)) then
                            cprint('ERROR!: Spawn point with id:' .. objectLocalId .. ' can not be DELETED!!!')
                        end
                    else
                        if (server_type == 'local') then
                            deleteVehicleSpawnPoint(objectLocalId)
                        end
                    end
                end

                -- Erase the object from the game memory
                delete_object(objectLocalId)

                -- Erase the object from objects store
                objectsStore[objectLocalId] = nil

                -- Update global budget count
                updateBudgetCount()
            else
                console_out('Error at trying to erase object with serverId: ' .. objectServerId)
            end
        else
            cprint('Incoming object data is in a WRONG format!!!')
        end
        return false
    elseif (command == '#fo') then
        flushForge()
        return false
    end
    return true
end

-- Send an object spawn request to the server
local function sendObjectSpawn(composedObject)
    local object = composedObject.object
    if (not object) then
        object = blam.object(get_object(composedObject.id))
    end
    if (object) then
        detachObjectToPlayer(true)
        cprint('Sending object spawn request... for tagId: ' .. object.tagId)
        local objectSpawnData = {
            {value = object.tagId, compression = 'I4'},
            {value = object.x, compression = 'f'},
            {value = object.y, compression = 'f'},
            {value = object.z, compression = 'f'},
            {value = composedObject.yaw},
            {value = composedObject.pitch},
            {value = composedObject.roll}
        }
        -- Data compression process
        local compressedData = maethrillian.compress(objectSpawnData)

        -- Object spawn request structure, using compressed data
        local request = "rcon forge '#s," .. maethrillian.convertDataToRequest(compressedData) .. "'"

        -- Debug request format
        cprint(inspect(request))
        cprint('Request size: ' .. #request - 11)
        if (server_type ~= 'local') then
            -- Player is connected to a server
            execute_script(request)
        else
            -- Mockup server response in local mode
            decodeIncomingData(string.gsub(string.gsub(request, "rcon forge '", ''), "'", ''))
        end
    else
        cprint('ERROR!!!: At trying to send object spawn!')
    end
end

-- Send an object update request to the server
local function sendObjectUpdate(composedObject)
    local object = blam.object(get_object(composedObject.id))
    if (object) then
        detachObjectToPlayer(true)
        cprint('Sending object update request... for serverId: ' .. composedObject.serverId)
        local objectUpdateData = {
            {value = composedObject.serverId, compression = 'I4'},
            {value = object.x, compression = 'f'},
            {value = object.y, compression = 'f'},
            {value = object.z, compression = 'f'},
            {value = composedObject.yaw},
            {value = composedObject.pitch},
            {value = composedObject.roll}
        }
        -- Data compression process
        local compressedData = maethrillian.compress(objectUpdateData)

        -- Object update request structure, using compressed data
        local request = "rcon forge '#u," .. maethrillian.convertDataToRequest(compressedData) .. "'"

        -- Debug request format
        cprint(inspect(request))
        cprint('Request size: ' .. #request - 11)
        if (server_type ~= 'local') then
            -- Player is connected to a server
            execute_script(request)
        else
            -- Mockup server response in local mode
            decodeIncomingData(string.gsub(string.gsub(request, "rcon forge '", ''), "'", ''))
        end
    end
end

-- Send an object delete request to the server
local function sendObjectDelete(composedObject)
    local object = get_object(composedObject.id)
    if (object) then
        cprint(
            'Sending object deletion request... for objectId: ' ..
                composedObject.id .. ', serverId: ' .. objectsStore[composedObject.id].serverId
        )
        local request = "rcon forge '#d," .. objectsStore[composedObject.id].serverId .. "'" -- Spawn format
        if (server_type ~= 'local') then
            -- Player is connected to a server
            execute_script(request)
        else
            -- Mockup server response in local mode
            decodeIncomingData(string.gsub(string.gsub(request, "rcon forge '", ''), "'", ''))
        end
    end
end

-- Execute code here on every game tick, in other words, where the magic happens.... tiling!
function onTick()
    UIWidgetsHooks()
    local playerBipedAddress = get_dynamic_player()
    if (playerBipedAddress) then
        local player = blam.biped(playerBipedAddress)
        -- Player exists and is in monitor/forge mode
        if (player and isPlayerMonitor(playerBipedAddress)) then
            if (playerLocalData.x) then
                blam.biped(
                    playerBipedAddress,
                    {
                        x = playerLocalData.x,
                        y = playerLocalData.y,
                        z = playerLocalData.z + 0.5
                    }
                )
                playerLocalData = {}
            end
            if (player.meleeKey) then
                blockDistance = not blockDistance
                hud_message('Distance from object is ' .. tostring(glue.round(distance)) .. ' units.')
                if (blockDistance) then
                    hud_message('Push n pull.')
                else
                    hud_message('Closer or further.')
                end
            end
            if (localScenery and localScenery.object) then -- Player has a scenery attached to it
                -- Player doesn't have a scenery attached
                -- Calculate distance between player and localScenery
                if (not blockDistance) then
                    distance =
                        math.sqrt(
                        (localScenery.object.x - player.x) ^ 2 + (localScenery.object.y - player.y) ^ 2 +
                            (localScenery.object.z - player.z) ^ 2
                    )
                end

                -- Prevent distance from being really short
                if (distance < 1.5) then
                    distance = 1.5
                end

                -- Get offset from player view to attach object position
                local xOffset = player.x + player.cameraX * distance
                local yOffset = player.y + player.cameraY * distance
                local zOffset = player.z + player.cameraZ * distance

                cprint(xOffset .. ' ' .. yOffset .. ' ' .. zOffset)

                -- Update monitor crosshair to "holding object" state
                setCrosshairState(2)

                -- Anti-spawn thing
                if (zOffset < minimumZSpawnPoint) then
                    local tempObject = blam.object(get_object(localScenery.id))
                    if (tempObject and inSceneryList(tempObject.tagId, spawnObjects)) then
                        -- Update monitor crosshair to "not placeable" state
                        zOffset = minimumZSpawnPoint
                        setCrosshairState(3)
                    end
                end

                -- Update object position
                blam.object(get_object(localScenery.id), {x = xOffset, y = yOffset, z = zOffset})

                -- Refresh object data
                localScenery.object = blam.object(get_object(localScenery.id))

                -- Forge controls
                if (player.weaponSTH) then
                    -- Place object
                    local previousObjectData = objectsStore[localScenery.id]
                    if (not previousObjectData) then
                        lastSpawnedObject.yaw = localScenery.yaw
                        lastSpawnedObject.pitch = localScenery.pitch
                        lastSpawnedObject.roll = localScenery.roll
                        sendObjectSpawn(localScenery)
                    else
                        lastSpawnedObject.yaw = localScenery.yaw
                        lastSpawnedObject.pitch = localScenery.pitch
                        lastSpawnedObject.roll = localScenery.roll

                        localScenery.serverId = previousObjectData.serverId
                        sendObjectUpdate(localScenery)
                    end
                elseif (player.flashlightKey) then
                    -- Object rotation control
                    local rotationList = {
                        'Yaw +',
                        'Yaw -',
                        'Pitch +',
                        'Pitch -',
                        'Roll +',
                        'Roll -'
                    }
                    localScenery.desiredRotation = localScenery.desiredRotation + 1
                    if (localScenery.desiredRotation > 6) then
                        localScenery.desiredRotation = 1
                    end
                    hud_message(rotationList[localScenery.desiredRotation])
                elseif (player.actionKeyHold) then
                    -- Update object rotation with step 3
                    if (rotationStep > 12) then
                        updateRotation(rotationStep)
                    else
                        updateRotation(rotationStep * 2)
                    end
                elseif (player.actionKey) then
                    -- Update object rotation with step 1
                    updateRotation(rotationStep)
                elseif (player.crouchHold) then
                    -- Reset rotation degrees of the current object
                    hud_message('Resetting rotation...')
                    localScenery.yaw = 0
                    localScenery.pitch = 0
                    localScenery.roll = 0
                    updateRotation(0)
                    hud_message('Current rotation step is ' .. rotationStep)
                elseif (player.jumpHold) then
                    -- Erase attached object
                    local previousObjectData = objectsStore[localScenery.id]
                    if (not previousObjectData) then
                        detachObjectToPlayer(true)
                        localScenery = {}
                    else
                        sendObjectDelete(localScenery)
                    end
                end
                local menuAnswer = forgeMenuHandle()
                if (menuAnswer ~= 0) then
                    detachObjectToPlayer(true)
                end
            else
                -- Restore default monitor crosshair
                setCrosshairState(0)

                -- Find if player is looking at certain object
                for objectLocalId, composedObject in pairs(objectsStore) do
                    local objectAddress = get_object(objectLocalId)
                    local tempObject = blam.object(objectAddress)
                    if (tempObject) then
                        if (blam.playerIsLookingAt(objectLocalId, 0.05, 0)) then
                            -- If object is an scenery
                            if (tempObject.type == 6) then
                                -- Avoid other objects to be highlighted
                                for k, v in pairs(objectsStore) do
                                    if (k ~= objectLocalId) then
                                        blam.object(get_object(k), {health = 0})
                                    end
                                end

                                -- Highlight object
                                blam.object(objectAddress, {health = 100})

                                -- Set monitor "takable object" crosshair
                                setCrosshairState(1)

                                -- Take object, block distance to take it from players distance
                                if (player.weaponPTH) then
                                    blockDistance = true
                                    attachObjectToPlayer(objectLocalId)
                                    distance =
                                        math.sqrt(
                                        (localScenery.object.x - player.x) ^ 2 + (localScenery.object.y - player.y) ^ 2 +
                                            (localScenery.object.z - player.z) ^ 2
                                    )
                                end
                            end
                        else
                            blam.object(objectAddress, {health = 0})
                        end
                    end
                end

                local function createForgeObject(sceneryPath, yaw, pitch, roll)
                    local xOffset = player.x + player.cameraX * distance
                    local yOffset = player.y + player.cameraY * distance
                    local zOffset = player.z + player.cameraZ * distance
                    if (zOffset < minimumZSpawnPoint) then
                        zOffset = minimumZSpawnPoint
                    end
                    local object = spawn_object('scen', sceneryPath, xOffset, yOffset, zOffset)
                    lastSpawnedObject = {}
                    lastSpawnedObject.path = sceneryPath
                    if (object) then
                        attachObjectToPlayer(object)
                        if (yaw and pitch and roll) then
                            rotateObject(object, yaw, pitch, roll)
                        end
                    else
                        cprint('Error at trying to spawn scenery: ' .. sceneryPath)
                    end
                end

                -- Open forge menu with flashlight key
                if (player.flashlightKey) then
                    distance = 5
                    openForgeMenu()
                elseif (player.crouchHold) then
                    swapForgeBiped()
                elseif (player.actionKey) then
                    -- If there is a previously spawned object, then copy his data
                    if (lastSpawnedObject.path) then
                        createForgeObject(
                            lastSpawnedObject.path,
                            lastSpawnedObject.yaw,
                            lastSpawnedObject.pitch,
                            lastSpawnedObject.roll
                        )
                    end
                end

                -- Get the pressed forge menu button
                local menuAnswer = forgeMenuHandle()

                -- If something was pressed
                if (menuAnswer ~= 0) then
                    -- Get the desired object from the Forge menu, using the previous answer
                    local desiredForgeObject = updateForgeMenu(menuAnswer)
                    if (desiredForgeObject) then
                        -- If there is a previous object attached erase it
                        if (localScenery.id) then
                            detachObjectToPlayer(true)
                        end
                        createForgeObject(desiredForgeObject)
                    end
                end
            end
        elseif (player and not isPlayerMonitor(playerBipedAddress)) then -- Player is not in monitor/forge mode
            if (playerLocalData.x) then
                blam.biped(
                    playerBipedAddress,
                    {
                        x = playerLocalData.x,
                        y = playerLocalData.y,
                        z = playerLocalData.z + 0.5,
                        yaw = playerLocalData.yaw,
                        pitch = playerLocalData.pitch,
                        roll = playerLocalData.roll,
                        xScale = playerLocalData.xScale,
                        yScale = playerLocalData.yScale,
                        zScale = playerLocalData.zScale
                    }
                )
                playerLocalData = {}
            end
            setCrosshairState(-1)
            if (player.flashlightKey) then -- Player is trying to get into monitor/forge mode
                swapForgeBiped()
            end
        else
            cprint('Error getting player biped.')
        end
    end
end

function onCommand(command)
    if (command == 'fdebug') then
        debugMode = not debugMode
        console_out('Debug Forge: ' .. tostring(debugMode))
        return false
    else
        local splittedCommand = glue.string.split(' ', command)
        local forgeCommand = splittedCommand[1]
        if (forgeCommand == 'fstep') then
            local newRotationStep = tonumber(splittedCommand[2])
            if (newRotationStep) then
                hud_message('Rotation step now is ' .. newRotationStep .. ' degrees.')
                rotationStep = glue.round(newRotationStep)
            else
                rotationStep = 3
            end
            return false
        elseif (forgeCommand == 'fdis' or forgeCommand == 'fdistance') then
            local newDistance = tonumber(splittedCommand[2])
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
            local mapName = splittedCommand[2]
            if (mapName) then
                saveForgeMap(mapName)
            else
                console_out('You must specify a name for your forge map.')
            end
            return false
        elseif (forgeCommand == 'fload') then
            local mapName = splittedCommand[2]
            if (mapName) then
                loadForgeMap(mapName)
            else
                console_out('You must specify a forge map name.')
            end
            return false
        elseif (forgeCommand == 'flist') then
            listForgeMaps()
            return false
        elseif (forgeCommand == 'fdump') then
            console_out('Current sceneries in game memory:')
            for i = 0, 1023 do
                local tempObject = blam.object(get_object(i))
                if (tempObject and tempObject.type == 6) then
                    console_out(i .. ': ' .. get_tag_path(tempObject.tagId))
                end
            end
            glue.writefile('fdumpStore.txt', inspect(objectsStore), 't')
            console_out('Dumped forge objects state into fdumpStore.txt!!')
            return false
        elseif (forgeCommand == 'freset') then
            execute_script('object_destroy_all')
            flushScript()
            return false
        end
    end
end

function saveForgeMap(mapName)
    console_out('Saving forge map...')
    local forgeObjects = {}
    for objectId, composedObject in pairs(objectsStore) do
        -- Get scenery tag path to keep compatibility between versions
        local sceneryPath = get_tag_path(composedObject.tagId)
        cprint(sceneryPath)
        -- Create a copy of the composed object in the store to avoid replacing useful values
        local fmapComposedObject = {}
        for k, v in pairs(composedObject) do
            fmapComposedObject[k] = v
        end

        -- Remove all the unimportant data
        fmapComposedObject.tagId = nil
        fmapComposedObject.serverId = nil
        fmapComposedObject.reflectedSpawn = nil

        -- Add tag path property
        fmapComposedObject.tagPath = sceneryPath

        -- Add forge object to list
        forgeObjects[#forgeObjects + 1] = fmapComposedObject
    end
    local fmapContent = json.encode(forgeObjects)

    local forgeMapFile = glue.writefile(forgeMapsFolder .. '\\' .. mapName .. '.fmap', fmapContent, 't')
    if (forgeMapFile) then
        console_out("Forge map '" .. mapName .. "' has been succesfully saved!")
    else
        console_out("ERROR!! At saving '" .. mapName .. "' as a forge map...")
    end
    updateForgedMapsMenu()
end

function loadForgeMap(mapName)
    local forgeObjects = {}
    local fmapContent = glue.readfile(forgeMapsFolder .. '\\' .. mapName .. '.fmap', 't')
    if (fmapContent) then
        console_out('Loading forge map...')
        forgeObjects = json.decode(fmapContent)
        if (forgeObjects and #forgeObjects > 0) then
            -- Clean the previous forge session
            flushForge()
            for k, v in pairs(forgeObjects) do
                local tagId = get_tag_id('scen', v.tagPath)
                if (tagId) then
                    v.tagId = tagId
                    v.tagPath = nil
                    spawnLocalObject(v)
                else
                    console_out("ERROR!!!!!!!! At trying to spawn tag: '" .. v.tagPath .. "'")
                end
            end
            console_out("Succesfully loaded '" .. mapName .. "' fmap!")
        else
            console_out("ERROR!! At decoding data from '" .. mapName .. "' forge map...")
        end
    else
        console_out("ERROR!! At trying to load '" .. mapName .. "' as a forge map...")
    end
    updateForgedMapsMenu()
end

function listForgeMaps()
    for file in lfs.dir(forgeMapsFolder) do
        if file ~= '.' and file ~= '..' then
            --local f = forgeMapsFolder .. '\\' .. file
            console_out(file)
        end
    end
    updateForgedMapsMenu()
end

function updateForgedMapsMenu()
    local mapList = {}
    for file in lfs.dir(forgeMapsFolder) do
        if file ~= '.' and file ~= '..' then
            mapList[#mapList + 1] = file
        end
    end
    blam.unicodeStringList(get_tag('unicode_string_list', unicodeStrings.mapList), {stringList = mapList})
end

function isForgeMap()
    return map == 'forge_island_local' or map == 'forge_island' or map == 'forge_island_beta' or map == 'forge'
end

function onMapLoad()
    alreadyLoaded = true
    if (isForgeMap()) then
        cprint('Forge is ready!')

        -- Forge maps folder creation
        forgeMapsFolder = lfs.currentdir() .. '\\fmaps'
        local alreadyForgeMapsFolder = not lfs.mkdir(forgeMapsFolder)
        if (not alreadyForgeMapsFolder) then
            console_out('Createad forge maps folder!')
        end

        -- updateForgedMapsMenu()

        set_callback('tick', 'onTick')
        set_callback('rcon message', 'decodeIncomingData')
        set_callback('command', 'onCommand')
    else
        console_out('This is not a compatible Forge map!!!')
    end
end

function onUnload()
    if (#getExistentObjects() > 0) then
        saveForgeMap('unsaved')
        execute_script('object_destroy_all')
    end
end

-- Prepare event callbacks
set_callback('map postload', 'onMapLoad') -- Thanks Jerry to add this callback!
set_callback('unload', 'onUnload')

-- Allows the script to run by just reloading it
if (server_type == 'local') then
    onMapLoad()
end

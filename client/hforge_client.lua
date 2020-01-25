------------------------------------------------------------------------------
-- HForge Client - Forge Island Client Script
-- Author: Sledmine
-- Version: 3.0
-- Script client side for Forge Island
------------------------------------------------------------------------------

local blam = require 'luablam'
local inspect = require 'inspect'
local json = require 'json'
local lfs = require 'lfs'
local glue = require 'glue'

clua_version = 2.042

local debugMode = false

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
    set_callback('tick')
    set_callback('rcon message')
    localScenery = {}
    objectsStore = {}
    playerLocalData = {}
    lastSpawnedObject = {}
    distance = 4
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

-- Scenery definitions
local sceneries = {
    spawnPoint = '[shm]\\halo_4\\scenery\\spawning\\spawn point\\spawn point'
}

-- Shader definitions
local shaders = {
    selectedObject = '[shm]\\halo_4\\scenery\\shared\\shaders\\object aimed'
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

-- Reflect any scenery spawn point as a real game spawn point
local function reflectSpawnPoints()
    local scenario = blam.scenario(get_tag(0))
    local mapSpawnCount = scenario.spawnLocationCount
    cprint('Found ' .. mapSpawnCount .. ' stock spawn points!')
    local mapSpawnPoints = scenario.spawnLocationList
    for i = 2, mapSpawnCount do
        mapSpawnPoints[i].type = 0
    end
    local lastReflectedSpawn = 0
    for k, composedObject in pairs(objectsStore) do
        local tempObject = blam.object(get_object(k))
        -- Object exists, it's a scenery and it's a spawn point scenery
        if (tempObject and tempObject.type == 6 and tempObject.tagId == get_tag_id('scen', sceneries.spawnPoint)) then
            cprint('Found spawn point at object index: ' .. k)
            lastReflectedSpawn = lastReflectedSpawn + 1
            mapSpawnPoints[lastReflectedSpawn].x = composedObject.x
            mapSpawnPoints[lastReflectedSpawn].y = composedObject.y
            mapSpawnPoints[lastReflectedSpawn].z = composedObject.z
            mapSpawnPoints[lastReflectedSpawn].rotation = math.rad(composedObject.yaw)
            mapSpawnPoints[lastReflectedSpawn].type = 12
        end
    end
    blam.scenario(get_tag(0), {spawnLocationList = mapSpawnPoints})
end

-- Update the amount of budget used per scenery object
local function updateBudgetCount()
    local sceneryCount = 0
    for i = 0, 1023 do
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

    -- As "updateBudgetCount" is called every time an object is deleted/created we can use it to reflect spawn points
    reflectSpawnPoints()
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
        -- THIS IS CALLED BY REFERENCE TO MODIFY availableObjects
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
            cprint(inspect(paginationStringList))
            paginationStringList[2] = tostring(current)
            paginationStringList[4] = tostring(last)
            blam.unicodeStringList(paginationTextAddress, {stringList = paginationStringList})
        end
    end
    local function writeMenuList(menuElements)
        table.sort(
            menuElements,
            function(a, b)
                return a < b
            end
        )
        if (#menuElements > 0) then
            local newChildWidgetsCount = #menuElements
            updatePages(1, 1)
            if (newChildWidgetsCount > 6) then
                newChildWidgetsCount = 6
                cprint('Maximum elements per page, generating another page. THIS WAS DISABLED!!! DUH...')
                updatePages(1, 2)
                lastElements = {}
                for i = 7, #menuElements do
                    lastElements[#lastElements + 1] = menuElements[i]
                end
            end
            blam.unicodeStringList(elementsTextAddress, {stringList = menuElements})
            -- We send new event type for this widget to force a new render on it
            blam.uiWidgetDefinition(
                get_tag('ui_widget_definition', widgetDefinitions.categoryList),
                {
                    childWidgetsCount = newChildWidgetsCount,
                    eventType = 33
                }
            )
        end
    end
    local newElements
    if (element == 0) then
        newElements = glue.keys(availableObjects.root)
        writeMenuList(newElements)
    elseif (element == 7 or element == 8) then
        --[[ Do that page thing here!!!!!]]
        if (lastElements) then
            writeMenuList(lastElements)
            updatePages(2, 2)
            lastElements = nil
        end
    elseif (element == 9) then
        if (lastElement) then
            cprint('Trying to get back in the menu!!!')
            local parent = glue.parentByChild(availableObjects, lastElement)
            if (parent) then
                lastElement = parent
                cprint('Children found in parent: ' .. parent)
                newElements = glue.keys(glue.childsByParent(availableObjects, parent))
                writeMenuList(newElements)
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
                writeMenuList(newElements)
            end
        end
    end
    return nil
end

-- Self explanatory
local function openForgeMenu()
    updateForgeMenu(0)
    updateBudgetCount()
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

-- Swap between monitor and spartan
local function swapForgeBiped()
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
    local tagPath = get_tag_path(objectProperties.tagId)
    local backupZ = objectProperties.z
    if (objectProperties.z < minimumZSpawnPoint) then
        objectProperties.z = minimumZSpawnPoint
    end

    -- Get current objects
    local objectsBeforeSpawn = getExistentObjects()

    -- Executing new object spawn, TODO: add automatic tag type detection (?)
    spawn_object('scen', tagPath, objectProperties.x, objectProperties.y, objectProperties.z)

    -- Getting new objects after object spawn action
    local objectsAfterSpawn = getExistentObjects()

    -- Compare previous and new objects and retreive the new one
    -- This is needed because Chimera API returns a different object id than the ones Halo is tracking
    local objectLocalId = glue.arraynv(objectsBeforeSpawn, objectsAfterSpawn)
    if (objectLocalId) then
        cprint('Object succesfully spawned with id: ' .. objectLocalId)

        -- If spawn is in local mode, then serverId is the same as localId
        if (not objectProperties.serverId) then
            objectProperties.serverId = objectLocalId
        end

        -- Sync scenery object
        objectsStore[objectLocalId] = objectProperties

        -- Update object Z
        blam.object(get_object(objectLocalId), {z = backupZ})
        rotateObject(objectLocalId, objectProperties.yaw, objectProperties.pitch, objectProperties.roll)

        -- Update budget count
        updateBudgetCount()
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
        cprint('Object succesfully updated with local id: ' .. objectLocalId)

        -- Sync scenery object
        objectsStore[objectLocalId].yaw = objectProperties.yaw
        objectsStore[objectLocalId].pitch = objectProperties.pitch
        objectsStore[objectLocalId].roll = objectProperties.roll
        objectsStore[objectLocalId].x = objectProperties.x
        objectsStore[objectLocalId].y = objectProperties.y
        objectsStore[objectLocalId].z = objectProperties.z

        -- Update object Z
        blam.object(
            get_object(objectLocalId),
            {
                x = objectProperties.x,
                y = objectProperties.y,
                z = objectProperties.z
            }
        )
        rotateObject(objectLocalId, objectProperties.yaw, objectProperties.pitch, objectProperties.roll)

        -- Update budget count
        updateBudgetCount()
    else
        cprint('Error at trying to update object!!!')
    end
end

local function flushForge()
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
            else
                cprint(property .. ' ' .. value)
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
        if (objectServerId) then
            local objectLocalId = getObjectByServerId(objectServerId)
            if (objectLocalId and get_object(objectLocalId)) then
                delete_object(objectLocalId)
                objectsStore[objectLocalId] = nil
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
    local object = blam.object(get_object(composedObject.id))
    if (object) then
        detachObjectToPlayer(true)
        cprint('Sending object spawn request... for tagId: ' .. object.tagId)
        local compressedData = {
            string.pack('I4', object.tagId),
            string.pack('f', object.x),
            string.pack('f', object.y),
            string.pack('f', object.z),
            composedObject.yaw,
            composedObject.pitch,
            composedObject.roll
        }
        local function convertDataToRequest(data)
            local request = {}
            for property, value in pairs(compressedData) do
                local encodedValue
                if (type(value) ~= 'number') then
                    encodedValue = glue.tohex(value)
                else
                    encodedValue = value
                end
                table.insert(request, encodedValue)
                cprint(property .. ' ' .. encodedValue)
            end
            local commandRequest = table.concat(request, ',')
            cprint('Request size is: ' .. #commandRequest + 5 .. ' characters')
            return "rcon forge '#s," .. commandRequest .. "'" -- Spawn format
        end
        local request = convertDataToRequest(compressedData)
        cprint(inspect(request))
        if (server_type ~= 'local') then
            -- Player is connected to a server
            execute_script(request)
        else
            -- Mockup server response in local mode
            decodeIncomingData(string.gsub(string.gsub(request, "rcon forge '", ''), "'", ''))
        end
    end
end

-- Send an object update request to the server
local function sendObjectUpdate(composedObject)
    local object = blam.object(get_object(composedObject.id))
    if (object) then
        detachObjectToPlayer(true)
        cprint('Sending object update request... for serverId: ' .. composedObject.serverId)
        local compressedData = {
            string.pack('I4', composedObject.serverId),
            string.pack('f', object.x),
            string.pack('f', object.y),
            string.pack('f', object.z),
            composedObject.yaw,
            composedObject.pitch,
            composedObject.roll
        }
        local function convertDataToRequest(data)
            local request = {}
            for property, value in pairs(compressedData) do
                local encodedValue
                if (type(value) ~= 'number') then
                    encodedValue = glue.tohex(value)
                else
                    encodedValue = value
                end
                table.insert(request, encodedValue)
                cprint(property .. ' ' .. encodedValue)
            end
            local commandRequest = table.concat(request, ',')
            cprint('Request size is: ' .. #commandRequest + 5 .. ' characters')
            return "rcon forge '#u," .. commandRequest .. "'" -- Spawn format
        end
        local request = convertDataToRequest(compressedData)
        cprint(inspect(request))
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
                    if (tempObject and tempObject.tagId == get_tag_id('scen', sceneries.spawnPoint)) then
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
            flushForge()
            for k, v in pairs(forgeObjects) do
                v.tagId = get_tag_id('scen', v.tagPath)
                v.tagPath = nil
                spawnLocalObject(v)
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

-- Convert global script into map script
function onMapLoad()
    flushScript()
    if (isForgeMap()) then
        -- Forge maps folder creation
        forgeMapsFolder = lfs.currentdir() .. '\\fmaps'
        local alreadyForgeMapsFolder = not lfs.mkdir(forgeMapsFolder)
        if (not alreadyForgeMapsFolder) then
            console_out('Createad forge maps folder!')
        end
        updateForgedMapsMenu()
        set_callback('tick', 'onTick')
        set_callback('rcon message', 'decodeIncomingData')
        set_callback('command', 'onCommand')
    else
        flushScript()
    end
end

if (server_type ~= 'local' and isForgeMap()) then
    -- Prevent the script from being reloaded on a server
    execute_script('disconnect')
elseif (server_type == 'local' and isForgeMap()) then
    -- Allows the script to run by just reloading it
    onMapLoad()

    -- Erase every object on the map, TODO: reupdate object storage with current objects
    execute_script('object_destroy_all')
end

-- Prepare event callbacks
set_callback('map load', 'onMapLoad')

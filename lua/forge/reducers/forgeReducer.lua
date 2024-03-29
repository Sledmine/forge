-- Lua libraries
local inspect = require "inspect"
local glue = require "glue"

-- Forge modules
local interface = require "forge.interface"

---@class forgeState
local defaultState = {
    mapsMenu = {
        mapsList = {},
        currentMapsList = {},
        currentPage = 1
    },
    forgeMenu = {
        -- //TODO Implement a way to use this field for menu navigation purposes 
        lastObject = "root",
        desiredElement = "root",
        objectsDatabase = {},
        objectsList = {root = {}},
        elementsList = {root = {}},
        currentElementsList = {},
        currentPage = 1,
        currentBudget = "0",
        currentBarSize = 0
    },
    loadingMenu = {loadingObjectPath = "", currentBarSize = 422, expectedObjects = 0},
    currentMap = {
        name = "Unsaved",
        author = "Unknown",
        version = "1.0",
        description = "No description given for this map."
    }
}

---@param state forgeState
local function forgeReducer(state, action)
    if (not state) then
        -- Create default state if it does not exist
        state = glue.deepcopy(defaultState)
    end
    if (action.type) then
        dprint("[Forge Reducer]:")
        dprint("Action: " .. action.type, "category")
    end
    if (action.type == "UPDATE_MAP_LIST") then
        state.mapsMenu.mapsList = action.payload.mapsList

        -- Sort maps list by alphabetical order
        table.sort(state.mapsMenu.mapsList, function(a, b)
            return a:lower() < b:lower()
        end)

        state.mapsMenu.currentMapsList = glue.chunks(state.mapsMenu.mapsList, 8)
        local totalPages = #state.mapsMenu.currentMapsList
        return state
    elseif (action.type == "INCREMENT_MAPS_MENU_PAGE") then
        if (state.mapsMenu.currentPage < #state.mapsMenu.currentMapsList) then
            state.mapsMenu.currentPage = state.mapsMenu.currentPage + 1
        end
        dprint(state.mapsMenu.currentPage)
        return state
    elseif (action.type == "DECREMENT_MAPS_MENU_PAGE") then
        if (state.mapsMenu.currentPage > 1) then
            state.mapsMenu.currentPage = state.mapsMenu.currentPage - 1
        end
        dprint(state.mapsMenu.currentPage)
        return state
    elseif (action.type == "UPDATE_FORGE_ELEMENTS_LIST") then
        state.forgeMenu = action.payload.forgeMenu
        local elementsList = glue.childsbyparent(state.forgeMenu.elementsList,
                                                 state.forgeMenu.desiredElement)
        if (not elementsList) then
            state.forgeMenu.desiredElement = "root"
            elementsList = glue.childsbyparent(state.forgeMenu.elementsList,
                                               state.forgeMenu.desiredElement)
        end

        if (elementsList) then
            -- Sort and prepare elements list in alphabetic order
            local keysList = glue.keys(elementsList)
            table.sort(keysList, function(a, b)
                return a:lower() < b:lower()
            end)

            for i = 1, #keysList do
                if (string.sub(keysList[i], 1, 1) == "_") then
                    keysList[i] = string.sub(keysList[i], 2, -1)
                end
            end

            -- Create list pagination
            state.forgeMenu.currentElementsList = glue.chunks(keysList, 6)
        else
            error("Element " .. tostring(state.forgeMenu.desiredElement) ..
                      " does not exist in the state list")
        end
        return state
    elseif (action.type == "INCREMENT_FORGE_MENU_PAGE") then
        dprint("Page: " .. inspect(state.forgeMenu.currentPage))
        if (state.forgeMenu.currentPage < #state.forgeMenu.currentElementsList) then
            state.forgeMenu.currentPage = state.forgeMenu.currentPage + 1
        end
        return state
    elseif (action.type == "DECREMENT_FORGE_MENU_PAGE") then
        dprint("Page: " .. inspect(state.forgeMenu.currentPage))
        if (state.forgeMenu.currentPage > 1) then
            state.forgeMenu.currentPage = state.forgeMenu.currentPage - 1
        end
        return state
    elseif (action.type == "DOWNWARD_NAV_FORGE_MENU") then
        state.forgeMenu.currentPage = 1
        state.forgeMenu.desiredElement = action.payload.desiredElement
        local objectsList = glue.childsbyparent(state.forgeMenu.elementsList,
                                                state.forgeMenu.desiredElement)

        -- Sort and prepare object list in alphabetic order
        local keysList = glue.keys(objectsList)
        table.sort(keysList, function(a, b)
            return a:lower() < b:lower()
        end)

        -- Create list pagination
        state.forgeMenu.currentElementsList = glue.chunks(keysList, 6)

        return state
    elseif (action.type == "UPWARD_NAV_FORGE_MENU") then
        state.forgeMenu.currentPage = 1
        state.forgeMenu.desiredElement = glue.parentbychild(state.forgeMenu.elementsList,
                                                            state.forgeMenu.desiredElement)
        local objectsList = glue.childsbyparent(state.forgeMenu.elementsList,
                                                state.forgeMenu.desiredElement)

        -- Sort and prepare object list in alphabetic order
        local keysList = glue.keys(objectsList)
        table.sort(keysList, function(a, b)
            return a:lower() < b:lower()
        end)

        -- Create list pagination
        state.forgeMenu.currentElementsList = glue.chunks(keysList, 6)

        return state
    elseif (action.type == "SET_MAP_NAME") then
        state.currentMap.name = action.payload.mapName
        return state
    elseif (action.type == "SET_MAP_AUTHOR") then
        state.currentMap.author = action.payload.mapAuthor
        return state
    elseif (action.type == "SET_MAP_DESCRIPTION") then
        state.currentMap.description = action.payload.mapDescription
        return state
    elseif (action.type == "SET_MAP_DATA") then
        state.currentMap.name = action.payload.mapName
        state.currentMap.description = action.payload.mapDescription
        if (action.payload.mapDescription == "") then
            state.currentMap.description = "No description given for this map."
        end
        state.currentMap.author = action.payload.mapAuthor
        return state
    elseif (action.type == "UPDATE_BUDGET") then
        -- FIXME This should be separated from this reducer in order to prevent menu blinking
        -- Set current budget bar data
        local objectState = eventsStore:getState().forgeObjects
        local currentObjects = #glue.keys(objectState) or 0
        local newBarSize = currentObjects * const.maximumProgressBarSize /
                               const.maximumObjectsBudget
        state.forgeMenu.currentBarSize = glue.floor(newBarSize)
        state.forgeMenu.currentBudget = tostring(currentObjects)
        return state
    elseif (action.type == "UPDATE_MAP_INFO") then
        if (action.payload) then
            local expectedObjects = action.payload.expectedObjects
            local mapName = action.payload.mapName
            local mapDescription = action.payload.mapDescription
            if (expectedObjects) then
                state.loadingMenu.expectedObjects = expectedObjects
            end
            if (mapName) then
                state.currentMap.name = mapName
            end
            if (mapDescription) then
                state.currentMap.description = mapDescription
            end
            if (action.payload.loadingObjectPath) then
                state.loadingMenu.loadingObjectPath = action.payload.loadingObjectPath
            end
        end
        if (server_type ~= "sapp") then
            if (eventsStore) then
                if (state.loadingMenu.expectedObjects > 0) then
                    -- Prevent player from falling and desyncing by freezing it
                    local player = blam.biped(get_dynamic_player())
                    -- FIXME For some reason player is being able unfreeze after applying this
                    if (player) then
                        player.zVel = 0
                        player.isFrozen = true
                    end

                    -- Set loading map bar data
                    local expectedObjects = state.loadingMenu.expectedObjects
                    local objectState = eventsStore:getState().forgeObjects
                    local currentObjects = #glue.keys(objectState) or 0
                    local newBarSize = currentObjects * const.maxLoadingBarSize /
                                           expectedObjects
                    state.loadingMenu.currentBarSize = glue.floor(newBarSize)
                    if (state.loadingMenu.currentBarSize >= const.maxLoadingBarSize) then
                        -- Unfreeze player
                        local player = blam.biped(get_dynamic_player())
                        if (player) then
                            player.isFrozen = false
                        end
                        if (forgeAnimationTimer) then
                            stop_timer(forgeAnimationTimer)
                            forgeAnimationTimer = nil
                            dprint("Erasing forge animation timer!")
                        end
                        interface.close(const.uiWidgetDefinitions.loadingMenu)
                    end
                else
                    interface.close(const.uiWidgetDefinitions.loadingMenu)
                end
            end
        end
        return state
    else
        if (action.type == "@@lua-redux/INIT") then
            dprint("Default state has been created!")
        else
            dprint(("Warning, Dispatched event \"%s\" does not exist:"):format(tostring(action.type)), "warning")
        end
        return state
    end
    return state
end

return forgeReducer

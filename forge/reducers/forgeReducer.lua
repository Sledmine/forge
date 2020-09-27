-- Lua libraries
local inspect = require "inspect"
local glue = require "glue"

-- Forge modules

local menu = require "forge.menu"

local function forgeReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        ---@class forgeState
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
                desiredElement = "root",
                objectsDatabase = {},
                objectsList = {root = {}},
                currentObjectsList = {},
                currentPage = 1,
                currentBudget = "0",
                currentBarSize = 0
            },
            loadingMenu = {
                loadingObjectPath = "",
                currentBarSize = 422,
                expectedObjects = 1
            },
            currentMap = {
                name = "Unsaved",
                author = "Author: Unknown",
                version = "1.0",
                description = "No description given for this map."
            }
        }
    end
    if (action.type) then
        dprint("[Forge Store]:")
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
        return state
    elseif (action.type == "INCREMENT_MAPS_MENU_PAGE") then
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
        dprint(state.mapsMenu.currentPage)
        return state
    elseif (action.type == "DECREMENT_MAPS_MENU_PAGE") then
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
        dprint(state.mapsMenu.currentPage)
        return state
    elseif (action.type == "UPDATE_FORGE_OBJECTS_LIST") then
        state.forgeMenu = action.payload.forgeMenu
        local objectsList = glue.childsbyparent(state.forgeMenu.objectsList,
                                                state.forgeMenu.desiredElement)

        -- Sort and prepare object list in alphabetic order
        local keysList = glue.keys(objectsList)
        table.sort(keysList, function(a, b)
            return a:lower() < b:lower()
        end)

        for i = 1, #keysList do
            if (string.sub(keysList[i], 1, 1) == "_") then
                keysList[i] = string.sub(keysList[i], 2, -1)
            end
        end

        -- Create list pagination
        state.forgeMenu.currentObjectsList = glue.chunks(keysList, 6)

        return state
    elseif (action.type == "INCREMENT_FORGE_MENU_PAGE") then
        dprint("Page:" .. inspect(state.forgeMenu.currentPage))
        if (state.forgeMenu.currentPage < #state.forgeMenu.currentObjectsList) then
            state.forgeMenu.currentPage = state.forgeMenu.currentPage + 1
        end
        return state
    elseif (action.type == "DECREMENT_FORGE_MENU_PAGE") then
        dprint("Page:" .. inspect(state.forgeMenu.currentPage))
        if (state.forgeMenu.currentPage > 1) then
            state.forgeMenu.currentPage = state.forgeMenu.currentPage - 1
        end
        return state
    elseif (action.type == "DOWNWARD_NAV_FORGE_MENU") then
        state.forgeMenu.currentPage = 1
        state.forgeMenu.desiredElement = action.payload.desiredElement
        local objectsList = glue.childsbyparent(state.forgeMenu.objectsList,
                                                state.forgeMenu.desiredElement)

        -- Sort and prepare object list in alphabetic order
        local keysList = glue.keys(objectsList)
        table.sort(keysList, function(a, b)
            return a:lower() < b:lower()
        end)

        -- Create list pagination
        state.forgeMenu.currentObjectsList = glue.chunks(keysList, 6)

        return state
    elseif (action.type == "UPWARD_NAV_FORGE_MENU") then
        state.forgeMenu.currentPage = 1
        state.forgeMenu.desiredElement = glue.parentbychild(state.forgeMenu.objectsList,
                                                            state.forgeMenu.desiredElement)
        local objectsList = glue.childsbyparent(state.forgeMenu.objectsList,
                                                state.forgeMenu.desiredElement)

        -- Sort and prepare object list in alphabetic order
        local keysList = glue.keys(objectsList)
        table.sort(keysList, function(a, b)
            return a:lower() < b:lower()
        end)

        -- Create list pagination
        state.forgeMenu.currentObjectsList = glue.chunks(keysList, 6)

        return state
    elseif (action.type == "SET_MAP_NAME") then
        state.currentMap.name = action.payload.mapName
        return state
    elseif (action.type == "SET_MAP_AUTHOR") then
        state.currentMap.author = "Author: " .. action.payload.mapAuthor
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
        state.currentMap.author = "Author: " .. action.payload.mapAuthor
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
                    -- Set current budget bar data
                    local objectState = eventsStore:getState().forgeObjects
                    local currentObjects = #glue.keys(objectState)
                    local newBarSize = currentObjects * constants.maximumProgressBarSize /
                                           constants.maximumBudget
                    state.forgeMenu.currentBarSize = glue.floor(newBarSize)
                    state.forgeMenu.currentBudget = tostring(currentObjects)

                    -- Set loading map bar data
                    local expectedObjects = state.loadingMenu.expectedObjects
                    local newBarSize = currentObjects * constants.maximumLoadingProgressBarSize /
                                           expectedObjects
                    state.loadingMenu.currentBarSize = glue.floor(newBarSize)
                    if (state.loadingMenu.currentBarSize >= constants.maximumLoadingProgressBarSize) then
                        menu.close(constants.uiWidgetDefinitions.loadingMenu)
                    end
                else
                    if (forgeAnimationTimer) then
                        stop_timer(forgeAnimationTimer)
                    end
                    menu.close(constants.uiWidgetDefinitions.loadingMenu)
                end
            end
        end
        return state
    else
        if (action.type == "@@lua-redux/INIT") then
            dprint("Default state has been created!")
        else
            dprint("ERROR!!! The dispatched event does not exist:", "error")
        end
        return state
    end
end

return forgeReducer

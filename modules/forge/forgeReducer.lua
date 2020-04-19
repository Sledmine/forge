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
                currentPage = 1,
                currentBudget = '0',
                currentBarSize = 0
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
    elseif (action.type == 'UPDATE_BUDGET') then
        if(objectsStore) then
            local objectState = objectsStore:getState()
            local currentObjects = tostring(#glue.keys(objectState))
            local newBarSize =  tonumber(currentObjects) * constants.maximumProgressBarSize / 1024
            state.forgeMenu.currentBarSize = glue.floor(newBarSize)
            state.forgeMenu.currentBudget = currentObjects
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

return forgeReducer
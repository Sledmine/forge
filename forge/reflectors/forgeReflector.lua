------------------------------------------------------------------------------
-- Forge Reflector
-- Sledmine
-- Function reflector for store
------------------------------------------------------------------------------
local menu = require "forge.menu"
local core = require "forge.core"
local forgeVersion = require "forge.version"

local inspect = require "inspect"

local function forgeReflector()
    -- Get current forge state
    ---@type forgeState
    local forgeState = forgeStore:getState()

    local currentMenuPage = forgeState.forgeMenu.currentPage
    local currentElements = forgeState.forgeMenu.currentElementsList[currentMenuPage]

    -- Prevent errors objects does not exist
    if (not currentElements) then
        dprint("Current objects list is empty.", "warning")
        currentElements = {}
    end

    -- Forge Menu
    local forgeMenuElementsStrings = blam.unicodeStringList(
                                         constants.unicodeStrings.forgeMenuElements)
    forgeMenuElementsStrings.stringList = currentElements
    menu.update(constants.uiWidgetDefinitions.objectsList, #currentElements + 2)

    local pagination = blam.unicodeStringList(constants.unicodeStrings.pagination)
    if (pagination) then
        local paginationStringList = pagination.stringList
        paginationStringList[2] = tostring(currentMenuPage)
        paginationStringList[4] = tostring(#forgeState.forgeMenu.currentElementsList)
        pagination.stringList = paginationStringList
    end

    -- Budget count
    -- Update unicode string with current budget value
    local currentBudget = blam.unicodeStringList(constants.unicodeStrings.budgetCount)

    -- Refresh budget count
    currentBudget.stringList = {
        forgeState.forgeMenu.currentBudget,
        "/ " .. tostring(constants.maximumBudget)
    }

    -- Refresh budget bar status
    local amountBarWidget = blam.uiWidgetDefinition(constants.uiWidgetDefinitions.amountBar)
    amountBarWidget.width = forgeState.forgeMenu.currentBarSize

    -- Refresh loading bar size
    local loadingProgressWidget = blam.uiWidgetDefinition(
                                      constants.uiWidgetDefinitions.loadingProgress)
    loadingProgressWidget.width = forgeState.loadingMenu.currentBarSize

    local currentMapsMenuPage = forgeState.mapsMenu.currentPage
    local currentMapsList = forgeState.mapsMenu.currentMapsList[currentMapsMenuPage]

    -- Prevent errors when maps does not exist
    if (not currentMapsList) then
        dprint("Current maps list is empty.")
        currentMapsList = {}
    end

    -- Refresh available forge maps list
    -- //TODO Merge unicode string updating with menus updating?

    local mapsListStrings = blam.unicodeStringList(constants.unicodeStrings.mapsList)
    mapsListStrings.stringList = currentMapsList
    -- Wich ui widget will be updated and how many items it will show
    menu.update(constants.uiWidgetDefinitions.mapsList, #currentMapsList + 3)

    -- Refresh fake sidebar in maps menu
    local sidebarWidget = blam.uiWidgetDefinition(constants.uiWidgetDefinitions.sidebar)
    sidebarWidget.height = forgeState.mapsMenu.sidebar.height
    sidebarWidget.boundsY = forgeState.mapsMenu.sidebar.position

    -- Refresh current forge map information
    local pauseGameStrings = blam.unicodeStringList(constants.unicodeStrings.pauseGameStrings)
    pauseGameStrings.stringList = {
        -- Bypass first 3 elements in the string list
        "",
        "",
        "",
        forgeState.currentMap.name,
        forgeState.currentMap.author,
        forgeState.currentMap.version,
        forgeState.currentMap.description,
        "",
        "",
        "",
        "",
        "",
        "v".. forgeVersion
    }
end

return forgeReflector

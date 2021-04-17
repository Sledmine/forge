------------------------------------------------------------------------------
-- Forge Reflector
-- Sledmine
-- Function reflector for store
------------------------------------------------------------------------------
local interface = require "forge.interface"
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
                                         constants.unicodeStrings.forgeMenuElementsTagId)
    forgeMenuElementsStrings.stringList = currentElements
    interface.update(constants.uiWidgetDefinitions.objectsList, #currentElements + 2)

    local pagination = blam.unicodeStringList(constants.unicodeStrings.paginationTagId)
    if (pagination) then
        local paginationStringList = pagination.stringList
        paginationStringList[2] = tostring(currentMenuPage)
        paginationStringList[4] = tostring(#forgeState.forgeMenu.currentElementsList)
        pagination.stringList = paginationStringList
    end

    -- Budget count
    -- Update unicode string with current budget value
    local currentBudget = blam.unicodeStringList(constants.unicodeStrings.budgetCountTagId)

    -- Refresh budget count
    currentBudget.stringList = {
        forgeState.forgeMenu.currentBudget,
        "/ " .. tostring(constants.maximumObjectsBudget)
    }

    -- Refresh budget bar status
    local amountBarWidget = blam.uiWidgetDefinition(constants.uiWidgetDefinitions.amountBar.id)
    amountBarWidget.width = forgeState.forgeMenu.currentBarSize

    -- Refresh loading bar size
    local loadingProgressWidget = blam.uiWidgetDefinition(
                                      constants.uiWidgetDefinitions.loadingProgress.id)
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

    local mapsListStrings = blam.unicodeStringList(constants.unicodeStrings.mapsListTagId)
    mapsListStrings.stringList = currentMapsList
    -- Wich ui widget will be updated and how many items it will show
    interface.update(constants.uiWidgetDefinitions.mapsList, #currentMapsList + 3)

    -- Refresh fake sidebar in maps menu
    local sidebarWidget = blam.uiWidgetDefinition(constants.uiWidgetDefinitions.sidebar.id)
    sidebarWidget.height = forgeState.mapsMenu.sidebar.height
    sidebarWidget.boundsY = forgeState.mapsMenu.sidebar.position

    -- Refresh current forge map information
    local pauseGameStrings = blam.unicodeStringList(constants.unicodeStrings.pauseGameStringsTagId)
    pauseGameStrings.stringList = {
        -- Skip elements using empty string
        "",
        "",
        "",
        -- Forge maps menu 
        forgeState.currentMap.name,
        "Author: " .. forgeState.currentMap.author,
        forgeState.currentMap.version,
        forgeState.currentMap.description,
        -- Forge loading objects screen
        "Loading " .. forgeState.currentMap.name .. "...",
        forgeState.loadingMenu.loadingObjectPath,
        "",
        "",
        "",
        "v".. forgeVersion
    }
end

return forgeReflector

------------------------------------------------------------------------------
-- Forge Reflector
-- Sledmine
-- Function reflector for store
------------------------------------------------------------------------------
local glue = require "glue"

local interface = require "forge.interface"
local features = require "forge.features"
local core = require "forge.core"
local forgeVersion = require "forge.version"

local function forgeReflector()
    -- Get current forge state
    ---@type forgeState
    local state = forgeStore:getState()

    local currentMenuPage = state.forgeMenu.currentPage
    local currentElements = state.forgeMenu.currentElementsList[currentMenuPage]

    -- Prevent errors objects does not exist
    if (not currentElements) then
        dprint("Current objects list is empty.", "warning")
        currentElements = {}
    end

    -- Forge Menu
    local forgeMenuElementsStrings = blam.unicodeStringList(const.unicodeStrings
                                                                .forgeMenuElementsTagId)
    forgeMenuElementsStrings.stringList = currentElements
    local newElementsCount = #currentElements + 2
    local elementsList = blam.uiWidgetDefinition(const.uiWidgetDefinitions.objectsList.id)
    if (elementsList and elementsList.childWidgetsCount ~= newElementsCount) then
        interface.update(const.uiWidgetDefinitions.objectsList, newElementsCount)
    end

    local pagination = blam.unicodeStringList(const.unicodeStrings.paginationTagId)
    if (pagination) then
        local paginationStringList = pagination.stringList
        paginationStringList[1] = " "
        paginationStringList[2] = tostring(currentMenuPage)
        paginationStringList[4] = tostring(#state.forgeMenu.currentElementsList)
        pagination.stringList = paginationStringList
    end

    -- Budget count
    -- Update unicode string with current budget value
    local currentBudget = blam.unicodeStringList(const.unicodeStrings.budgetCountTagId)

    -- Refresh budget count
    currentBudget.stringList = {
        state.forgeMenu.currentBudget,
        "/ " .. tostring(const.maximumObjectsBudget)
    }

    -- Refresh budget bar status
    local amountBarWidget = blam.uiWidgetDefinition(const.uiWidgetDefinitions.amountBar.id)
    amountBarWidget.width = state.forgeMenu.currentBarSize

    -- Refresh loading bar size
    local loadingProgressWidget = blam.uiWidgetDefinition(
                                      const.uiWidgetDefinitions.loadingProgress.id)
    loadingProgressWidget.width = state.loadingMenu.currentBarSize

    local currentMapsMenuPage = state.mapsMenu.currentPage
    local mapsListPage = state.mapsMenu.currentMapsList[currentMapsMenuPage]

    -- Prevent errors when maps does not exist
    if (not mapsListPage) then
        dprint("Current maps list is empty.")
        mapsListPage = {}
    end

    -- Refresh available forge maps list
    -- //TODO Merge unicode string updating with menus updating?

    local mapsListStrings = blam.unicodeStringList(const.unicodeStrings.mapsListTagId)
    mapsListStrings.stringList = mapsListPage

    local mapsListWidget = blam.uiWidgetDefinition(const.uiWidgetDefinitions.mapsList.id)
    local newElementsCount = #mapsListPage + 3
    if (mapsListWidget and mapsListWidget.childWidgetsCount ~= newElementsCount) then
        -- Wich ui widget will be updated and how many items it will show
        interface.update(const.uiWidgetDefinitions.mapsList, newElementsCount)
    end

    -- Refresh scroll bar
    -- TODO Move this into a new reducer to avoid reflector conflicts, or a better implementation
    local scrollBar = blam.uiWidgetDefinition(const.uiWidgetDefinitions.scrollBar.id)
    local scrollBarPosition = blam.uiWidgetDefinition(const.uiWidgetDefinitions.scrollPosition.id)
    if (scrollBar and scrollBarPosition) then
        if (features.getCurrentWidget() == const.uiWidgetDefinitions.mapsMenu.id) then
            local elementsCount = #state.mapsMenu.currentMapsList
            if (elementsCount > 0) then
                local barSizePerElement = glue.round(scrollBar.height / elementsCount)
                scrollBarPosition.height = barSizePerElement * state.mapsMenu.currentPage
                scrollBarPosition.boundsY = -barSizePerElement +
                                                (barSizePerElement * state.mapsMenu.currentPage)
            end
        else
            local elementsCount = #state.forgeMenu.currentElementsList
            if (elementsCount > 0) then
                local barSizePerElement = glue.round(scrollBar.height / elementsCount)
                scrollBarPosition.height = barSizePerElement * state.forgeMenu.currentPage
                scrollBarPosition.boundsY = -barSizePerElement +
                                                (barSizePerElement * state.forgeMenu.currentPage)
            end
        end
    end

    -- Refresh current forge map information
    local pauseGameStrings = blam.unicodeStringList(const.unicodeStrings.pauseGameStringsTagId)
    pauseGameStrings.stringList = {
        -- Skip elements using empty string
        "",
        "",
        "",
        -- Forge maps menu 
        state.currentMap.name,
        "Author: " .. state.currentMap.author,
        state.currentMap.version,
        state.currentMap.description,
        -- Forge loading objects screen
        "Loading " .. state.currentMap.name .. "...",
        state.loadingMenu.loadingObjectPath,
        "",
        "",
        "",
        "v" .. forgeVersion
    }
end

return forgeReflector

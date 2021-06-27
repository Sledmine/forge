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
    local forgeMenuElementsStrings = blam.unicodeStringList(const.unicodeStrings
                                                                .forgeMenuElementsTagId)
    forgeMenuElementsStrings.stringList = currentElements
    interface.update(const.uiWidgetDefinitions.objectsList, #currentElements + 2)

    local pagination = blam.unicodeStringList(const.unicodeStrings.paginationTagId)
    if (pagination) then
        local paginationStringList = pagination.stringList
        paginationStringList[2] = tostring(currentMenuPage)
        paginationStringList[4] = tostring(#forgeState.forgeMenu.currentElementsList)
        pagination.stringList = paginationStringList
    end

    -- Budget count
    -- Update unicode string with current budget value
    local currentBudget = blam.unicodeStringList(const.unicodeStrings.budgetCountTagId)

    -- Refresh budget count
    currentBudget.stringList = {
        forgeState.forgeMenu.currentBudget,
        "/ " .. tostring(const.maximumObjectsBudget)
    }

    -- Refresh budget bar status
    local amountBarWidget =
        blam.uiWidgetDefinition(const.uiWidgetDefinitions.amountBar.id)
    amountBarWidget.width = forgeState.forgeMenu.currentBarSize

    -- Refresh loading bar size
    local loadingProgressWidget = blam.uiWidgetDefinition(
                                      const.uiWidgetDefinitions.loadingProgress.id)
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

    local mapsListStrings = blam.unicodeStringList(const.unicodeStrings.mapsListTagId)
    mapsListStrings.stringList = currentMapsList
    -- Wich ui widget will be updated and how many items it will show
    interface.update(const.uiWidgetDefinitions.mapsList, #currentMapsList + 3)

    -- Refresh fake sidebar in maps menu
    local sidebarWidget = blam.uiWidgetDefinition(const.uiWidgetDefinitions.sidebar.id)
    sidebarWidget.height = forgeState.mapsMenu.sidebar.height
    sidebarWidget.boundsY = forgeState.mapsMenu.sidebar.position

    -- Refresh current forge map information
    local pauseGameStrings = blam.unicodeStringList(const.unicodeStrings
                                                        .pauseGameStringsTagId)
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
        "v" .. forgeVersion
    }

    local settingsMenuList =
        blam.uiWidgetDefinition(const.uiWidgetDefinitions.settingsMenuList.id)
    if (settingsMenuList) then
        settingsMenuList.childWidgetsCount = 4
    end

    local settingsMenuStrings = blam.unicodeStringList(const.unicodeStrings
                                                           .settingsMenuStringsTagId)
    if (settingsMenuStrings) then
        settingsMenuStrings.stringList = {
            "Enable debug mode",
            "Constantly save current map",
            "Enable object snap mode",
            "Cast shadow on objects"
        }
    end
    local settingsMenuValuesStrings = blam.unicodeStringList(const.unicodeStrings.settingsMenuValueStringsTagId)
    settingsMenuValuesStrings.stringList = {
        core.toSentenceCase(tostring(config.forge.debugMode)),
        core.toSentenceCase(tostring(config.forge.autoSave)),
        core.toSentenceCase(tostring(config.forge.snapMode)),
        core.toSentenceCase(tostring(config.forge.objectsCastShadow)),
    }
end

return forgeReflector

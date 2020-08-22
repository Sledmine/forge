------------------------------------------------------------------------------
-- Forge Reflector
-- Sledmine
-- Function reflector for store
------------------------------------------------------------------------------
local constants = require "forge.constants"
local menu = require "forge.menu"

local inspect = require "inspect"

local function forgeReflector()
    -- Get current forge state
    local forgeState = forgeStore:getState()

    local currentObjectsList = forgeState.forgeMenu.currentObjectsList[forgeState.forgeMenu
                                   .currentPage]

    -- Prevent errors objects does not exist
    if (not currentObjectsList) then
        dprint("Current objects list is empty.", "warning")
        currentObjectsList = {}
    end

    -- Forge Menu
    blam.unicodeStringList(get_tag("unicode_string_list", constants.unicodeStrings.forgeList),
                           {
        stringList = currentObjectsList
    })
    menu.update(constants.uiWidgetDefinitions.forgeList, #currentObjectsList + 2)

    local paginationTextAddress =
        get_tag("unicode_string_list", constants.unicodeStrings.pagination)
    if (paginationTextAddress) then
        local pagination = blam.unicodeStringList(paginationTextAddress)
        local paginationStringList = pagination.stringList
        paginationStringList[2] = tostring(forgeState.forgeMenu.currentPage)
        paginationStringList[4] = tostring(#forgeState.forgeMenu.currentObjectsList)
        blam.unicodeStringList(paginationTextAddress, {
            stringList = paginationStringList
        })
    end

    -- Budget count
    -- Update unicode string with current budget value
    local budgetCountAddress = get_tag("unicode_string_list", constants.unicodeStrings.budgetCount)
    local currentBudget = blam.unicodeStringList(budgetCountAddress)

    currentBudget.stringList = {
        forgeState.forgeMenu.currentBudget,
        "/ " .. tostring(constants.maximumBudget)
    }

    -- Refresh budget count
    blam.unicodeStringList(budgetCountAddress, currentBudget)
    

    -- Refresh budget bar status
    blam.uiWidgetDefinition(
        get_tag("ui_widget_definition", constants.uiWidgetDefinitions.amountBar),
        {
            width = forgeState.forgeMenu.currentBarSize
        })

    -- Refresh loading bar size
    blam.uiWidgetDefinition(get_tag("ui_widget_definition",
                                    constants.uiWidgetDefinitions.loadingProgress),
                            {
        width = forgeState.loadingMenu.currentBarSize
    })

    local currentMapsList = forgeState.mapsMenu.currentMapsList[forgeState.mapsMenu.currentPage]

    -- Prevent errors when maps does not exist
    if (not currentMapsList) then
        dprint("Current maps list is empty.")
        currentMapsList = {}
    end

    -- Refresh available forge maps list
    -- TO DO: Merge unicode string updating with menus updating!
    blam.unicodeStringList(get_tag("unicode_string_list", constants.unicodeStrings.mapsList),
                           {
        stringList = currentMapsList
    })
    -- Wich ui widget will be updated and how many items it will show
    menu.update(constants.uiWidgetDefinitions.mapsList, #currentMapsList + 3)

    -- Refresh fake sidebar in maps menu
    blam.uiWidgetDefinition(get_tag("ui_widget_definition", constants.uiWidgetDefinitions.sidebar),
                            {
        height = forgeState.mapsMenu.sidebar.height,
        boundsY = forgeState.mapsMenu.sidebar.position
    })

    -- Refresh current forge map information
    blam.unicodeStringList(
        get_tag("unicode_string_list", constants.unicodeStrings.pauseGameStrings), {
            stringList = {
                -- Bypass first 3 elements in the string list
                "",
                "",
                "",
                forgeState.currentMap.name,
                forgeState.currentMap.author,
                forgeState.currentMap.version,
                forgeState.currentMap.description
            }
        })
end

return forgeReflector

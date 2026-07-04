local glue = require "glue"
local features = require "forge.features"
local interface = require "forge.interface"
local core = require "forge.core"

local function generalMenuReflector()
    ---@type generalMenuState
    local state = generalMenuStore:getState()
    -- Update general menu header
    local generalHeaderStrings = blam.unicodeStringList(const.unicodeStrings.generalMenuHeaderTagId)
    if (generalHeaderStrings) then
        local newStrings = generalHeaderStrings.stringList
        newStrings[1] = state.menu.title
        generalHeaderStrings.stringList = newStrings
    end

    -- Update general menu elements list count
    local elementsList = blam.uiWidgetDefinition(const.uiWidgetDefinitions.generalMenuList.id)
    if (elementsList) then
        -- Elements list count equals to number of elements plus 1 element for the back button
        local newElementsCount = #state.menu.currentElementsList + 1
        if (elementsList.childWidgetsCount ~= newElementsCount) then
            elementsList.childWidgetsCount = newElementsCount
            interface.update(const.uiWidgetDefinitions.generalMenuList, newElementsCount)
        end
    end
    local scrollBar = blam.uiWidgetDefinition(const.uiWidgetDefinitions.scrollBar.id)
    local scrollPosition = blam.uiWidgetDefinition(const.uiWidgetDefinitions.scrollPosition.id)
    if (scrollBar and scrollPosition) then
        local elementsCount = #state.menu.elementsList
        if (elementsCount > 0) then
            local barSizePerElement = glue.round(scrollBar.height / elementsCount)
            scrollPosition.height = barSizePerElement * state.menu.currentPage
            scrollPosition.boundsY = -barSizePerElement +
                                         (barSizePerElement * state.menu.currentPage)
        end
    end

    -- Update general menu elements strings
    local elementsStrings = blam.unicodeStringList(const.unicodeStrings.generalMenuStringsTagId)
    if (elementsStrings) then
        local newStrings = elementsStrings.stringList
        for elementIndex, element in pairs(newStrings) do
            newStrings[elementIndex] = state.menu.currentElementsList[elementIndex]
            -- dprint(state.menu.currentElementsList[elementIndex])
        end
        elementsStrings.stringList = newStrings
    end

    -- Update or hide elements list values
    local elementsStringsValues = blam.unicodeStringList(const.unicodeStrings
                                                             .generalMenuValueStringsTagId)
    local newStringsValues = elementsStringsValues.stringList
    if (#state.menu.elementsValues > 0) then
        local newValues = state.menu.elementsValues[state.menu.currentPage]
        for valueIndex, value in pairs(newValues) do
            newStringsValues[valueIndex] = core.toSentenceCase(tostring(value))
        end
    else
        for valueIndex, value in pairs(newStringsValues) do
            newStringsValues[valueIndex] = " "
        end
    end
    elementsStringsValues.stringList = newStringsValues
end

return generalMenuReflector

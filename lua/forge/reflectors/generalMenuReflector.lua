local function generalMenuReflector()
    ---@type generalMenuReducer
    local state = generalMenuStore:getState()
    local generalHeaderStrings = blam.unicodeStringList(const.unicodeStrings.generalMenuHeaderTagId)
    if (generalHeaderStrings) then
        local newStrings = generalHeaderStrings.stringList
        newStrings[1] = state.menu.title
        generalHeaderStrings.stringList = newStrings
    end

    local elementsList = blam.uiWidgetDefinition(const.uiWidgetDefinitions.generalMenuList.id)
    if (elementsList) then
        elementsList.childWidgetsCount = #state.menu.currentElementsList
    end

    local elementsStrings = blam.unicodeStringList(const.unicodeStrings.generalMenuStringsTagId)
    if (elementsStrings) then
        local newStrings = elementsStrings.stringList
        for elementIndex, element in pairs(state.menu.currentElementsList) do
            dprint(element)
            newStrings[elementIndex] = element
        end
        elementsStrings.stringList = newStrings
    end
    local elementsStringsValues = blam.unicodeStringList(const.unicodeStrings
                                                                 .generalMenuValueStringsTagId)
    local newStringsValues = elementsStringsValues.stringList
    for valueIndex, value in pairs(newStringsValues) do
        newStringsValues[valueIndex] = " "
    end
    elementsStringsValues.stringList = newStringsValues
end

return generalMenuReflector

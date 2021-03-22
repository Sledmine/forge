------------------------------------------------------------------------------
-- Voting Reflector
-- Sledmine
-- Function reflector for store
------------------------------------------------------------------------------
local glue = require "glue"

local menu = require "forge.menu"

local function votingReflector()
    -- Get current forge state
    ---@type votingState
    local votingState = votingStore:getState()

    local votesList = votingState.votingMenu.votesList

    for k, v in pairs(votesList) do
        votesList[k] = tostring(v)
    end

    -- [Voting Menu]

    -- Update maps string list
    local mapsList = votingState.votingMenu.mapsList

    -- Prevent errors objects does not exist
    if (not mapsList) then
        dprint("Current maps vote list is empty.", "warning")
        mapsList = {}
    end

    local currentMapsList = {}
    for mapIndex, map in pairs(mapsList) do
        glue.append(currentMapsList, map.name .. "\r" .. map.gametype)
    end

    -- Get maps vote menu buttons lists
    local votingMapsMenuList = blam.uiWidgetDefinition(constants.uiWidgetDefinitions.voteMenuList.id)
    votingMapsMenuList.childWidgetsCount = #glue.keys(currentMapsList)

    -- Get maps vote string list
    local votingMapsStrings = blam.unicodeStringList(constants.unicodeStrings.votingMapsListTagId)
    votingMapsStrings.stringList = currentMapsList

    -- Get maps vote count string list
    local votingCountListStrings = blam.unicodeStringList(constants.unicodeStrings.votingCountListTagId)
    votingCountListStrings.stringList = votesList

        -- // TODO Add count replacing for child widgets
end

return votingReflector

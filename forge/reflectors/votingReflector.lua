------------------------------------------------------------------------------
-- Voting Reflector
-- Sledmine
-- Function reflector for store
------------------------------------------------------------------------------
local glue = require "glue"

local menu = require "forge.menu"

local function votingReflector()
    -- Get current forge state
    local votingState = votingStore:getState()

    
    local votesList = votingState.votingMenu.votesList
    
    for k, v in pairs(votesList) do
        votesList[k] = tostring(v)
    end
    
    -- Voting Menu
    
    -- Get maps vote string list
    local unideStringListAddress = get_tag(tagClasses.unicodeStringList,
    constants.unicodeStrings.votingList)
    
    -- Update maps string list
    local mapsList = votingState.votingMenu.mapsList

    -- Prevent errors objects does not exist
    if (not mapsList) then
        dprint("Current maps vote list is empty.", "warning")
        mapsList = {}
    end
    
    local currentMapsList = {}
    for mapIndex, map in pairs (mapsList) do
        glue.append(currentMapsList, map.name .. "\r" .. map.gametype)
    end
    blam35.unicodeStringList(unideStringListAddress, {
        stringList = currentMapsList
    })

    unideStringListAddress = get_tag(tagClasses.unicodeStringList,
                                     constants.unicodeStrings.votingCountList)

    blam35.unicodeStringList(unideStringListAddress, {
        stringList = votesList
    })

end

return votingReflector

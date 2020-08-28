------------------------------------------------------------------------------
-- Voting Reflector
-- Sledmine
-- Function reflector for store
------------------------------------------------------------------------------

local menu = require "forge.menu"

local function votingReflector()
    -- Get current forge state
    local votingState = votingStore:getState()

    local currentMapsList = votingState.votingMenu.currentMapsList

    -- Prevent errors objects does not exist
    if (not currentMapsList) then
        dprint("Current maps vote list is empty.", "warning")
        currentMapsList = {}
    end

    local votesList = votingState.votingMenu.votesList

    for k, v in pairs(votesList) do
        votesList[k] = tostring(v)
    end

    -- Voting Menu

    -- Get maps vote string list
    local unideStringListAddress = get_tag(tagClasses.unicodeStringList,
                                           constants.unicodeStrings.votingList)

    -- Update string list
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

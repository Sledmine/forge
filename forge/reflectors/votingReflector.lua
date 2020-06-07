local blam = require 'lua-blam'

-- Global Halo Custom Edition libraries
local constants = require 'forge.constants'
local menu = require 'forge.menu'

local function forgeReflector()
    -- Get current forge state
    local votingState = votingStore:getState()

    local currentMapsList = votingState.votingMenu.currentMapsList

    -- Prevent errors objects does not exist
    if (not currentMapsList) then
        dprint('Current maps vote list is empty.', 'warning')
        currentMapsList = {}
    end

    local votesList = votingState.votingMenu.votesList
    
    for k,v in pairs (votesList) do
        votesList[k] = tostring(v)
    end

    -- Voting Menu

    -- Get maps vote string list
    local unideStringListAddress = get_tag(tagClasses.unicodeStringList, constants.unicodeStrings.votingList)

    -- Update string list
    blam.unicodeStringList(unideStringListAddress, {stringList = currentMapsList})

    unideStringListAddress =  get_tag(tagClasses.unicodeStringList, constants.unicodeStrings.votingCountList)

    blam.unicodeStringList(unideStringListAddress, {stringList = votesList})

end

return forgeReflector
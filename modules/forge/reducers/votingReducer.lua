-- Lua libraries
local inspect = require "inspect"
local glue = require "glue"

-- Forge modules
local menu = require "forge.menu"

---@class votingReducer
local defaultState = {
    votingMenu = {
        mapsList = {
            {
                name = "Begotten",
                gametype = "Team Slayer",
                mapIndex = 1
            },
            {
                name = "Octagon",
                gametype = "Slayer",
                mapIndex = 1
            },
            {
                name = "Strong Enough",
                gametype = "CTF",
                mapIndex = 1
            },
            {
                name = "Castle",
                gametype = "CTF",
                mapIndex = 1
            }
        },
        votesList = {0, 0, 0, 0}
    }
}

local function votingReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        state = glue.deepcopy(defaultState)
    end
    if (action.type) then
        dprint("-> [Voting Store]")
        dprint("Action: " .. action.type, "category")
    end
    if (action.type == constants.requests.appendVoteMap.actionType) then
        if (#state.votingMenu.mapsList < 4) then
            local map = action.payload.map
            glue.append(state.votingMenu.mapsList, map)
        end
        return state
    elseif (action.type == "SET_MAP_VOTES_LIST") then
        state.votingMenu.votesList = action.payload.votesList
        return state
    elseif (action.type == "FLUSH_MAP_VOTES") then
        state.votingMenu.mapsList = {}
        state.votingMenu.votesList = {0, 0, 0, 0}
        return state
    else
        if (action.type == "@@lua-redux/INIT") then
            dprint("Default state has been created!")
        else
            dprint("ERROR!!! The dispatched event does not exist:", "error")
        end
        return state
    end
end

return votingReducer

-- Lua libraries
local inspect = require "inspect"
local glue = require "glue"

-- Forge modules

local menu = require "forge.menu"

local function votingReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        state = {
            votingMenu = {
                mapsList = {
                    {
                        name = "Forge",
                        gametype = "Slayer"
                    },
                    {
                        name = "Forge",
                        gametype = "Slayer"
                    },
                    {
                        name = "Forge",
                        gametype = "Slayer"
                    },
                    {
                        name = "Forge",
                        gametype = "Slayer"
                    }
                },
                votesList = {0, 0, 0, 0}
            }
        }
    end
    if (action.type) then
        dprint("-> [Voting Store]")
        dprint("Action: " .. action.type, "category")
    end
    if (action.type == "APPEND_MAP_VOTE") then
        if (#state.votingMenu.mapsList < 4) then
            local map = action.payload.map
            glue.append(state.votingMenu.mapsList, map)
            dprint(inspect(state.votingMenu.mapsList))
        end
        return state
    elseif (action.type == "SET_MAP_VOTES_LIST") then
        dprint(inspect(action.payload.votesList))
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

-- Lua libraries
local inspect = require "inspect"
local glue = require "glue"

-- Forge modules
local constants = require "forge.constants"
local menu = require "forge.menu"

local function votingReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        state = {
            votingMenu = {
                mapsList = {
                    {
                        mapName = "Forge",
                        gametype = "Slayer"
                    },
                    {
                        mapName = "Forge",
                        gametype = "Slayer"
                    },
                    {
                        mapName = "Forge",
                        gametype = "Slayer"
                    },
                    {
                        mapName = "Forge",
                        gametype = "Slayer"
                    }
                },
                currentMapsList = {
                    "Octagon\rSlayer",
                    "Lockout\rCTF",
                    "Hemorrhage\rTeam Slayer",
                    "Begotten\rInfection"
                },
                currentPlayersList = {},
                votesList = {0, 0, 0, 0}
            }
        }
    end
    if (action.type) then
        dprint("Forge Store, dispatched event:")
        dprint(action.type, "category")
    end
    if (action.type == "UPDATE_VOTE_LIST") then
        state.votingMenu.mapsList = action.payload.mapsList
        dprint(inspect(state.votingMenu))
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

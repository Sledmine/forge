-- Lua libraries
local inspect = require "inspect"
local glue = require "glue"

---@class generalMenuReducer
local defaultState = {
    menu = {
        title = "General Menu",
        elementsList = {},
        currentElementsList = {},
        currentValues = {},
        currentPage = 1,
        sidebar = {
            height = 0,
            position = 0,
            slice = 0,
            overflow = 0
        }
    }
}

---@param state generalMenuReducer
local function generalMenuReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        -- Create default state if it does not exist
        state = glue.deepcopy(defaultState)
    end
    if (action.type) then
        dprint("[General Menu Reducer]")
        dprint("Action -> " .. action.type, "category")
    end
    if (action.type == "SET_MENU") then
        state.menu.title = action.payload.title
        state.menu.elementsList = glue.chunks(action.payload.elements, 8)
        state.menu.currentPage = 1
        state.menu.currentElementsList = state.menu.elementsList[state.menu.currentPage]
        return state
    else
        if (action.type == "@@lua-redux/INIT") then
            dprint("Default state has been created!")
        else
            dprint("ERROR!!! The dispatched event does not exist:", "error")
        end
        return state
    end
    return state
end

return generalMenuReducer

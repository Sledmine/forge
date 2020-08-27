-- Lua libraries
local glue = require "glue"
local inspect = require "inspect"
local constants = require "forge.constants"

-- Forge modules
local core = require "forge.core"
local features = require "forge.features"

local function eventsReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        state = {forgeObjects = {}}
    end
    if (action.type) then
        dprint("-> [Events Store]")
        dprint("Action: " .. action.type, "category")
    end
    if (action.type == constants.actionTypes.SPAWN_OBJECT) then
        dprint("SPAWNING object to store...", "warning")
        local requestObject = action.payload.requestObject

        -- Create a new object rather than passing it as "reference"
        local composedObject = glue.update({}, requestObject)

        local tagPath = get_tag_path(composedObject.tagId)

        -- Get all the existent objects in the game before object spawn
        local objectsBeforeSpawn = get_objects()

        -- Spawn object in the game
        local localObjectId = core.spawnObject("scen", tagPath, composedObject.x, composedObject.y,
                                               composedObject.z)

        -- Get all the existent objects in the game after object spawn
        local objectsAfterSpawn = get_objects()

        -- Tricky way to get object local id, due to Chimera 581 API returning a whole id instead of id
        -- Remember objectId is local to this game
        if (server_type ~= "sapp") then
            local newObjects = glue.arraynv(objectsBeforeSpawn, objectsAfterSpawn)
            localObjectId = newObjects[#newObjects]
        end

        -- Set object rotation after creating the object
        core.rotateObject(localObjectId, composedObject.yaw, composedObject.pitch,
                          composedObject.roll)

        -- Clean and prepare object
        -- composedObject.object = blam.object(get_object(localObjectId))
        composedObject.tagId = nil
        composedObject.requestType = nil
        composedObject.objectId = localObjectId

        -- We are the server so the remote id is the local objectId
        if (server_type == "local" or server_type == "sapp") then
            composedObject.remoteId = composedObject.objectId
        end

        dprint("objectId: " .. composedObject.objectId)
        dprint("remoteId: " .. composedObject.remoteId)

        -- Check and take actions if the object is a special netgame object
        if (tagPath:find("spawning")) then
            dprint("-> [Reflecting Spawn]", "warning")
            if (tagPath:find("gametypes")) then
                dprint("GAMETYPE_SPAWN", "category")
                -- Make needed modifications to game spawn points
                core.updatePlayerSpawnPoint(tagPath, composedObject)
            elseif (tagPath:find("vehicles") or tagPath:find("objects")) then
                core.updateVehicleSpawn(tagPath, composedObject)
            end
        elseif (tagPath:find("objectives")) then
            dprint("-> [Reflecting Flag]", "warning")
            core.updateNetgameFlagSpawnPoint(tagPath, composedObject)
        end

        -- As a server we have to send back a response/request to the players in the server
        if (server_type == "sapp") then
            local response = core.createRequest(composedObject)
            core.sendRequest(response)
        end

        -- Store the object in our state
        state.forgeObjects[localObjectId] = composedObject

        -- Update the current map information
        forgeStore:dispatch({
            type = "UPDATE_MAP_INFO"
        })

        return state
    elseif (action.type == constants.actionTypes.UPDATE_OBJECT) then
        local requestObject = action.payload.requestObject
        local targetObjectId =
            core.getObjectIdByRemoteId(state.forgeObjects, requestObject.objectId)
        local composedObject = state.forgeObjects[targetObjectId]

        if (composedObject) then
            dprint("UPDATING object from store...", "warning")
            composedObject.x = requestObject.x
            composedObject.y = requestObject.y
            composedObject.z = requestObject.z
            composedObject.yaw = requestObject.yaw
            composedObject.pitch = requestObject.pitch
            composedObject.roll = requestObject.roll

            -- Update object rotation
            core.rotateObject(composedObject.objectId, composedObject.yaw, composedObject.pitch,
                              composedObject.roll)

            -- Update object position
            blam.object(get_object(composedObject.objectId), {
                x = composedObject.x,
                y = composedObject.y,
                z = composedObject.z
            })

            -- Check and take actions if the object is reflecting a netgame point
            if (composedObject.reflectionId) then
                local tagPath = get_tag_path(targetObjectId)
                if (tagPath:find("spawning")) then
                    dprint("-> [Reflecting Spawn]", "warning")
                    if (tagPath:find("gametypes")) then
                        dprint("GAMETYPE_SPAWN", "category")
                        -- Make needed modifications to game spawn points
                        core.updatePlayerSpawnPoint(tagPath, composedObject)
                    elseif (tagPath:find("vehicles") or tagPath:find("objects")) then
                        core.updateVehicleSpawn(tagPath, composedObject)
                    end
                elseif (tagPath:find("objectives")) then
                    dprint("-> [Reflecting Flag]", "warning")
                    core.updateNetgameFlagSpawnPoint(tagPath, composedObject)
                end
            end

            -- As a server we have to send back a response/request to the players in the server
            if (server_type == "sapp") then
                local response = core.createRequest(composedObject)
                core.sendRequest(response)
            end
        else
            dprint("ERROR!!! The required object with Id: " .. requestObject.objectId ..
                       "does not exist.", "error")
        end
        return state
    elseif (action.type == constants.actionTypes.DELETE_OBJECT) then
        local requestObject = action.payload.requestObject
        local targetObjectId =
            core.getObjectIdByRemoteId(state.forgeObjects, requestObject.objectId)
        local composedObject = state.forgeObjects[targetObjectId]

        if (composedObject) then
            if (composedObject.reflectionId) then
                local tagPath = get_tag_path(targetObjectId)
                if (tagPath:find("spawning")) then
                    dprint("-> [Reflecting Spawn]", "warning")
                    if (tagPath:find("gametypes")) then
                        dprint("GAMETYPE_SPAWN", "category")
                        -- Make needed modifications to game spawn points
                        core.updatePlayerSpawnPoint(tagPath, composedObject, true)
                    elseif (tagPath:find("vehicles") or tagPath:find("objects")) then
                        core.updateVehicleSpawn(tagPath, composedObject, true)
                    end
                end
            end

            dprint("Deleting object from store...", "warning")
            -- // TODO: Add validation to this erasement!
            delete_object(composedObject.objectId)
            state.forgeObjects[targetObjectId] = nil
            dprint("Done.", "success")

            -- As a server we have to send back a response/request to the players in the server
            if (server_type == "sapp") then
                local response = core.createRequest(composedObject)
                core.sendRequest(response)
            end
        else
            dprint("ERROR!!! The required object with Id: " .. requestObject.objectId ..
                       "does not exist.", "error")
        end
        -- Update the current map information
        forgeStore:dispatch({
            type = "UPDATE_MAP_INFO"
        })

        return state
    elseif (action.type == constants.actionTypes.LOAD_MAP_SCREEN) then
        -- // TODO: This is not ok, this must be split in different reducers
        local requestObject = action.payload.requestObject

        local expectedObjects = requestObject.objectCount
        local mapName = requestObject.mapName
        local mapDescription = requestObject.mapDescription

        forgeStore:dispatch({
            type = "UPDATE_MAP_INFO",
            payload = {
                expectedObjects = expectedObjects,
                mapName = mapName,
                mapDescription = mapDescription
            }
        })

        -- // TODO: This does not end after finishing map loading
        set_timer(140, "forgeAnimation")

        features.openMenu(constants.uiWidgetDefinitions.loadingMenu)

        return state
    elseif (action.type == constants.actionTypes.FLUSH_FORGE) then
        state = {forgeObjects = {}}
        return state
    else
        if (action.type == "@@lua-redux/INIT") then
            dprint("Default state has been created!")
        else
            dprint("ERROR!!! The dispatched event does not exist.", "error")
        end
        return state
    end
end

return eventsReducer

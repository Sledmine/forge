-- Lua libraries
local glue = require "glue"
local inspect = require "inspect"


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
    if (action.type == constants.requests.spawnObject.actionType) then
        dprint("SPAWNING object to store...", "warning")
        local requestObject = action.payload.requestObject

        -- Create a new object rather than passing it as "reference"
        local forgeObject = glue.update({}, requestObject)

        local tagPath = get_tag_path(requestObject.tagId)

        -- Get all the existent objects in the game before object spawn
        local objectsBeforeSpawn = get_objects()

        -- Spawn object in the game
        local localObjectId = core.spawnObject("scen", tagPath, forgeObject.x, forgeObject.y,
                                               forgeObject.z)

        -- Get all the existent objects in the game after object spawn
        local objectsAfterSpawn = get_objects()

        -- Tricky way to get object local id, due to Chimera 581 API returning a whole id instead of id
        -- Remember objectId is local to this game
        if (server_type ~= "sapp") then
            local newObjects = glue.arraynv(objectsBeforeSpawn, objectsAfterSpawn)
            localObjectId = newObjects[#newObjects]
        end

        -- Set object rotation after creating the object
        core.rotateObject(localObjectId, forgeObject.yaw, forgeObject.pitch, forgeObject.roll)

        -- We are the server so the remote id is the local objectId
        if (server_type == "local" or server_type == "sapp") then
            forgeObject.remoteId = localObjectId
        end

        dprint("objectId: " .. localObjectId)
        dprint("remoteId: " .. forgeObject.remoteId)

        -- Check and take actions if the object is a special netgame object
        if (tagPath:find("spawning")) then
            dprint("-> [Reflecting Spawn]", "warning")
            if (tagPath:find("gametypes")) then
                dprint("GAMETYPE_SPAWN", "category")
                -- Make needed modifications to game spawn points
                core.updatePlayerSpawnPoint(tagPath, forgeObject)
            elseif (tagPath:find("vehicles") or tagPath:find("objects")) then
                dprint("VEHICLE_SPAWN", "category")
                core.updateVehicleSpawn(tagPath, forgeObject)
            elseif (tagPath:find("weapons")) then
                dprint("WEAPON_SPAWN", "category")
                core.updateNetgameEquipmentSpawnPoint(tagPath, forgeObject)
            end
        elseif (tagPath:find("objectives")) then
            dprint("-> [Reflecting Flag]", "warning")
            core.updateNetgameFlagSpawnPoint(tagPath, forgeObject)
        end
        
        -- Clean and prepare object
        forgeObject.tagId = nil
        
        -- Store the object in our state
        state.forgeObjects[localObjectId] = forgeObject
        
        -- As a server we have to send back a response/request to the players in the server
        if (server_type == "sapp") then
            local response = core.createRequest(forgeObject)
            core.sendRequest(response)
        end

        -- Update the current map information
        forgeStore:dispatch({
            type = "UPDATE_MAP_INFO"
        })

        return state
    elseif (action.type == constants.requests.updateObject.actionType) then
        local requestObject = action.payload.requestObject
        local targetObjectId =
            core.getObjectIdByRemoteId(state.forgeObjects, requestObject.objectId)
        local forgeObject = state.forgeObjects[targetObjectId]

        if (forgeObject) then
            dprint("UPDATING object from store...", "warning")

            forgeObject.x = requestObject.x
            forgeObject.y = requestObject.y
            forgeObject.z = requestObject.z
            forgeObject.yaw = requestObject.yaw
            forgeObject.pitch = requestObject.pitch
            forgeObject.roll = requestObject.roll

            -- Update object rotation
            core.rotateObject(targetObjectId, forgeObject.yaw, forgeObject.pitch,
                              forgeObject.roll)

            -- Update object position
            blam35.object(get_object(targetObjectId), {
                x = forgeObject.x,
                y = forgeObject.y,
                z = forgeObject.z
            })

            -- Check and take actions if the object is reflecting a netgame point
            if (forgeObject.reflectionId) then
                console_out("Reflection id:")
                local tempObject = blam35.object(get_object(targetObjectId))
                local tagPath = get_tag_path(tempObject.tagId)
                if (tagPath:find("spawning")) then
                    dprint("-> [Reflecting Spawn]", "warning")
                    if (tagPath:find("gametypes")) then
                        dprint("GAMETYPE_SPAWN", "category")
                        -- Make needed modifications to game spawn points
                        core.updatePlayerSpawnPoint(tagPath, forgeObject)
                    elseif (tagPath:find("vehicles") or tagPath:find("objects")) then
                        dprint("VEHICLE_SPAWN", "category")
                        core.updateVehicleSpawn(tagPath, forgeObject)
                    elseif (tagPath:find("weapons")) then
                        dprint("WEAPON_SPAWN", "category")
                        core.updateNetgameEquipmentSpawnPoint(tagPath, forgeObject)
                    end
                elseif (tagPath:find("objectives")) then
                    dprint("-> [Reflecting Flag]", "warning")
                    core.updateNetgameFlagSpawnPoint(tagPath, forgeObject)
                end
            end

            -- As a server we have to send back a response/request to the players in the server
            if (server_type == "sapp") then
                print(inspect(requestObject))
                local response = core.createRequest(requestObject)
                core.sendRequest(response)
            end
        else
            dprint("ERROR!!! The required object with Id: " .. requestObject.objectId ..
                       "does not exist.", "error")
        end
        return state
    elseif (action.type == constants.requests.deleteObject.actionType) then
        local requestObject = action.payload.requestObject
        local targetObjectId =
            core.getObjectIdByRemoteId(state.forgeObjects, requestObject.objectId)
        local forgeObject = state.forgeObjects[targetObjectId]

        if (forgeObject) then
            if (forgeObject.reflectionId) then
                local tempObject = blam35.object(get_object(targetObjectId))
                local tagPath = get_tag_path(tempObject.tagId)
                if (tagPath:find("spawning")) then
                    dprint("-> [Reflecting Spawn]", "warning")
                    if (tagPath:find("gametypes")) then
                        dprint("GAMETYPE_SPAWN", "category")
                        -- Make needed modifications to game spawn points
                        core.updatePlayerSpawnPoint(tagPath, forgeObject, true)
                    elseif (tagPath:find("vehicles") or tagPath:find("objects")) then
                        dprint("VEHICLE_SPAWN", "category")
                        core.updateVehicleSpawn(tagPath, forgeObject, true)
                    elseif (tagPath:find("weapons")) then
                        dprint("WEAPON_SPAWN", "category")
                        core.updateNetgameEquipmentSpawnPoint(tagPath, forgeObject, true)
                    end
                end
            end

            dprint("Deleting object from store...", "warning")
            -- // TODO: Add validation to this erasement!
            delete_object(targetObjectId)
            state.forgeObjects[targetObjectId] = nil
            dprint("Done.", "success")

            -- As a server we have to send back a response/request to the players in the server
            if (server_type == "sapp") then
                local response = core.createRequest(requestObject)
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
    elseif (action.type == constants.requests.loadMapScreen.actionType) then
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
        -- // FIXME: We need a request for this just in case!
    elseif (action.type == "FLUSH_FORGE") then
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

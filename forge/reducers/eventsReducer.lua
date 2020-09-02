-- Lua libraries
local glue = require "glue"
local inspect = require "inspect"

-- Forge modules
local core = require "forge.core"
local features = require "forge.features"

local function eventsReducer(state, action)
    -- Create default state if it does not exist
    if (not state) then
        state = {
            forgeObjects = {},
            playerVotes = {},
            mapsList = {
                {
                    mapName = "Begotten",
                    mapGametype = "Team Slayer",
                    mapIndex = 1
                },
                {
                    mapName = "Octagon",
                    mapGametype = "Slayer",
                    mapIndex = 1
                },
                {
                    mapName = "Strong Enough",
                    mapGametype = "CTF",
                    mapIndex = 1
                },
                {
                    mapName = "Castle",
                    mapGametype = "CTF",
                    mapIndex = 1
                }
            }
        }
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
                core.updatePlayerSpawn(tagPath, forgeObject)
            elseif (tagPath:find("vehicles") or tagPath:find("objects")) then
                dprint("VEHICLE_SPAWN", "category")
                core.updateVehicleSpawn(tagPath, forgeObject)
            elseif (tagPath:find("weapons")) then
                dprint("WEAPON_SPAWN", "category")
                core.updateNetgameEquipmentSpawn(tagPath, forgeObject)
            end
        elseif (tagPath:find("objectives")) then
            dprint("-> [Reflecting Flag]", "warning")
            core.updateNetgameFlagSpawn(tagPath, forgeObject)
        end

        -- As a server we have to send back a response/request to the players in the server
        if (server_type == "sapp") then
            local response = core.createRequest(forgeObject)
            core.sendRequest(response)
        end

        -- Clean and prepare object
        forgeObject.tagId = nil

        -- Store the object in our state
        state.forgeObjects[localObjectId] = forgeObject

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
            core.rotateObject(targetObjectId, forgeObject.yaw, forgeObject.pitch, forgeObject.roll)

            -- Update object position
            blam35.object(get_object(targetObjectId), {
                x = forgeObject.x,
                y = forgeObject.y,
                z = forgeObject.z
            })

            -- Check and take actions if the object is reflecting a netgame point
            if (forgeObject.reflectionId) then
                local tempObject = blam35.object(get_object(targetObjectId))
                local tagPath = get_tag_path(tempObject.tagId)
                if (tagPath:find("spawning")) then
                    dprint("-> [Reflecting Spawn]", "warning")
                    if (tagPath:find("gametypes")) then
                        dprint("GAMETYPE_SPAWN", "category")
                        -- Make needed modifications to game spawn points
                        core.updatePlayerSpawn(tagPath, forgeObject)
                    elseif (tagPath:find("vehicles") or tagPath:find("objects")) then
                        dprint("VEHICLE_SPAWN", "category")
                        core.updateVehicleSpawn(tagPath, forgeObject)
                    elseif (tagPath:find("weapons")) then
                        dprint("WEAPON_SPAWN", "category")
                        core.updateNetgameEquipmentSpawn(tagPath, forgeObject)
                    end
                elseif (tagPath:find("objectives")) then
                    dprint("-> [Reflecting Flag]", "warning")
                    core.updateNetgameFlagSpawn(tagPath, forgeObject)
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
                        core.updatePlayerSpawn(tagPath, forgeObject, true)
                    elseif (tagPath:find("vehicles") or tagPath:find("objects")) then
                        dprint("VEHICLE_SPAWN", "category")
                        core.updateVehicleSpawn(tagPath, forgeObject, true)
                    elseif (tagPath:find("weapons")) then
                        dprint("WEAPON_SPAWN", "category")
                        core.updateNetgameEquipmentSpawn(tagPath, forgeObject, true)
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
    elseif (action.type == constants.requests.flushForge.actionType) then
        state.forgeObjects = {}
        return state
    elseif (action.type == constants.requests.loadVoteMapScreen.actionType) then
        if (server_type ~= "sapp") then
            function preventClose()
                features.openMenu(constants.uiWidgetDefinitions.voteMenu)
                return false
            end
            set_timer(5000, "preventClose")
        else
            -- Send vote map menu open request
            local loadMapVoteMenuRequest = {
                requestType = constants.requests.loadVoteMapScreen.requestType
            }
            core.sendRequest(core.createRequest(loadMapVoteMenuRequest))
            -- Send list of all available vote maps
            for mapIndex, map in pairs(state.mapsList) do
                local voteMapOpenRequest = {
                    requestType = constants.requests.appendVoteMap.requestType
                }
                glue.update(voteMapOpenRequest, map)
                core.sendRequest(core.createRequest(voteMapOpenRequest))
            end
        end
        return state
    elseif (action.type == constants.requests.appendVoteMap.actionType) then
        if (server_type ~= "sapp") then
            local params = action.payload.requestObject
            votingStore:dispatch({
                type = "APPEND_MAP_VOTE",
                payload = {
                    map = {
                        name = params.mapName,
                        gametype = params.mapGametype
                    }
                }
            })
        end
        return state
    elseif (action.type == constants.requests.sendTotalMapVotes.actionType) then
        if (server_type == "sapp") then
            local mapVotes = {0, 0, 0, 0}
            for playerIndex, mapIndex in pairs(state.playerVotes) do
                mapVotes[mapIndex] = mapVotes[mapIndex] + 1
            end
            -- Send vote map menu open request
            local sendTotalMapVotesRequest = {
                requestType = constants.requests.sendTotalMapVotes.requestType

            }
            for mapIndex, votes in pairs(mapVotes) do
                sendTotalMapVotesRequest["votesMap" .. mapIndex] = votes
            end
            core.sendRequest(core.createRequest(sendTotalMapVotesRequest))
        else
            local params = action.payload.requestObject
            local votesList = {params.votesMap1, params.votesMap2, params.votesMap3, params.votesMap4}
            votingStore:dispatch({type = "SET_MAP_VOTES_LIST", payload = {votesList = votesList}})
        end
        return state
    elseif (action.type == constants.requests.sendMapVote.actionType) then
        -- // TODO: Add vote map logic to handle player votes
        if (action.playerIndex and server_type == "sapp") then
            local playerName = get_var(action.playerIndex, "$name")
            if (not state.playerVotes[action.playerIndex]) then
                local params = action.payload.requestObject
                state.playerVotes[action.playerIndex] = params.mapVoted
                local mapName = state.mapsList[params.mapVoted].mapName
                local mapGametype = state.mapsList[params.mapVoted].mapGametype
                gprint(playerName .. " voted for " .. mapName .. " " .. mapGametype)
                eventsStore:dispatch({
                    type = constants.requests.sendTotalMapVotes.actionType
                })
                print(inspect(state))
            end
        end
        return state
    elseif (action.type == constants.requests.flushVotes.actionType) then
        state.playerVotes = {}
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

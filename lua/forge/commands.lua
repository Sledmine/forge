------------------------------------------------------------------------------
-- Forge Commands
-- Sledmine
-- Commands values
------------------------------------------------------------------------------
local inspect = require "inspect"
local glue = require "glue"

local core = require "forge.core"
local features = require "forge.features"

local function forgeCommands(command)
    if (command == "fdebug") then
        debugBuffer = nil
        config.forge.debugMode = not config.forge.debugMode
        features.hideReflectionObjects()
        -- Force settings menu update
        console_out("Debug mode: " .. tostring(config.forge.debugMode))
        return false
    else
        -- Split all the data in the command input
        local splitCommand = glue.string.split(command, " ")

        -- Substract first console command
        local forgeCommand = splitCommand[1]

        if (forgeCommand == "fstep") then
            local newRotationStep = tonumber(splitCommand[2])
            if (newRotationStep) then
                features.printHUD("Rotation step now is " .. newRotationStep .. " degrees.")
                playerStore:dispatch({
                    type = "SET_ROTATION_STEP",
                    payload = {step = newRotationStep}
                })
            else
                playerStore:dispatch({type = "SET_ROTATION_STEP", payload = {step = 3}})
            end
            return false
        elseif (forgeCommand == "fdis" or forgeCommand == "fdistance") then
            local newDistance = tonumber(splitCommand[2])
            if (newDistance) then
                features.printHUD("Distance from object has been set to " .. newDistance ..
                                      " units.")
                -- Force distance object update
                playerStore:dispatch({type = "SET_LOCK_DISTANCE", payload = {lockDistance = true}})
                local distance = glue.round(newDistance)
                playerStore:dispatch({type = "SET_DISTANCE", payload = {distance = distance}})
            else
                local distance = 3
                playerStore:dispatch({type = "SET_DISTANCE", payload = {distance = distance}})
            end
            return false
        elseif (forgeCommand == "fsave") then
            core.saveForgeMap()
            return false
        elseif (forgeCommand == "fsnap") then
            config.forge.snapMode = not config.forge.snapMode
            console_out("Snap Mode: " .. tostring(config.forge.snapMode))
            core.saveConfiguration()
            return false
        elseif (forgeCommand == "fauto") then
            config.forge.autoSave = not config.forge.autoSave
            console_out("Auto Save: " .. tostring(config.forge.autoSave))
            core.saveConfiguration()
            return false
        elseif (forgeCommand == "fcast") then
            config.forge.objectsCastShadow = not config.forge.objectsCastShadow
            local objectsCastShadow = config.forge.objectsCastShadow
            ---@type eventsState
            local eventsState = eventsStore:getState()
            for objectIndex, forgeObject in pairs(eventsState.forgeObjects) do
                local object = blam.object(get_object(objectIndex))
                if (object) then
                    if (objectsCastShadow) then
                        core.forceShadowCasting(object)
                    else
                        object.isNotCastingShadow = true
                    end
                end
            end
            core.saveConfiguration()
            console_out("Objects Cast Shadow: " .. tostring(config.forge.objectsCastShadow))
            return false
        elseif (forgeCommand == "fload") then
            local mapName = table.concat(glue.shift(splitCommand, 1, -1), " ")
            if (mapName) then
                core.loadForgeMap(mapName)
            else
                console_out("You must specify a forge map name.")
            end
            return false
        elseif (forgeCommand == "flist") then
            local mapsFiles = list_directory(defaultMapsPath)
            for fileIndex, file in pairs(mapsFiles) do
                console_out(file)
            end
            return false
        elseif (forgeCommand == "fname") then
            local mapName = table.concat(glue.shift(splitCommand, 1, -1), " "):gsub(",", " ")
            forgeStore:dispatch({type = "SET_MAP_NAME", payload = {mapName = mapName}})
            return false
        elseif (forgeCommand == "fdesc") then
            local mapDescription = table.concat(glue.shift(splitCommand, 1, -1), " "):gsub(",", " ")
            forgeStore:dispatch({
                type = "SET_MAP_DESCRIPTION",
                payload = {mapDescription = mapDescription}
            })
            return false
        elseif (forgeCommand == "fspawn" and server_type == "local") then
            -- Get scenario data
            local scenario = blam.scenario(0)

            -- Get scenario player spawn points
            local mapSpawnPoints = scenario.spawnLocationList

            mapSpawnPoints[1].type = 12

            scenario.spawnLocationList = mapSpawnPoints
            return false
            -------------- DEBUGGING COMMANDS ONLY ---------------
        elseif (config.forge.debugMode) then
            if (forgeCommand == "fmenu") then
                votingStore:dispatch({
                    type = "APPEND_MAP_VOTE",
                    payload = {map = {name = "Forge", gametype = "Slayer"}}
                })
                features.openMenu(const.uiWidgetDefinitions.voteMenu.path)
                return false
            elseif (forgeCommand == "fsize") then
                dprint(collectgarbage("count") / 1024)
                return false
            elseif (forgeCommand == "fconfig") then
                loadForgeConfiguration()
                return false
            elseif (forgeCommand == "fweap") then
                local weaponsList = {}
                for tagId = 0, blam.tagDataHeader.count - 1 do
                    local tempTag = blam.getTag(tagId)
                    if (tempTag and tempTag.class == tagClasses.weapon) then
                        local splitPath = glue.string.split(tempTag.path, "\\")
                        local weaponTagName = splitPath[#splitPath]
                        weaponsList[weaponTagName] = tempTag.path
                    end
                end
                local weaponName = table.concat(glue.shift(splitCommand, 1, -1), " ")
                local player = blam.biped(get_dynamic_player())
                local weaponResult = weaponsList[weaponName]
                if (weaponResult) then
                    local weaponObjectId = core.spawnObject(tagClasses.weapon, weaponResult,
                                                            player.x, player.y, player.z + 0.5)
                end
                return false
            elseif (forgeCommand == "ftest") then
                -- Run unit testing
                if (config.forge.debugMode) then
                    local tests = require "forge.tests"
                    tests.run(true)
                    return false
                end
            elseif (forgeCommand == "fbiped") then
                local player = blam.player(get_player())
                if (player) then
                    local playerBiped = blam.object(get_object(player.objectId))
                    if (playerBiped) then
                        local bipedName = table.concat(glue.shift(splitCommand, 1, -1), " ")
                        for tagIndex = 0, blam.tagDataHeader.count - 1 do
                            local tag = blam.getTag(tagIndex)
                            if (tag.class == tagClasses.biped) then
                                local pathSplit = glue.string.split(tag.path, "\\")
                                local tagName = pathSplit[#pathSplit]
                                if (tagName == bipedName) then
                                    console_out("Changing biped...")
                                    local globals = blam.globalsTag()
                                    if (globals) then
                                        local newMpInfo = globals.multiplayerInformation
                                        newMpInfo[1].unit = tag.id
                                        -- Update globals tag data to set new biped
                                        globals.multiplayerInformation = newMpInfo
                                        -- Erase player object to force biped respawn
                                        delete_object(player.objectId)
                                        return false
                                    end
                                end
                            end
                        end
                    end
                end
                dprint("Error, biped tag was not found on the map!")
                return false
            elseif (forgeCommand == "fdump") then
                write_file("player_dump.lua", inspect(playerStore:getState()))
                write_file("forge_dump.lua", inspect(forgeStore:getState()))
                write_file("events_dump.lua", inspect(eventsStore:getState()))
                write_file("voting_dump.lua", inspect(votingStore:getState()))
                write_file("general_menu_dump.lua", inspect(generalMenuStore:getState()))
                write_file("constants.lua", inspect(const))
                write_file("debug_dump.txt", debugBuffer or "No debug messages to print.")
                dprint("Done, dumped forge reducers to files.")
                return false
            elseif (forgeCommand == "fixmaps") then
                --[[local mapsFiles = list_directory(defaultMapsPath)
                for fileIndex, file in pairs(mapsFiles) do
                    if (not file:find("\\")) then
                        local fmapContent = read_file(defaultMapsPath .. "\\" .. file)
                        local forgeMapPath = defaultMapsPath .. "\\fix\\" .. file:lower()
                        write_file(forgeMapPath, fmapContent)
                    end
                end]]
                return false
            elseif (forgeCommand == "fprint") then
                dprint("[Game Objects]", "category")
                local objects = blam.getObjects()
                dprint("Count: " .. #objects)
                dprint(inspect(objects))

                dprint("[Objects Store]", "category")
                local storeObjects = glue.keys(eventsStore:getState().forgeObjects)
                dprint("Count: " .. #storeObjects)
                dprint(inspect(storeObjects))

                dprint("[Objects Database]", "category")
                local objectsDatabase = glue.keys(forgeStore:getState().forgeMenu.objectsDatabase)
                dprint("Count: " .. #objectsDatabase)
                dprint(inspect(objectsDatabase))

                return false
            elseif (forgeCommand == "fblam") then
                console_out("lua-blam " .. blam._VERSION)
                return false
            elseif (forgeCommand == "fspeed") then
                local newSpeed = tonumber(table.concat(glue.shift(splitCommand, 1, -1), " "))
                if (newSpeed) then
                    local player = get_player()
                    write_float(player + 0x6C, newSpeed)
                end
                return false
            elseif (forgeCommand == "fpos") then
                local playerBiped = blam.object(get_dynamic_player())
                if (playerBiped) then
                    console_out(("%s,%s,%s"):format(playerBiped.x, playerBiped.y, playerBiped.z))
                end
                return false
            elseif (forgeCommand == "frot") then
                local yaw = splitCommand[2]
                local pitch = splitCommand[3]
                local roll = splitCommand[4]
                dprint(("%s: %s: %s:"):format(yaw, pitch, roll))
                local rotation, matrix = core.eulerToRotation(yaw, pitch, roll)
                dprint("ROTATION:")
                dprint(inspect(rotation))
                dprint("MATRIX:")
                dprint(inspect(matrix[1]))
                dprint(inspect(matrix[2]))
                dprint(inspect(matrix[3]))
                return false
            elseif (forgeCommand == "fdialog") then
                features.overrideDialog("Kono giorno giovanna niwa yume ga aru",
                                        "Sexy... isn't?\rOH YEAH BOI")
            end
        end
    end
    return true
end

return forgeCommands

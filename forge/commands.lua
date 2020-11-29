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
        configuration.forge.debugMode = not configuration.forge.debugMode
        configuration.forge.debugMode = configuration.forge.debugMode
        console_out("Debug mode: " .. tostring(configuration.forge.debugMode))
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
                    payload = {
                        step = newRotationStep
                    }
                })
            else
                playerStore:dispatch({
                    type = "SET_ROTATION_STEP",
                    payload = {step = 3}
                })
            end
            return false
        elseif (forgeCommand == "fdis" or forgeCommand == "fdistance") then
            local newDistance = tonumber(splitCommand[2])
            if (newDistance) then
                features.printHUD("Distance from object has been set to " .. newDistance ..
                                      " units.")
                -- Force distance object update
                playerStore:dispatch({
                    type = "SET_LOCK_DISTANCE",
                    payload = {
                        lockDistance = true
                    }
                })
                local distance = glue.round(newDistance)
                playerStore:dispatch({
                    type = "SET_DISTANCE",
                    payload = {
                        distance = distance
                    }
                })
            else
                local distance = 3
                playerStore:dispatch({
                    type = "SET_DISTANCE",
                    payload = {
                        distance = distance
                    }
                })
            end
            return false
        elseif (forgeCommand == "fsave") then
            core.saveForgeMap()
            return false
        elseif (forgeCommand == "fsnap") then
            configuration.forge.snapMode = not configuration.forge.snapMode
            console_out("Snap Mode: " .. tostring(configuration.forge.snapMode))
            return false
        elseif (forgeCommand == "fauto") then
            configuration.forge.autoSave = not configuration.forge.autoSave
            console_out("Auto Save: " .. tostring(configuration.forge.autoSave))
            return false
        elseif (forgeCommand == "fcast") then
            configuration.forge.objectsCastShadow = not configuration.forge.objectsCastShadow
            console_out("Objects Cast Shadow: " .. tostring(configuration.forge.objectsCastShadow))
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
            forgeStore:dispatch({
                type = "SET_MAP_NAME",
                payload = {mapName = mapName}
            })
            return false
        elseif (forgeCommand == "fdesc") then
            local mapDescription = table.concat(glue.shift(splitCommand, 1, -1), " "):gsub(",", " ")
            forgeStore:dispatch({
                type = "SET_MAP_DESCRIPTION",
                payload = {
                    mapDescription = mapDescription
                }
            })
            return false
            -------------- DEBUGGING COMMANDS ONLY ---------------
        elseif (forgeCommand == "fmenu") then
            votingStore:dispatch({
                type = "APPEND_MAP_VOTE",
                payload = {
                    map = {
                        name = "Forge",
                        gametype = "Slayer"
                    }
                }
            })
            features.openMenu("[shm]\\halo_4\\ui\\shell\\map_vote_menu\\map_vote_menu")
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
                local weaponObjectId = core.spawnObject(tagClasses.weapon, weaponResult, player.x,
                                                        player.y, player.z + 0.5)
            end
            return false
        elseif (forgeCommand == "ftest") then
            -- Run unit testing
            if (configuration.forge.debugMode) then
                local tests = require "forge.tests"
                tests.run(true)
                return false
            end
        elseif (forgeCommand == "ftable") then
            -- Run unit testing
            console_out(blam.readUnicodeString(get_player() + 0x4), true)
            console_out(get_player())
            return false
        elseif (forgeCommand == "fbiped") then
            local tagsList = {}
            for tagId = 0, blam.tagDataHeader.count - 1 do
                local tempTag = blam.getTag(tagId)
                if (tempTag and tempTag.class == tagClasses.biped) then
                    local tagPath = tempTag.path
                    local splitPath = glue.string.split(tagPath, "\\")
                    local tagPathName = splitPath[#splitPath]
                    tagsList[tagPathName] = tagPath
                end
            end

            local bipedTagName = table.concat(glue.shift(splitCommand, 1, -1), " ")
            local player = blam.biped(get_dynamic_player())
            local tagPathResult = tagsList[bipedTagName]
            if (tagPathResult) then
                local objectId = core.spawnObject(tagClasses.biped, tagPathResult, player.x,
                                                  player.y, player.z + 0.5)
                local player = blam.biped(get_object(objectId))
            end
            return false
        elseif (forgeCommand == "fdump") then
            write_file("player_dump.json", inspect(playerStore:getState()))
            write_file("forge_dump.json", inspect(forgeStore:getState()))
            write_file("events_dump.json", inspect(eventsStore:getState()))
            write_file("voting_dump.json", inspect(votingStore:getState()))
            write_file("debug_dump.txt", debugBuffer)
            return false
        elseif (forgeCommand == "fixmaps") then
            --[[local json = require "json"
            for mapName in hfs.dir(forgeMapsFolder) do
                if (mapName ~= "." and mapName ~= "..") then
                    local fmapContent = read_file(forgeMapsFolder .. "\\" .. mapName)
                    if (fmapContent) then
                        local forgeMap = json.decode(fmapContent)
                        if (forgeMap) then
                            --local fixedObjects = {}
                            for objectIndex, object in pairs(forgeMap.objects) do
                                object.roll, object.pitch = object.pitch, object.roll
                                --glue.append(fixedObjects, object)
                            end
                            --forgeMap.objects = fixedObjects
                        end
                        -- Encode map info as json
                        local fmapContent = json.encode(forgeMap)
                        local forgeMapPath = forgeMapsFolder .. "\\fix\\" .. mapName
                        write_file(forgeMapPath, fmapContent)
                    end
                end
            end]]
            return false
        elseif (forgeCommand == "fprint") then
            -- Testing rcon communication
            dprint("[Game Objects]", "category")

            local objects = blam.getObjects()

            -- Debug in game objects count
            dprint("Count: " .. #objects)

            -- Debug list of all the in game objects
            dprint(inspect(objects))

            dprint("[Objects Store]", "category")

            local storeObjects = glue.keys(eventsStore:getState().forgeObjects)

            -- Debug store objects count
            dprint("Count: " .. #storeObjects)

            -- Debug list of all the store objects
            dprint(inspect(storeObjects))

            return false
        elseif (forgeCommand == "fblam") then
            dprint(constants.bipeds)
            console_out("lua-blam " .. blam.version)
            return false
        elseif (forgeCommand == "fspeed") then
            local newSpeed = tonumber(table.concat(glue.shift(splitCommand, 1, -1), " "))
            if (newSpeed) then
                local player = get_player()
                write_float(player + 0x6C, newSpeed)
            end
            return false
        elseif (forgeCommand == "fspawn") then
            -- Get scenario data
            local scenario = blam.scenario(0)

            -- Get scenario player spawn points
            local mapSpawnPoints = scenario.spawnLocationList

            mapSpawnPoints[1].type = 12

            scenario.spawnLocationList = mapSpawnPoints
            return false
        end
    end
    return true
end

return forgeCommands

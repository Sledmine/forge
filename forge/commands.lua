local inspect = require "inspect"
local glue = require "glue"

local core = require "forge.core"
local features = require "forge.features"

local function forgeCommands(command)
    if (command == "fdebug") then
        debugMode = not debugMode
        configuration.debugMode = debugMode
        console_out("Debug mode: " .. tostring(debugMode))
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
            configuration.snapMode = not configuration.snapMode
            console_out("Snap Mode: " .. tostring(configuration.snapMode))
            return false
        elseif (forgeCommand == "fauto") then
            configuration.autoSave = not configuration.autoSave
            console_out("Auto Save: " .. tostring(configuration.autoSave))
            return false
        elseif (forgeCommand == "fcast") then
            configuration.objectsCastShadow = not configuration.objectsCastShadow
            console_out("Objects Cast Shadow: " .. tostring(configuration.objectsCastShadow))
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
            for file in hfs.dir(forgeMapsFolder) do
                if (file ~= "." and file ~= "..") then
                    console_out(file)
                end
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
            features.openMenu("[shm]\\halo_4\\ui\\shell\\map_vote_menu\\map_vote_menu")
            return false
        elseif (forgeCommand == "fweaps") then
            for tagId = 0, get_tags_count() - 1 do
                local tagType = get_tag_type(tagId)
                if (tagType == tagClasses.weapon) then
                    local tagPath = get_tag_path(tagId)
                    console_out(tagPath)
                end
            end
            return false
        elseif (forgeCommand == "fit") then
            for objectId = 0, #get_objects() - 1 do
                local tempObject = blam35.object(get_object(objectId))
                if (tempObject and tempObject.type == objectClasses.weapon) then
                    delete_object(objectId)
                end
            end
            for tagId = 0, get_tags_count() - 1 do
                local tagType = get_tag_type(tagId)
                if (tagType == tagClasses.itemCollection) then
                    local tagPath = get_tag_path(tagId)
                    console_out(tagPath .. " " .. tagId)
                end
            end
            return false
        elseif (forgeCommand == "fonts") then
            for tagId = 0, get_tags_count() - 1 do
                local tagType = get_tag_type(tagId)
                if (tagType == tagClasses.font) then
                    local tagPath = get_tag_path(tagId)
                    console_out(tagPath .. " " .. tagId)
                end
            end
        elseif (forgeCommand == "fsize") then
            dprint(collectgarbage("count") / 1024)
            return false
        elseif (forgeCommand == "fconfig") then
            loadForgeConfiguration()
            return false
        elseif (forgeCommand == "fweap") then
            local weaponsList = {}
            for tagId = 0, get_tags_count() - 1 do
                local tagType = get_tag_type(tagId)
                if (tagType == tagClasses.weapon) then
                    local tagPath = get_tag_path(tagId)
                    local splitPath = glue.string.split(tagPath, "\\")
                    local weaponTagName = splitPath[#splitPath]
                    weaponsList[weaponTagName] = tagPath
                end
            end

            local weaponName = table.concat(glue.shift(splitCommand, 1, -1), " ")
            local player = blam.biped(get_dynamic_player())
            local weaponResult = weaponsList[weaponName]
            if (weaponResult) then
                local weaponObjectId = core.spawnObject(tagClasses.weapon, weaponResult, player.x, player.y, player.z + 0.5)
            end
            return false
        elseif (forgeCommand == "ftest") then
            -- Run unit testing
            if (debugMode) then
                local tests = require "forge.tests"
                tests.run(true)
                return false
            end
        elseif (forgeCommand == "fbiped") then
            local player = blam.biped(get_dynamic_player())
            console_out(player.weaponId)
            return false
        elseif (forgeCommand == "fobject") then
            local weaponsList = {}
            for tagId = 0, get_tags_count() - 1 do
                local tagType = get_tag_type(tagId)
                if (tagType == tagClasses.biped) then
                    local tagPath = get_tag_path(tagId)
                    local splitPath = glue.string.split(tagPath, "\\")
                    local weaponTagName = splitPath[#splitPath]
                    weaponsList[weaponTagName] = tagPath
                end
            end

            local weaponName = table.concat(glue.shift(splitCommand, 1, -1), " ")
            local player = blam35.biped(get_dynamic_player())
            local weaponResult = weaponsList[weaponName]
            if (weaponResult) then
                core.spawnObject(tagClasses.biped, weaponResult, player.x, player.y, player.z)
            end
            return false
        elseif (forgeCommand == "fdump") then
            glue.writefile("player_dump.json", inspect(playerStore:getState()), "t")
            glue.writefile("forge_dump.json", inspect(forgeStore:getState()), "t")
            glue.writefile("events_dump.json", inspect(eventsStore:getState().forgeObjects), "t")
            glue.writefile("debug_dump.txt", debugBuffer, "t")
            return false
        elseif (forgeCommand == "fprint") then
            -- Testing rcon communication
            dprint("[Game Objects]", "category")

            local objects = get_objects()

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
            console_out("lua-blam " .. blam35.version)
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

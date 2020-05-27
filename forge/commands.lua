local inspect = require 'inspect'
local tests = require 'forge.tests'
local glue = require 'glue'
local core = require 'forge.core'

local function forgeCommands(command)
    if (command == 'fdebug') then
        debugMode = not debugMode
        console_out('Debug Forge: ' .. tostring(debugMode))
        return false
    else
        -- Split all the data in the command input
        local splitCommand = glue.string.split(' ', command)

        -- Substract first console command
        local forgeCommand = splitCommand[1]

        if (forgeCommand == 'fstep') then
            local newRotationStep = tonumber(splitCommand[2])
            if (newRotationStep) then
                features.printHUD('Rotation step now is ' .. newRotationStep ..
                                ' degrees.')
                playerStore:dispatch({
                    type = 'SET_ROTATION_STEP',
                    payload = {step = newRotationStep}
                })
            else
                playerStore:dispatch({
                    type = 'SET_ROTATION_STEP',
                    payload = {step = 3}
                })
            end
            return false
        elseif (forgeCommand == 'fdis' or forgeCommand == 'fdistance') then
            local newDistance = tonumber(splitCommand[2])
            if (newDistance) then
                features.printHUD('Distance from object has been set to ' ..
                                newDistance .. ' units.')
                -- Force distance object update
                playerStore:dispatch({
                    type = 'SET_LOCK_DISTANCE',
                    payload = {lockDistance = true}
                })
                local distance = glue.round(newDistance)
                playerStore:dispatch({
                    type = 'SET_DISTANCE',
                    payload = {distance = distance}
                })
            else
                local distance = 3
                playerStore:dispatch({
                    type = 'SET_DISTANCE',
                    payload = {distance = distance}
                })
            end
            return false
        elseif (forgeCommand == 'fsave') then
            core.saveForgeMap()
            return false
        elseif (forgeCommand == 'fload') then
            local mapName = table.concat(glue.shift(splitCommand, 1, -1), ' ')
            if (mapName) then
                core.loadForgeMap(mapName)
            else
                console_out('You must specify a forge map name.')
            end
            return false
        elseif (forgeCommand == 'flist') then
            for file in hfs.dir(forgeMapsFolder) do
                if (file ~= '.' and file ~= '..') then
                    console_out(file)
                end
            end
            return false
        elseif (forgeCommand == 'ftest') then
            -- Run unit testing
            tests.run(true)
            return false
        elseif (forgeCommand == 'fobject') then
            local objectId = tonumber(splitCommand[2])
            console_out(tostring(get_object(objectId)))
            local eraseConfirm = splitCommand[3]
            if (eraseConfirm) then delete_object(objectId) end
            return false
        elseif (forgeCommand == 'fdump') then
            glue.writefile('forge_dump.json', inspect(forgeStore:getState()),
                           't')
            glue.writefile('events_dump.json',
                           inspect(eventsStore:getState().forgeObjects), 't')
            glue.writefile('debug_dump.txt', debugBuffer, 't')
            return false
        elseif (forgeCommand == 'fprint') then
            -- Testing rcon communication
            dprint('[Game Objects]', 'category')

            local objects = get_objects()

            -- Debug in game objects count
            dprint('Count: ' .. #objects)

            -- Debug list of all the in game objects
            dprint(inspect(objects))

            dprint('[Objects Store]', 'category')

            local storeObjects = glue.keys(eventsStore:getState().forgeObjects)

            -- Debug store objects count
            dprint('Count: ' .. #storeObjects)

            -- Debug list of all the store objects
            dprint(inspect(storeObjects))

            return false

        elseif (forgeCommand == 'fname') then
            local mapName = table.concat(glue.shift(splitCommand, 1, -1), ' ')
            forgeStore:dispatch({
                type = 'SET_MAP_NAME',
                payload = {mapName = mapName}
            })
            return false

        elseif (forgeCommand == 'fdesc') then
            local mapDescription = table.concat(glue.shift(splitCommand, 1, -1), ' ')
            forgeStore:dispatch({
                type = 'SET_MAP_DESCRIPTION',
                payload = {mapDescription = mapDescription}
            })
            return false
        end
    end
    return true
end

return forgeCommands
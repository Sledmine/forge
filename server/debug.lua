-- SAPP Lua Script Boilerplate
-- Version 1.0
-- Every function uses lower camel case, be careful about naming conventions
-- Api version must be declared at the top
-- It helps lua-blam to detect if the script is made for SAPP or Chimera
api_version = "1.12.0.0"

-- Lua libraries
local glue = require "glue"

-- Halo Custom Edition specific libraries
local blam = require "blam"
local tagClasses = blam.tagClasses
local objectClasses = blam.objectClasses

-- On tick function provided by default if needed
-- Be careful at handling data here, things can be messy
function OnTick()
end

-- Put initialization code here
function OnScriptLoad()
    -- We can set up our event callbacks, like the onTick callback
    register_callback(cb["EVENT_COMMAND"], "OnCommand")
end

-- Put cleanup code here
function OnScriptUnload()
end

function OnCommand(playerIndex, command, environment, interceptedRcon)
    if (environment == 1) then
        print("Command:" .. command)
        -- Split all the data in the command input
        local splitCommand = glue.string.split(command:gsub("_", " "):gsub("\"", ""), " ")

        -- Substract first console command
        local command = splitCommand[1]
        if (command == "dweaps") then
            for tagId = 0, blam.tagDataHeader.count - 1 do
                local tag = blam.getTag(tagId)
                if (tag.class == tagClasses.weapon) then
                    print(tag.path)
                end
            end

        elseif (command == "dvehis") then
            for tagId = 0, blam.tagDataHeader.count - 1 do
                local tag = blam.getTag(tagId)
                if (tag.class == tagClasses.vehicle) then
                    print(tag.path)
                end
            end

        elseif (command == "dweap") then
            local weaponsList = {}
            for tagId = 0, blam.tagDataHeader.count - 1 do
                local tag = blam.getTag(tagId)
                if (tag.class == tagClasses.weapon) then
                    local splitPath = glue.string.split(tag.path, "\\")
                    local weaponTagName = splitPath[#splitPath]
                    weaponsList[weaponTagName] = tag.path
                end
            end
            local weaponName = table.concat(glue.shift(splitCommand, 1, -1), " ")
            local player = blam.biped(get_dynamic_player(playerIndex))
            local weaponResult = weaponsList[weaponName]
            if (weaponResult) then
                local weaponObjectId = spawn_object(tagClasses.weapon, weaponResult,
                                                    player.x, player.y, player.z + 0.5)
            end

        elseif (command == "dspeed") then
            local newSpeed = tonumber(table.concat(glue.shift(splitCommand, 1, -1), " "))
            if (newSpeed) then
                local player = get_player()
                write_float(player + 0x6C, newSpeed)
            end

        elseif (command == "dobjects") then
            --[[local objectCount = 0
        local tagName = table.concat(glue.shift(splitCommand, 1, -1), " ")
        local objects = blam.getObjects()
        for _, objectIndex in pairs(objects) do
            local tempObject = blam.object(get_object(objectIndex))
            if (tempObject) then
                local tempTag = blam.getTag(tempObject.tagId)
                if (tempTag and tempTag.path:find(tagName)) then
                    objectCount = objectCount + 1
                    print(objectIndex .. "    " .. tempTag.path .. "    " ..
                                    tempTag.class)
                end
            end
        end
        print(objectCount)]]

        elseif (command == "dspawn") then
            print("commanaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaad")
            local desiredTagClass = splitCommand[2]
            local tagsList = {}
            for tagId = 0, blam.tagDataHeader.count - 1 do
                local tag = blam.getTag(tagId)
                if (tag and tag.class == desiredTagClass) then
                    local splitPath = glue.string.split(tag.path, "\\")
                    local tagName = splitPath[#splitPath]
                    tagsList[tagName] = tag.path
                end
            end
            local desiredTagName = table.concat(glue.shift(splitCommand, 1, -2), " ")
            local player = blam.biped(get_dynamic_player(playerIndex))
            local tagResult = tagsList[desiredTagName]
            print(desiredTagName)
            print(tagResult)
            if (tagResult) then
                local weaponObjectId = spawn_object(desiredTagClass, tagResult, player.x,
                                                    player.y, player.z + 0.5)
            end

        elseif (command == "builex") then
            debugMode = not debugMode

        elseif (command == "dinfo") then
            local objectIndex = tonumber(
                                    table.concat(glue.shift(splitCommand, 1, -1), " "))
            if (objectIndex) then
                local tempObject = blam.object(get_object(objectIndex))
                if (tempObject) then
                    print("Perm: " .. tempObject.regionPermutation1)
                    print("Health: " .. tempObject.health)
                    print("Shield: " .. tempObject.shield)
                end
            end

        elseif (command == "dtest") then
            local objectId = splitCommand[2]
            print(get_object(objectId))

        elseif (command == "dmenus") then
            for tagId = 0, blam.tagDataHeader.count - 1 do
                local tag = blam.getTag(tagId)
                if (tag.class == tagClasses.uiWidgetDefinition) then
                    print(tag.path)
                end
            end

        elseif (command == "dmenu") then
            local tagName = tonumber(table.concat(glue.shift(splitCommand, 1, -1), " "))
            local tagsList = {}
            for tagId = 0, blam.tagDataHeader.count - 1 do
                local tag = blam.getTag(tagId)
                if (tag.class == tagClasses.uiWidgetDefinition) then
                    local splitPath = glue.string.split(tag.path, "\\")
                    local uiTagName = splitPath[#splitPath]
                    tagsList[uiTagName] = tag.path
                end
            end
            local desiredTagName = splitCommand[1]
            local tagPath = tagsList[desiredTagName]
            print(desiredTagName)
            load_ui_widget(tagPath)

        elseif (command == "dstrings") then
            for tagId = 0, blam.tagDataHeader.count - 1 do
                local tag = blam.getTag(tagId)
                if (tag.class == tagClasses.unicodeStringList) then
                    print(tag.path)
                end
            end

        elseif (command == "dsounds") then
            for tagId = 0, blam.tagDataHeader.count - 1 do
                local tag = blam.getTag(tagId)
                if (tag.class == tagClasses.sound) then
                    print(tag.path)
                end
            end

        elseif (command == "did") then
            local biped = blam.object(get_object(splitCommand[2]))
            print(blam.getTag(biped.tagId).path)

        end
    end
end

-- This function is not mandatory, but if you want to log errors, use this
function OnError(Message)
    print(debug.traceback())
end

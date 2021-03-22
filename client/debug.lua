------------------------------------------------------------------------------
-- Debug script
-- Sledmine
-- This script is intended to provide tools to test and debug any game map
------------------------------------------------------------------------------
clua_version = 2.042

blam = require "blam"
tagClasses = blam.tagClasses
objectClasses = blam.objectClasses
local glue = require "glue"
local inspect = require "inspect"

local core = require "forge.core"

local debugMode = false
local fly = false

function OnCommand(command)
    -- Split all the data in the command input
    local splitCommand = glue.string.split(command, " ")

    -- Substract first console command
    local command = splitCommand[1]
    if (command == "dweaps") then
        for tagId = 0, blam.tagDataHeader.count - 1 do
            local tag = blam.getTag(tagId)
            if (tag.class == tagClasses.weapon) then
                console_out(tag.path)
            end
        end
        return false
    elseif (command == "dvehis") then
        for tagId = 0, blam.tagDataHeader.count - 1 do
            local tag = blam.getTag(tagId)
            if (tag.class == tagClasses.vehicle) then
                console_out(tag.path)
            end
        end
        return false
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
        local player = blam.biped(get_dynamic_player())
        local weaponResult = weaponsList[weaponName]
        if (weaponResult) then
            local weaponObjectId = spawn_object(tagClasses.weapon, weaponResult, player.x,
                                                player.y, player.z + 0.5)
        end
        return false
    elseif (command == "dspeed") then
        local newSpeed = tonumber(table.concat(glue.shift(splitCommand, 1, -1), " "))
        if (newSpeed) then
            local player = get_player()
            write_float(player + 0x6C, newSpeed)
        end
        return false
    elseif (command == "dobjects") then
        local objectCount = 0
        local tagName = table.concat(glue.shift(splitCommand, 1, -1), " ")
        local objects = blam.getObjects()
        for _, objectIndex in pairs(objects) do
            local tempObject = blam.object(get_object(objectIndex))
            if (tempObject) then
                local tempTag = blam.getTag(tempObject.tagId)
                if (tempTag and tempTag.path:find(tagName)) then
                    objectCount = objectCount + 1
                    console_out(objectIndex .. "    " .. tempTag.path .. "    " ..
                                    tempTag.class)
                end
            end
        end
        console_out(objectCount)
        return false
    elseif (command == "dspawn") then
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
        local player = blam.biped(get_dynamic_player())
        local tagResult = tagsList[desiredTagName]
        console_out(desiredTagName)
        console_out(tagResult)
        if (tagResult) then
            local objectId = spawn_object(desiredTagClass, tagResult, player.x, player.y,
                                          player.z + 0.5)
        end
        return false
    elseif (command == "builex") then
        debugMode = not debugMode
        return false
    elseif (command == "dinfo") then
        local objectIndex = tonumber(table.concat(glue.shift(splitCommand, 1, -1), " "))
        if (objectIndex) then
            local tempObject = blam.object(get_object(objectIndex))
            if (tempObject) then
                console_out("Perm: " .. tempObject.regionPermutation1)
                console_out("Health: " .. tempObject.health)
                console_out("Shield: " .. tempObject.shield)
            end
        end
        return false
    elseif (command == "dtest") then
    elseif (command == "dmenus") then
        for tagId = 0, blam.tagDataHeader.count - 1 do
            local tag = blam.getTag(tagId)
            if (tag.class == tagClasses.uiWidgetDefinition) then
                console_out(tag.path)
            end
        end
        return false
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
        console_out(desiredTagName)
        load_ui_widget(tagPath)
        return false
    elseif (command == "dstrings") then
        for tagId = 0, blam.tagDataHeader.count - 1 do
            local tag = blam.getTag(tagId)
            if (tag.class == tagClasses.unicodeStringList) then
                console_out(tag.path)
            end
        end
        return false
    elseif (command == "dsounds") then
        for tagId = 0, blam.tagDataHeader.count - 1 do
            local tag = blam.getTag(tagId)
            if (tag.class == tagClasses.sound) then
                console_out(tag.path)
            end
        end
        return false
    elseif (command == "did") then
        local biped = blam.object(get_object(splitCommand[2]))
        console_out(blam.getTag(biped.tagId).path)
        return false
    end
end

function OnTick()
    local player = blam.biped(get_dynamic_player())
    if (player) then
        if (debugMode and player.flashlightKey) then
            fly = not fly
        end
        if (fly) then
            player.ignoreCollision = true
            player.zVel = player.zVel + 0.005
        else
            player.ignoreCollision = false
        end
    end
    return false
end

set_callback("command", "OnCommand")
set_callback("tick", "OnTick")

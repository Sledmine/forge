------------------------------------------------------------------------------
-- Debug script
-- Sledmine
-- This script is intended to provide tools to debug any game map
------------------------------------------------------------------------------
clua_version = 2.042

local blam = require "nlua-blam"
tagClasses = blam.tagClasses
local glue = require "glue"
local inspect = require "inspect"

function OnCommand(command)
    -- Split all the data in the command input
    local splitCommand = glue.string.split(command, " ")

    -- Substract first console command
    local command = splitCommand[1]
    if (command == "weaps") then
        for tagId = 0, blam.tagDataHeader.count - 1 do
            local tag = blam.getTag(tagId)
            if (tag.class == tagClasses.weapon) then
                console_out(tag.path)
            end
        end
        return false
    elseif (command == "weap") then
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
    end
end

set_callback("command", "OnCommand")

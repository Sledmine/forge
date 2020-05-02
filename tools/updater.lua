local glue = require 'glue'
local fs = require 'fs'
local md5 = require 'md5'
local inspect = require 'inspect'
local argparse = require 'argparse'
local registry = require 'registry'
local path = require 'path'
local winapi = require 'winapi'

require 'winapi.windowclass'
require 'winapi.windowclass'
require 'winapi.menuclass'
require 'winapi.buttonclass'
require 'winapi.toolbarclass'
require 'winapi.groupboxclass'
require 'winapi.checkboxclass'
require 'winapi.radiobuttonclass'
require 'winapi.editclass'
require 'winapi.tabcontrolclass'
require 'winapi.listboxclass'
require 'winapi.comboboxclass'
require 'winapi.labelclass'
require 'winapi.listviewclass'
require 'winapi.trackbarclass'

local function getMyGamesPath()
    local documentsPath =
        registry.getkey('HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders')
    if (documentsPath ~= nil) then
        return documentsPath.values['Personal']['value'] .. '\\My Games\\Halo CE'
    else
        print("Error at trying to get 'My Documents' path...")
        os.exit()
    end
    return nil
end

local function getGamePath()
    local registryPath
    local _ARCH = os.getenv('PROCESSOR_ARCHITECTURE')
    registryPath = registry.getkey('HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Microsoft\\Microsoft Games\\Halo CE')
    if (_ARCH == 'x86') then
        registryPath = registry.getkey('HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Microsoft Games\\Halo CE')
    end
    if (registryPath) then
        return registryPath.values['EXE Path']['value']
    else
        print('\nError at trying to get Halo Custom Edition installation path, are you using a portable version (?)')
        os.exit()
    end
    return nil
end

local versionsTable = {
    ['86736298d0e47362eb92172f09af2711'] = 4.0,
    ['ea40c369993d5726c3c9fb551d5fa59d'] = 4.1
}

local updatesTable = {
    ['5d382084da87a542e4c28ce642095e46'] = 4.1
}

-- Create argument parser with Updater info
local parser = argparse('updater', 'Halo Custom Edition Map Updater 1.0', 'Support it at shadowmods.net/discord')

-- Catch command name as "command" on the args object
parser:command_target('command')

-- Arguments
parser:argument('baseMapOrUpdate', 'File path for the base file to update / path to the map update')
parser:argument('targetMap', 'Target file to create an update'):args('?')

-- Override args array with parser ones
local args = parser:parse()

local forgeMapPath = getGamePath() .. '\\maps\\forge_island.map'

local mainWindow =
    winapi.Window {
    w = 400, --all these are "initial fields"
    h = 100,
    title = 'Forge Updater',
    autoquit = true, --this is to quit app when the window is closed
    visible = false --this field is from BaseWindow
}

print('[Map Updater 1.0]')
if (args.baseMapOrUpdate and args.targetMap) then
    print('Calculating checksums...\n')

    local baseMap = glue.readfile(args.baseMapOrUpdate, 'b')
    local targetMap = glue.readfile(args.targetMap, 'b')
    print('Base MD5: ' .. glue.tohex(md5.sum(baseMap)))
    print('Target MD5: ' .. glue.tohex(md5.sum(targetMap)))
    local baseMapPath = '"' .. args.baseMapOrUpdate .. '"'
    local targetMapPath = '"' .. args.targetMap .. '"'
    local updatePath =
        '"' .. path.dir(args.targetMap) .. '\\' .. path.file(args.targetMap):gsub('.map', '.update') .. '"'
    os.execute('xdelta3 -e -f -s' .. baseMapPath .. ' ' .. targetMapPath .. ' ' .. updatePath)

    print('\nDone!')
    print('Update file: ' .. updatePath)
elseif (args.baseMapOrUpdate) then
    local forgeMap = glue.readfile(forgeMapPath)
    local updateFile = glue.readfile(args.baseMapOrUpdate, 'b')

    local mapMd5 = glue.tohex(md5.sum(forgeMap))
    local updateMd5 = glue.tohex(md5.sum(updateFile))

    print('Current map MD5: ' .. mapMd5)
    print('Update file MD5: ' .. updateMd5)

    local mapVersion = versionsTable[mapMd5]
    if (mapVersion) then
        print('\nGotcha!!!, found Forge version: ' .. mapVersion)
    else
        mapVersion = 'Unknown version'
    end

    local updateVersion = updatesTable[updateMd5]
    if (updateVersion) then
        print('\nUpdate version: ' .. updateVersion)
    else
        updateVersion = 'Unknown version'
    end

    local lb =
        winapi.Label {
        x = 10,
        y = 10,
        w = mainWindow.client_w / 2,
        h = 15,
        parent = mainWindow,
        align = 'left',
        text = 'Forge Version: ' .. tostring(mapVersion)
    }

    local lb =
        winapi.Label {
        x = 10,
        y = 35,
        w = mainWindow.client_w / 2,
        h = 15,
        parent = mainWindow,
        align = 'left',
        text = 'Update Version: ' .. tostring(updateVersion)
    }

    local updateButton =
        winapi.Button {
        x = mainWindow.client_w - 120,
        y = 15,
        w = 100,
        h = 30,
        text = 'Update',
        parent = mainWindow,
        default = true --respond to pressing Enter
    }

    function updateButton:on_click()
        if (mapVersion == updateVersion) then
            mainWindow:close()
        else
            local fixedForgePathTmp = '"' .. forgeMapPath .. 'tmp"'
            local fixedForgePath = '"' .. forgeMapPath .. '"'
            local fixedUpdatePath = '"' .. args.baseMapOrUpdate .. '"'
            print('Updating...')
            fs.move(forgeMapPath, forgeMapPath .. 'tmp')
            os.execute('xdelta3 -d -f -s' .. fixedForgePathTmp .. ' ' .. fixedUpdatePath .. ' ' .. fixedForgePath)
            print(forgeMapPath .. 'tmp')
            fs.remove(forgeMapPath .. 'tmp')
            print('\nDone!')
            print('New file: ' .. fixedForgePath)
        end
        mainWindow:close()
    end

    mainWindow:show()
end

os.exit(winapi.MessageLoop())

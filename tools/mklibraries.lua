local glue = require 'glue'
local fs = require 'fs'
local md5 = require 'md5'
local argparse = require 'argparse'

-- Create argument parser with Updater info
local parser = argparse('mklibraries', 'Script to create libraries for developing.', '')

-- Catch command name as "command" on the args object
parser:command_target('command')

-- Developer flags
parser:flag('-d --debug', 'Updater will print debug messages.')
parser:argument('input', 'Path of files to take as libraries')
parser:argument('output', 'Path to place the symlinks')

-- Override args array with parser ones
local args = parser:parse()

for name, d in fs.dir(args.input) do
    if not name then
        print('error: ', d)
        break
    end
    if (d:attr('type') == 'file') then
        if (string.find(name, '.lua')) then
            print(d:path())
            print('--------------------------')
            print(args.output.."\\"..name)
            local targetPath = '"' .. d:path() .. '"'
            local linkPath = '"' .. args.output.."\\"..name .. '"'
            os.execute('mklink ' .. linkPath .. ' ' .. targetPath)
            --fs.mksymlink(args.output.."\\"..name, d:path(), false)
        end
    end
end

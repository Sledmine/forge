------------------------------------------------------------------------------
-- Forge Island Project Compiler
-- Sledmine
-- Script utility to compile the entire Forge Island project
------------------------------------------------------------------------------
local argparse = require "lua.scripts.modules.argparse"

-- Create argument parser
local parser = argparse("compileMap", "Compile map project with different configurations")

-- Flags
parser:flag("-r --release", "Define release properties before compilation")
parser:flag("-u --updateVersion", "Update tags to reflect project version")

-- Get script args
local args = parser:parse()

-- Import constants
local forgeVersion = require "lua.forge.version"
forgeVersion = forgeVersion .. "+invader"

local buildName = "forge_island"

if (not args.release) then
    buildName = buildName .. "_dev"
    forgeVersion = forgeVersion .. ".dev"
end

-- Update map version tags
if (args.updateVersion) then
    -- Generate bitmap version from code
    local versionBitmapCmd =
        [[cd "data\[shm]\halo_4\ui\hud\bitmaps" & convert version_number_template.png +compress -fill "#aaaaaa" -size 512x128 -font "conduit_itc_medium.otf" -pointsize 98 -gravity center -draw "text 0,0 '%s'" version_number.tif]]

    print("Generating bitmap version from Forge code...")
    local result = os.execute(versionBitmapCmd:format(forgeVersion:upper()))
    if (result) then
        print("Done!")
    else
        os.exit(1)
        print("Error, an error occurred while generating bitmap version from Forge code.")
    end
    -- Compile bitmap version
    local versionBitmapCompileCmd =
        [[invader-bitmap -d data\ -t tags\ -F 32-bit -T 2d_textures "[shm]\halo_4\ui\hud\bitmaps\version_number"]]

    print("Compiling bitmap version...")
    local result = os.execute(versionBitmapCompileCmd)
    if (result) then
        print("Done!")
    else
        os.exit(1)
        print("Error, an error occurred while compiling bitmap version.")
    end
end

-- Compile map
local compileMapCmd =
    [[cd tags\ & invader-build.exe -t . -P -m "D:\Program Files (x86)\Microsoft Games\Halo Custom Edition\maps" -A pc-custom -E -g pc-custom -N %s -q "[shm]\halo_4\maps\forge_island\forge_island_dev.scenario"]]

print("Compiling project...")
local result = os.execute(compileMapCmd:format(buildName))
if (result) then
    print("Project compiled succesfully!")
else
    os.exit(1)
    print("Error, an error occurred while compiling map.")
end

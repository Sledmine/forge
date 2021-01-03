-- Import constants
local forgeVersion = require "forge.version"
local forgeBuild = arg[1]

-- Generate bitmap version from code

local versionBitmapCmd = [[cd "D:\Program Files (x86)\Microsoft Games\Halo Custom Edition\projects\ForgeIsland\data\[shm]\halo_4\ui\hud\bitmaps" & convert version_number_template.png +compress -fill "#5aa5cef5" -size 512x128 -font "Conduit_ITC_Medium.ttf" -pointsize 128 -gravity center -draw "text 0,0 '%s'" version_number.tif]]

print("Generating bitmap version from Forge code...")
local result = os.execute(versionBitmapCmd:format("v" .. forgeVersion:upper()))
if (result) then
    print("Done!")
else
    os.exit(1)
    print("Error, error occurred while generating bitmap version from Forge code.")
end

-- Compile bitmap version

local versionBitmapCompileCmd = [[cd "D:\Program Files (x86)\Microsoft Games\Halo Custom Edition\projects\ForgeIsland" & harvest bitmaps "[shm]\halo_4\ui\hud\bitmaps"]]

print("Compiling bitmap version...")
local result = os.execute(versionBitmapCompileCmd)
if (result) then
    print("Done!")
else
    os.exit(1)
    print("Error, an error occurred while compiling bitmap version.")
end

-- Compile map

local compileMapCmd = [[cd "D:\Program Files (x86)\Microsoft Games\Halo Custom Edition\projects\ForgeIsland" & harvest build-cache-file "[shm]\halo_4\maps\forge_island\%s"]]

-- forge_island_dev
-- forge_island

print("Compiling map...")
local result = os.execute(compileMapCmd:format(forgeBuild))
if (result) then
    print("Done!")
else
    os.exit(1)
    print("Error, an error occurred while compiling map.")
end
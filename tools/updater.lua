local oldMap = arg[1]
local updateFile = oldMap:gsub("%.%map", ".update")
local newMap = oldMap:gsub("%.%map", "") .. "_u.map"
print(oldMap)
print(updateFile)

local xDelta3Update = "xdelta3 -d -f -s \"%s\" \"%s\" \"%s\""
local command = xDelta3Update:format(oldMap, updateFile, newMap)
--print(command)
print("Updating map...")
os.execute(command)
os.remove(oldMap)
os.remove(updateFile)
os.rename(newMap, oldMap)
print("Map updated!")

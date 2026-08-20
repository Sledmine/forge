local luna = require "luna"
local blam = require "blam2"
local forge = require "forge.forge"

local commands = {}

commands = {
    debug = {
        description = "Toggle debug mode.",
        category = "debug",
        help = "<boolean>",
        example = "debug true",
        minArgs = 1,
        maxArgs = 1,
        func = function(isEnabled)
            DebugMode = luna.bool(isEnabled)
            if DebugMode then
                Balltze.logger.info("Debug mode enabled.")
            else
                Balltze.logger.info("Debug mode disabled.")
            end
            Balltze.logger.muteDebug(not DebugMode)
        end
    },
    load_forge_map = {
        description = "Load a saved Forge map (.fmap) by name.",
        category = "map",
        help = "<mapName>",
        example = "load_forge_map forge_island",
        minArgs = 1,
        maxArgs = 1,
        func = function(mapName)
            local loaded, loadedObjects = forge.loadSavedMap(mapName)
            if loaded then
                Balltze.logger.info("Loaded forge map '{}' with {} objects", tostring(mapName),
                                    loadedObjects)
                return
            end
            Balltze.logger.error("Failed to load forge map '{}'", tostring(mapName))
        end
    }
}

return commands

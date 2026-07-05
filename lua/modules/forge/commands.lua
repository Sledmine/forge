local luna = require "luna"
local blam = require "blam2"

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
                logger:info("Debug mode enabled.")
            else
                logger:info("Debug mode disabled.")
            end
            logger:muteDebug(not DebugMode)
        end
    }
}

return commands

------------------------------------------------------------------------------
-- Forge Network Constants
-- Sledmine
-- Shared constants for the Forge network synchronization layer
------------------------------------------------------------------------------
local constants = {}

-- Every Forge network message travels through this single Balltze channel,
-- a "kind" field inside the payload tells listeners what to do with it
constants.channel = "forge_sync"

-- The three Forge object operations that need to travel over the network,
-- matching the three "specific object handler cases" Forge exposes:
-- place/create, update (move/rotate) and delete
constants.kind = {
    spawn = "spawn",
    update = "update",
    delete = "delete"
}

return constants

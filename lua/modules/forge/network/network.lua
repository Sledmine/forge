------------------------------------------------------------------------------
-- Forge Network
-- Sledmine
-- Minimal transport used to keep Forge object placement, updates (position
-- and rotation) and deletion in sync across every machine in a networked
-- game. This intentionally does not bring back the old "maethrillian"
-- request encoding, messages are just small JSON tables.
--
-- Every machine spawns/updates/deletes its own real, local Forge object;
-- this module only carries the *description* of what changed, `tracking`
-- (see network/tracking.lua) is what lets every machine agree on which
-- local object a given message refers to.
--
-- Roles:
--   * Authority: either the host of a network game, or a plain offline/local
--     game (which is trivially authoritative over itself). It is the only
--     side allowed to decide real Forge state, so its messages are always
--     broadcast to everyone as the new source of truth.
--   * Client: connected to someone else's network game. It cannot decide
--     Forge state on its own, so its messages are only *requests* sent to
--     the authority, which performs the change and broadcasts the result
--     back (including to the requester).
--
-- This split is what keeps forge.lua free of network branching: it just
-- calls `network.emitSpawn/emitUpdate/emitDelete` after doing its local job,
-- and registers `network.setHandler` callbacks to (re)apply a change that
-- came from the network.
------------------------------------------------------------------------------
local engine = Engine
local json = require "json"
local logger = Balltze.logger

local constants = require "forge.network.constants"
local tracking = require "forge.network.tracking"

local network = {}
network.tracking = tracking
network.kind = constants.kind

-- This machine's role for the current game session. Computed once, like the
-- rest of the connection-type checks already used across the Forge modules,
-- since it cannot meaningfully change without a map/plugin reload
local connectionType = engine.game.getGameConnectionType()

--- Whether Forge is part of an actual networked game (as opposed to a local
--- offline game). Network messages are only ever sent/received when this is
--- true, this is the "flag" that gates the whole network layer
---@type boolean
network.isGameNetwork = connectionType == "networkClient" or connectionType == "networkServer"

--- Whether this machine is the authority over Forge state: the host of a
--- network game, or the only participant of a local/offline game
---@type boolean
network.isAuthority = connectionType ~= "networkClient"

-- Handlers registered by forge.lua, one per message kind, used to (re)apply
-- a change that came from the network
local handlers = {}

--- Register the function used to apply a given message kind locally
---@param kind string
---@param handlerFunction fun(data: table)
function network.setHandler(kind, handlerFunction)
    handlers[kind] = handlerFunction
end

--- Send a Forge network message, the transport used depends on this
--- machine's role: the authority broadcasts (it is the source of truth),
--- a client only ever asks the authority to make the change happen
---@param kind string
---@param data table
local function transmit(kind, data)
    if not network.isGameNetwork then
        -- Nothing to sync, this is not a networked game
        return
    end
    data.kind = kind
    local payload = json.encode(data)
    if network.isAuthority then
        Balltze.network.broadcast(constants.channel, payload)
    else
        logger.debug("Forge network: sending \"{}\" request to authority: {}", kind, payload)
        local sent = Balltze.network.send(constants.channel, payload)
        if sent == false then
            logger.warning("Forge network: failed to send \"{}\" request, not connected?", kind)
        end
    end
end

--- Notify (or, on a client, request) a Forge object spawn
---@param data table @{id?: integer, tag: string, x: number, y: number, z: number, yaw?: number, pitch?: number, roll?: number, playerIndex?: integer}
function network.emitSpawn(data)
    transmit(constants.kind.spawn, data)
end

--- Notify (or, on a client, request) a Forge object transform update
---@param data table @{id: integer, x: number, y: number, z: number, yaw?: number, pitch?: number, roll?: number}
function network.emitUpdate(data)
    transmit(constants.kind.update, data)
end

--- Notify (or, on a client, request) a Forge object deletion
---@param data table @{id: integer}
function network.emitDelete(data)
    transmit(constants.kind.delete, data)
end

--- Dispatch an incoming Forge network message to its registered handler
---@param payload string
---@param senderPlayerIndex integer? @nil when the message came from the authority
local function onMessage(payload, senderPlayerIndex)
    logger.debug("Forge network: received message from {}: {}", senderPlayerIndex or "authority", payload)
    local ok, data = pcall(json.decode, payload)
    if not ok or type(data) ~= "table" or not data.kind then
        logger.warning("Forge network: received a malformed payload")
        return
    end

    if senderPlayerIndex then
        -- This is a request coming from a client, trust the transport-level
        -- sender identity over anything the payload itself claims
        data.playerIndex = senderPlayerIndex
    end

    local handlerFunction = handlers[data.kind]
    if not handlerFunction then
        logger.warning("Forge network: no handler registered for kind \"{}\"", tostring(data.kind))
        return
    end

    -- A single bad/unexpected message must never take down the whole
    -- dispatcher: on the authority that would also mean any confirmation
    -- broadcast for it silently never happens, breaking every client
    -- waiting on it
    local ok, err = pcall(handlerFunction, data)
    if not ok then
        logger.error("Forge network: error handling \"{}\" message: {}", tostring(data.kind),
                     tostring(err))
    end
end

-- Subscribing is harmless even on a local/offline game, no message will ever
-- arrive on the channel in that case
Balltze.network.subscribe(constants.channel, onMessage)

return network

------------------------------------------------------------------------------
-- Forge Network Object Tracking
-- Sledmine
-- Every machine (authority or client) spawns its own real, local copy of a
-- given Forge object. Since local object handles are only meaningful to the
-- machine that created them, this module keeps a small table that relates a
-- shared "network id" (agreed upon by every machine) to the local object
-- handle used to reference that same conceptual object on this machine.
--
-- This is intentionally the only piece of state the network layer keeps,
-- every other Forge action is looked up through it instead of carrying raw
-- object handles across the network.
------------------------------------------------------------------------------
local tracking = {}

--- objectHandleValue -> networkId
local handleToNetworkId = {}
--- networkId -> objectHandleValue
local networkIdToHandle = {}

-- Incrementing counter used to mint new ids. Only the authority ever
-- generates ids (clients only ever learn about ids through the network), so
-- there is no risk of two machines handing out the same id
local nextNetworkId = 1

--- Generate a new unique network id, only meant to be called by the authority
---@return integer networkId
function tracking.generateId()
    local networkId = nextNetworkId
    nextNetworkId = nextNetworkId + 1
    return networkId
end

--- Relate a network id with a local object handle
---@param networkId integer
---@param objectHandleValue integer
function tracking.register(networkId, objectHandleValue)
    networkIdToHandle[networkId] = objectHandleValue
    handleToNetworkId[objectHandleValue] = networkId
end

--- Forget any tracking information related to a given network id
---@param networkId integer
function tracking.remove(networkId)
    local objectHandleValue = networkIdToHandle[networkId]
    if objectHandleValue then
        handleToNetworkId[objectHandleValue] = nil
    end
    networkIdToHandle[networkId] = nil
end

--- Get the local object handle tracked for a given network id
---@param networkId integer
---@return integer? objectHandleValue
function tracking.getHandle(networkId)
    return networkIdToHandle[networkId]
end

--- Get the network id tracked for a given local object handle
---@param objectHandleValue integer
---@return integer? networkId
function tracking.getNetworkId(objectHandleValue)
    return handleToNetworkId[objectHandleValue]
end

return tracking

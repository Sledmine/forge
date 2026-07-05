local engine = Engine
local getPlayer = engine.gameState.getPlayer
local getObject = engine.gameState.getObject
local objectType = engine.tag.objectType

local core = {}

local constants = require "forge.constants"

BipedReplacements = {}

local isGameDedicated = engine.netgame.getServerType() == "dedicated"

function core.getPlayerObject(playerIndex)
    local player = getPlayer(playerIndex)
    if not player then
        return nil
    end
    local playerBiped = getObject(player.objectHandle.value, objectType.biped)
    if not playerBiped then
        return nil
    end
    return playerBiped
end

function core.teleportPlayer(playerIndex, x, y, z)
    local player = getPlayer(playerIndex)
    if not player then
        return
    end
    local playerBiped = getObject(player.objectHandle.value, objectType.biped)
    if not playerBiped then
        return
    end
    playerBiped.position.x = x
    playerBiped.position.y = y
    playerBiped.position.z = z
end

function core.swapBiped(playerIndex, tagHandleValue)
    if not isGameDedicated then
        local multiplayerInfo = constants.globals.data.multiplayerInformation.elements[1]
        multiplayerInfo.unit.tagHandle.value = tagHandleValue
    else
        BipedReplacements[playerIndex] = tagHandleValue
    end
end

return core

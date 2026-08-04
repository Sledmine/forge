local engine = Engine
local getPlayer = engine.player.getPlayer
local getObject = engine.object.getObject

local core = {}

local constants = require "forgeIsland.constants"

BipedReplacements = {}

local isGameDedicated = engine.game.getGameConnectionType() == "networkClient"

function core.getPlayerObject(playerIndex)
    local player = getPlayer(playerIndex)
    if not player then
        return nil
    end
    local playerBiped = getObject(player.unitHandle.value, "biped")
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
    local playerBiped = getObject(player.unitHandle.value, "biped")
    if not playerBiped then
        return
    end
    playerBiped.position.x = x
    playerBiped.position.y = y
    playerBiped.position.z = z
end

function core.swapBiped(playerIndex, tagHandleValue)
    if not isGameDedicated then
        local globalsTagData = constants.globals and constants.globals:getData()
        if not globalsTagData then
            return
        end
        local multiplayerInfo = globalsTagData.multiplayerInformation[1]
        multiplayerInfo.unit.tagHandle.value = tagHandleValue
    else
        BipedReplacements[playerIndex] = tagHandleValue
    end
end

return core

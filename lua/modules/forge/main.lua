local script = require "script"
local sleep = script.sleep
local engine = Engine
local getPlayer = engine.gameState.getPlayer
local getObject = engine.gameState.getObject
local objectType = engine.tag.objectType

local constants = require "forge.constants"
local core = require "forge.core"
local forge = require "forge.forge"
local bipeds = constants.bipeds

local map = {}

local isGameDedicated = engine.netgame.getServerType() == "dedicated"

function map.main()
    logger:info("Welcome to Forge Island!")
end
script.startup(map.main)

function map.forgeControl()
    for playerIndex = 0, 15 do
        -- Does this player exists?
        if getPlayer(playerIndex) then
            -- We create individual anonymous scripts for each player so that each thread
            -- can sleep independently of other players
            script.create(function()
                local player = getPlayer(playerIndex)
                if not player then
                    return
                end
                local playerBiped = getObject(player.objectHandle.value, objectType.biped)
                if not playerBiped then
                    return
                end
                local previousPosition = {
                    x = playerBiped.position.x,
                    y = playerBiped.position.y,
                    z = playerBiped.position.z
                }
                if playerBiped.unitControlFlags.light and forge.mode == "edit" then
                    if playerBiped.tagHandle.value == bipeds.spartan.handle.value then
                        logger:debug("Player {} is pressing light", playerIndex)
                        core.swapBiped(playerIndex, bipeds.monitor.handle.value)
                        engine.gameState.deleteObject(player.objectHandle)
                        sleep(1)
                        sleep(function()
                            playerBiped = core.getPlayerObject(playerIndex)
                            return playerBiped ~= nil
                        end)
                        core.teleportPlayer(playerIndex, previousPosition.x, previousPosition.y,
                                            previousPosition.z)
                        playerBiped.vitals.health = 1
                        playerBiped.vitals.shield = 1
                        -- TODO Restore biped rotation as well
                        forge.setMonitorMode("idle")
                    end
                elseif playerBiped.unitControlFlags.crouch then
                    logger:debug("Player {} is pressing crouch", playerIndex)
                    if playerBiped.tagHandle.value == bipeds.monitor.handle.value then
                        core.swapBiped(playerIndex, bipeds.spartan.handle.value)
                        engine.gameState.deleteObject(player.objectHandle)
                        sleep(1)
                        sleep(function()
                            return core.getPlayerObject(playerIndex) ~= nil
                        end)
                        core.teleportPlayer(playerIndex, previousPosition.x, previousPosition.y,
                                            previousPosition.z)
                        forge.setMonitorMode("hidden")
                    end
                end
            end)
        end
    end
end
script.continuous(map.forgeControl)

return map

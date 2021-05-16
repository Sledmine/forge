------------------------------------------------------------------------------
-- Rcon Bypass
-- Sledmine
-- SAPP commands interceptor
------------------------------------------------------------------------------
local rcon = {_VERSION = "1.0.1"}

local environments = {
    console = 0,
    rcon = 1,
    chat = 2
}

rcon.environments = environments

-- Accepted rcon passwords
rcon.safeRcons = {}

-- Admin commands
rcon.adminCommands = {}

-- Commands to intercept
rcon.safeCommands = {}

rcon.commandInterceptor = nil

-- Internal functions
local function split(s, sep)
    if (sep == nil or sep == '') then return 1 end
    local position, array = 0, {}
    for st, sp in function() return string.find(s, sep, position, true) end do
        table.insert(array, string.sub(s, position, st-1))
        position = sp + 1
    end
    table.insert(array, string.sub(s, position))
    return array
end

local function listHas(list, value)
    value = string.gsub(value, "'", "")
    for k, element in pairs(list) do
        local wildcard = split(value, element)[1]
        if (element == value or wildcard == "") then
            return true
        end
    end
    return false
end

local function submit(list, value)
    if (not listHas(list, value)) then
        list[#list + 1] = value
        return true
    end
    return false
end

local function isABypassValue(list, value)
    if (listHas(list, value)) then
        return true
    end
    return false
end

local function isRconSafe(value)
    return isABypassValue(rcon.safeRcons, value)
end

local function isCommandSafe(value)
    return isABypassValue(rcon.safeCommands, value)
end

local function isAdminCommand(value)
    return isABypassValue(rcon.adminCommands, value)
end

-- Public functions and main usage

function rcon.submitRcon(rconValue)
    cprint("Adding new accepted rcon: " .. rconValue)
    return submit(rcon.safeRcons, rconValue)
end

function rcon.submitAdmimCommand(commandValue)
    cprint("Adding new accepted command: " .. commandValue)
    return submit(rcon.adminCommands, commandValue)
end

function rcon.submitCommand(commandValue)
    cprint("Adding new accepted command: " .. commandValue)
    return submit(rcon.safeCommands, commandValue)
end

---@param playerIndex number
---@param command string
---@param environment number
---@param rconPassword string
function rcon.OnCommand(playerIndex, command, environment, rconPassword)
    if (environment == environments.console or environment == environments.rcon) then
        if (environment == environments.console) then
            rconPassword = rcon.serverRcon
        end
        local playerName = get_var(playerIndex, "$name") or "Server"
        if (rconPassword == rcon.serverRcon) then
            -- Normal rcon usage, allow command
            if (isAdminCommand(command)) then
                rcon.commandInterceptor(playerIndex, command, environment, rconPassword)
                return false
            end
        elseif (isRconSafe(rconPassword)) then
            -- This is an interceptable rcon command
            cprint("Safe rcon: " .. rconPassword)
            if (isCommandSafe(command)) then
                -- Rcon command it's an expected command, apply bypass
                cprint("Safe command: " .. command)
                -- Execute interceptor
                rcon.commandInterceptor(playerIndex, command, environment, rconPassword)
            else
                cprint("Command: " .. command .. " is not in the safe commands list.")
                say_all(playerName .. " was sending commands trough safe rcon, watch out!!!")
                execute_command("sv_kick " .. playerIndex)
            end
            return false
        else
            say_all(playerName .. " was kicked by sending wrong rcon password.")
            execute_command("sv_kick " .. playerIndex)
        end
    end
end

function rcon.attach()
    if (server_type == "sapp") then
        rcon.passwordAddress = read_dword(sig_scan("7740BA??????008D9B000000008A01") + 0x3)
        rcon.failMessageAddress = read_dword(sig_scan("B8????????E8??000000A1????????55") + 0x1)
        if (rcon.passwordAddress and rcon.failMessageAddress) then
            -- Remove "rcon command failure" message
            safe_write(true)
            write_byte(rcon.failMessageAddress, 0x0)
            safe_write(false)
            -- Read current rcon in the server
            rcon.serverRcon = read_string(rcon.passwordAddress)
            if (rcon.serverRcon) then
                cprint("Server rcon password is: \"" .. rcon.serverRcon .. "\"")
            else
                cprint("Error, at getting server rcon, please set and enable rcon on the server.")
            end
        else
            cprint("Error, at obtaining rcon patches, please check SAPP version.")
        end
    end
end

function rcon.detach()
    if (rcon.failMessageAddress) then
        -- Restore "rcon command failure" message
        safe_write(true)
        write_byte(rcon.failMessageAddress, 0x72)
        safe_write(false)
    end
end

return rcon

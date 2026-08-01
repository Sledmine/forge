local balltze = Balltze
local engine = Engine

-- Load Chimera Lua compatibility for modules that still rely on it
local function loadChimeraCompatibility()
    --if not balltze.chimera then
    --    Balltze.logger.error("Chimera compatibility is not available. Please ensure the bridge module is loaded and that Chimera functions are accessible.")
    --    return
    --end
    ---- Populate global namespace with Chimera functions and variables, excluding some exceptions
    --for k, v in pairs(balltze.chimera) do
    --    if not k:includes "timer" and not k:includes "execute_script" and
    --        not k:includes "set_callback" then
    --        _G[k] = v
    --    end
    --end
    server_type = engine.game.getGameConnectionType()

    function console_is_open()
        return false
    end

    -- Replace Chimera functions with Balltze functions
    read_bit = balltze.memory.readBit
    read_byte = balltze.memory.readInt8
    read_word = balltze.memory.readInt16
    read_dword = balltze.memory.readInt32
    read_int = balltze.memory.readInt32
    read_float = balltze.memory.readFloat
    read_double = balltze.memory.readDouble
    read_string = balltze.memory.readString8
    
    write_bit = balltze.memory.writeBit
    write_byte = balltze.memory.writeInt8
    write_word = balltze.memory.writeInt16
    write_dword = balltze.memory.writeInt32
    write_int = balltze.memory.writeInt32
    write_float = balltze.memory.writeFloat
    write_string = function(address, value)
        for i = 1, #value do
            write_byte(address + i - 1, string.byte(value, i))
        end
        if #value == 0 then
            write_byte(address, 0)
        end
    end

    execute_script = engine.script.execute
end

return loadChimeraCompatibility
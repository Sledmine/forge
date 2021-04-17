------------------------------------------------------------------------------
-- Chimera API Bindings for SAPP
-- Sledmine
-- SAPP bindings for Chimera Lua functions, also EmmyLua helper
------------------------------------------------------------------------------
if (api_version) then
    local glue = require "glue"

    --- Function wrapper for file writing from Chimera to SAPP
    ---@param path string
    ---@param content string
    function write_file(path, content)
        glue.writefile(path, content, "t")
    end

    --- Function wrapper for file reading from Chimera to SAPP
    ---@param path string
    function read_file(path)
        return glue.readfile(path, "t")
    end

    -- TODO PENDING FUNCTION!!
    function directory_exists(dir)
        return true
    end

    --- Function wrapper for directory listing from Chimera to SAPP
    ---@param dir string
    function list_directory(dir)
        -- TODO This needs a way to separate folders from files
        if (dir) then
            local command = "dir " .. dir .. " /B"
            local pipe = io.popen(command, "r")
            local output = pipe:read("*a")
            if (output) then
                local items = glue.string.split(output, "\n")
                for index, item in pairs(items) do
                    if (item and item == "") then
                        items[index] = nil
                    end
                end
                return items
            end
        end
        return nil
    end

    --- Return the memory address of a tag given tagId or tagClass and tagPath
    ---@param tagIdOrTagType string | number
    ---@param tagPath string
    ---@return number
    function get_tag(tagIdOrTagType, tagPath)
        if (not tagPath) then
            return lookup_tag(tagIdOrTagType)
        else
            return lookup_tag(tagIdOrTagType, tagPath)
        end
    end

    --- Execute a game command or script block
    ---@param command string
    function execute_script(command)
        return execute_command(command)
    end

    --- Return the address of the object memory given object id
    ---@param objectId number
    ---@return number
    function get_object(objectId)
        if (objectId) then
            local object_memory = get_object_memory(objectId)
            if (object_memory ~= 0) then
                return object_memory
            end
        end
        return nil
    end

    --- Delete an object given object id
    ---@param objectId number
    function delete_object(objectId)
        destroy_object(objectId)
    end

    --- Print text into console
    ---@param message string
    -- TODO Add color printing to this function
    function console_out(message)
        cprint(message)
    end

    local sapp_get_dynamic_player = get_dynamic_player
    --- Get object address from a specific player given playerIndex
    ---@param playerIndex number
    ---@return number
    function get_dynamic_player(playerIndex)
        return sapp_get_dynamic_player(playerIndex)
    end

    print("Compatibility with Chimera Lua API has been loaded!")
end


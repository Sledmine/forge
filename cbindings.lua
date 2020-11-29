------------------------------------------------------------------------------
-- Chimera Bindings
-- Sledmine
-- SAPP bindings for Chimera Lua functions
------------------------------------------------------------------------------

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
    return glue.readfile(path)
end

-- // TODO PENDING FUNCTION!!
function directory_exists(dir)
    return true
end

--- Function wrapper for directory listing from Chimera to SAPP
---@param dir string
function list_directory(dir)
    -- // TODO This needs a way to separate folders from files
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

print("Compatibility with Chimera Lua API has been loaded!")
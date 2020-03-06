------------------------------------------------------------------------------
-- Maethrillian library
-- Author: Sledmine
-- Version: 1.0
-- Compression, decompression and tools for data manipulation
------------------------------------------------------------------------------

local glue = require 'glue'

local maethrillian = {}

-- Compress data in the given format
function maethrillian.compress(data)
    local compressedValues = {}
    for index, dataField in pairs(data) do
        if (dataField.compression) then
            glue.append(compressedValues, string.pack(dataField.compression, dataField.value))
        else
            glue.append(compressedValues, dataField.value)
        end
    end
    return compressedValues
end

-- Format data into specific request format
function maethrillian.convertDataToRequest(data)
    local requestData = {}
    for property, value in pairs(data) do
        local encodedValue = value
        if (type(value) ~= 'number') then
            encodedValue = glue.tohex(value)
        end
        glue.append(requestData, encodedValue)
    end
    return table.concat(requestData, ',')
end

return maethrillian

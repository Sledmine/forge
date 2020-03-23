------------------------------------------------------------------------------
-- Maethrillian library
-- Author: Sledmine
-- Version: 2.0
-- Compression, decompression and tools for data manipulation
------------------------------------------------------------------------------

local glue = require 'glue'

local maethrillian = {}

-- Compress data in the given format
-- @params List or Object with data, Object or list with desired compression values, Optional HEX formatting for compressed values
-- @return List or Object with compressed data
function maethrillian.compress(data, compressionList, hex)
    local compressedData = {}
    for key, value in pairs(data) do
        local compressionFormat = compressionList[key]
        if (compressionFormat) then
            if (hex) then
                compressedData[key] = glue.tohex(string.pack(compressionFormat, value))
            else
                compressedData[key] = string.pack(compressionFormat, value)
            end
        else
            compressedData[key] = value
        end
    end
    return compressedData
end

-- Format data into request
-- @params List or an Object with data, Optional the order result of the object properties
-- @return String with formatted data
function maethrillian.convertObjectToRequest(data, order)
    local requestData = {}
    for currentProperty, value in pairs(data) do
        if (order) then
            for position, propertyName in pairs(order) do
                if (currentProperty == propertyName) then
                    requestData[position] = value
                end
            end
        else
            requestData[#requestData + 1] = value
        end
    end
    return table.concat(requestData, ',')
end

-- Decompress data from given format
function maethrillian.decompress(request)
    for index, encodedValue in pairs(dataRequest) do
        --  By default every value is assumed as wrong formatted
        local value = nil

        -- Get compression format for current value
        local compressionFormat = request.compression[index]

        -- There is a compression format available
        if (compressionFormat) then
            value = string.unpack(compressionFormat, glue.fromhex(encodedValue))
        elseif (tonumber(encodedValue) ~= 'nil') then
            value = encodedValue
        end
        glue.append(dataRequest, value)
    end
    return dataRequest
end

-- Transform request into data
function maethrillian.convertRequestToData(request, properties)
    local data = {}
    local dataRequest = glue.string.split(',', request)
    for index, value in pairs(dataRequest) do
        local propertyName = properties[index]
        if (propertyName) then
            data[propertyName] = value
        end
    end
    return data
end

return maethrillian

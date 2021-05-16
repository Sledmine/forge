------------------------------------------------------------------------------
-- Maethrillian library
-- Sledmine
-- Version 4.0
-- Encode, decode tools for data manipulation
------------------------------------------------------------------------------
local glue = require "glue"
local maethrillian = {}

--- Compress table data in the given format
---@param inputTable table
---@param requestFormat table
---@param noHex boolean
---@return table
function maethrillian.encodeTable(inputTable, requestFormat, noHex)
    local compressedTable = {}
    for property, value in pairs(inputTable) do
        if (type(value) ~= "table") then
            local expectedProperty
            local encodeFormat
            for formatIndex, format in pairs(requestFormat) do
                if (glue.arrayhas(format, property)) then
                    expectedProperty = format[1]
                    encodeFormat = format[2]
                end
            end
            if (encodeFormat) then
                if (not noHex) then
                    compressedTable[property] = glue.tohex(string.pack(encodeFormat, value))
                else
                    compressedTable[property] = string.pack(encodeFormat, value)
                end
            else
                if (expectedProperty == property) then
                    compressedTable[property] = value
                end
            end
        end
    end
    return compressedTable
end

--- Format table into request string
---@param inputTable table
---@param requestFormat table
---@return string
function maethrillian.tableToRequest(inputTable, requestFormat, separator)
    local requestData = {}
    for property, value in pairs(inputTable) do
        if (requestFormat) then
            for formatIndex, format in pairs(requestFormat) do
                if (glue.arrayhas(format, property)) then
                    requestData[formatIndex] = value
                end
            end
        else
            requestData[#requestData + 1] = value
        end
    end
    return table.concat(requestData, separator)
end

--- Decompress table data given expected encoding format
---@param inputTable table
---@param requestFormat any
function maethrillian.decodeTable(inputTable, requestFormat)
    local dataDecompressed = {}
    for property, encodedValue in pairs(inputTable) do
        -- Get encode format for current value
        local encodeFormat
        for formatIndex, format in pairs(requestFormat) do
            if (glue.arrayhas(format, property)) then
                encodeFormat = format[2]
            end
        end
        if (encodeFormat) then
            -- There is a compression format available
            value = string.unpack(encodeFormat, glue.fromhex(tostring(encodedValue)))
        elseif (tonumber(encodedValue)) then
            -- Convert value into number
            value = tonumber(encodedValue)
        else
            -- Value is just a string
            value = encodedValue
        end
        dataDecompressed[property] = value
    end
    return dataDecompressed
end

--- Transform request into table given
---@param request string
---@param requestFormat table
function maethrillian.requestToTable(request, requestFormat, separator)
    local outputTable = {}
    local splitRequest = glue.string.split(request, separator)
    for index, value in pairs(splitRequest) do
        local currentFormat = requestFormat[index]
        local propertyName = currentFormat[1]
        local encodeFormat = currentFormat[2]
        -- Convert value into number
        local toNumberValue = tonumber(value)
        if (not encodeFormat and toNumberValue) then
            value = toNumberValue
        end
        if (propertyName) then
            outputTable[propertyName] = value
        end
    end
    return outputTable
end

return maethrillian

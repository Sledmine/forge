local convertColor = {}

--- Convert to decimal rgb color from hex string color
---@param hex string
---@param alpha number
function convertColor.hex(hex, alpha)
    local redColor, greenColor, blueColor = hex:gsub("#", ""):match("(..)(..)(..)")
    redColor, greenColor, blueColor = tonumber(redColor, 16) / 255,
                                      tonumber(greenColor, 16) / 255,
                                      tonumber(blueColor, 16) / 255
    redColor, greenColor, blueColor = math.floor(redColor * 100) / 100,
                                      math.floor(greenColor * 100) / 100,
                                      math.floor(blueColor * 100) / 100
    if alpha == nil then
        return redColor, greenColor, blueColor
    elseif alpha > 1 then
        alpha = alpha / 100
    end
    return redColor, greenColor, blueColor, alpha
end

--- Convert to decimal rgb color from byte rgb color
---@param r number
---@param g number
---@param b number
---@param alpha number
function convertColor.rgb(r, g, b, alpha)
    local redColor, greenColor, blueColor = r / 255, g / 255, b / 255
    redColor, greenColor, blueColor = math.floor(redColor * 100) / 100,
                                      math.floor(greenColor * 100) / 100,
                                      math.floor(blueColor * 100) / 100
    if alpha == nil then
        return redColor, greenColor, blueColor
    elseif alpha > 1 then
        alpha = alpha / 100
    end
    return redColor, greenColor, blueColor, alpha
end

return convertColor

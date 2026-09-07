local point = {}

local sqrt = math.sqrt

---Calculate distance between point `a` and point `b`. 
---@param a Point3d
---@param b Point3d
---@return integer
function point.distance(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return sqrt(dx * dx + dy * dy + dz * dz)
end

return point
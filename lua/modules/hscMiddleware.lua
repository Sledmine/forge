local blam = require "blam"
local hsc = require "hsc"
local hscDoc = require "hscDoc"
local concat = table.concat
local tagClasses = blam.tagClasses
local objectClasses = blam.objectClasses

function broadcastMessage(message)
    for playerIndex = 1, 16 do
        if player_present(playerIndex) then
            rprint(playerIndex, message)
        end
    end
    return false
end

function monocastMessage(playerIndex, message)
    rprint(playerIndex, message)
    return false
end

local snakeCaseTagClasses = {
    actor_variant = "actv",
    actor = "actr",
    antenna = "ant!",
    biped = "bipd",
    bitmap = "bitm",
    camera_track = "trak",
    color_table = "colo",
    continuous_damage_effect = "cdmg",
    contrail = "cont",
    damage_effect = "jpt!",
    decal = "deca",
    detail_object_collection = "dobc",
    device_control = "ctrl",
    device_light_fixture = "lifi",
    device_machine = "mach",
    device = "devi",
    dialogue = "udlg",
    effect = "effe",
    equipment = "eqip",
    flag = "flag",
    fog = "fog ",
    font = "font",
    garbage = "garb",
    gbxmodel = "mod2",
    globals = "matg",
    glow = "glw!",
    grenade_hud_interface = "grhi",
    hud_globals = "hudg",
    hud_message_text = "hmt ",
    hud_number = "hud#",
    item_collection = "itmc",
    item = "item",
    lens_flare = "lens",
    light_volume = "mgs2",
    light = "ligh",
    lightning = "elec",
    material_effects = "foot",
    meter = "metr",
    model_animations = "antr",
    model_collision_geometry = "coll",
    model = "mode",
    multiplayer_scenario_description = "mply",
    object = "obje",
    particle_system = "pctl",
    particle = "part",
    physics = "phys",
    placeholder = "plac",
    point_physics = "pphy",
    preferences_network_game = "ngpr",
    projectile = "proj",
    scenario_structure_bsp = "sbsp",
    scenario = "scnr",
    scenery = "scen",
    shader_environment = "senv",
    shader_model = "soso",
    shader_transparent_chicago_extended = "scex",
    shader_transparent_chicago = "schi",
    shader_transparent_generic = "sotr",
    shader_transparent_glass = "sgla",
    shader_transparent_meter = "smet",
    shader_transparent_plasma = "spla",
    shader_transparent_water = "swat",
    shader = "shdr",
    sky = "sky ",
    sound_environment = "snde",
    looping_sound = "lsnd",
    sound_scenery = "ssce",
    sound = "snd!",
    spheroid = "boom",
    string_list = "str#",
    tag_collection = "tagc",
    ui_widget_collection = "Soul",
    ui_widget_definition = "DeLa",
    unicode_string_list = "ustr",
    unit_hud_interface = "unhi",
    unit = "unit",
    vehicle = "vehi",
    virtual_keyboard = "vcky",
    weapon_hud_interface = "wphi",
    weapon = "weap",
    weather_particle_system = "rain",
    wind = "wind"
}

local packetPrefix = "@"
local packetSeparator = ","

local function getObjectIndexByName(objectName)
    local scenario = blam.scenario(0)
    assert(scenario, "Failed to load scenario tag")
    local objectIndex = table.indexof(scenario.objectNames, objectName)
    if objectIndex then
        return objectIndex
    end
end

local function getArgType(funcMeta, argIndex)
    local argType = funcMeta.args[argIndex]
    if table.indexof(hscDoc.nativeTypes, argType) then
        return argType
    end
    if argType == "object" or argType == "vehicle" or argType == "biped" or argType == "weapon" or
        argType == "unit" or argType == "scenery" or argType == "device" or argType == "object_name" then
        return "object"
    end
    local tagType = snakeCaseTagClasses[argType]
    if tagType then
        return "tag", tagType
    end
    return argType
end

--- Create a packet string for an hsc function invocation
---@param functionName string
---@param funcArgs string[]
---@return string | nil
local function createHscPacket(functionName, funcArgs)
    local funcMeta = table.find(hscDoc.functions, function(v, k)
        return v.funcName == functionName
    end)
    logger:debug("Creating HSC packet for function: \"{}\" with args: {}", functionName,
                 inspect(funcArgs))
    if not funcMeta then
        error("Function " .. functionName .. " not found in hscDoc")
    end
    local args = table.map(funcArgs, function(argValue, argIndex)
        local argType, tagType = getArgType(funcMeta, argIndex)
        if argType == "object" then
            local objectIndex = getObjectIndexByName(argValue)
            if objectIndex then
                -- logger:debug("Value {} is an object, converting to object index!", argValue)
                return objectIndex
            end
        elseif argType == "tag" then
            local argIsSubExpression = argValue:startswith "(" and argValue:endswith ")"
            if not argIsSubExpression then
                local tagEntry = blam.getTag(argValue, tagType)
                if tagEntry then
                    -- logger:debug("Value {} is a tag, converting to tag handle!", argValue)
                    return tagEntry.id
                end
            end
        end
        return argValue
    end)
    local name = funcMeta.funcName
    if (name:startswith("object_create") or name:startswith("object_destroy")) and
        not name:endswith("containing") then
        local objectNameIndex = tointeger(tostring(args[1]))
        if not objectNameIndex then
            -- This usually happens when the argument is a sub-expression like (object_get_first ...)
            -- We can change this later when Lua is able to resolve expression results to actual values
            logger:error("Failed to convert object name index to integer!")
            return
        end
        -- logger:debug("Object name index: {}", objectNameIndex)
        local scenario = blam.scenario(0)
        assert(scenario, "Failed to load scenario tag")

        -- FIXME Dirty hack to force default unit state
        -- local scenarioEntry = blam2.tag.findTag("", blam2.tag.groups.scenario) --[[@as MetaEngineScenarioTag]]
        -- assert(scenarioEntry)
        -- for vehicleElementIndex = 1, scenarioEntry.data.vehicles.count do
        --    local vehicleElement = scenarioEntry.data.vehicles.elements[vehicleElementIndex]
        --    if vehicleElement.name == objectNameIndex - 1 then
        --        logger:warning("Forcing close state in vehicle \"{}\"", funcArgs[1])
        --        script.thread(function (_, sleep)
        --            sleep(30)
        --            hsc.unit_close(funcArgs[1])
        --        end)()
        --    end
        -- end

        for objectId in pairs(blam.getObjects()) do
            local object = blam.getObject(objectId)
            if object and object.nameIndex == objectNameIndex - 1 then
                if object.class == objectClasses.biped then
                    -- logger:debug("Object {} is a biped, not syncing!", objectNameIndex)
                    return
                elseif object.class == objectClasses.vehicle then
                    -- logger:debug("Object {} is a vehicle, not syncing!", objectNameIndex)
                elseif object.class == objectClasses.weapon then
                    -- logger:debug("Object {} is a weapon, not syncing!", objectNameIndex)
                    return
                end
            end
        end
    end

    local packet = {packetPrefix .. funcMeta.hash, table.unpack(args)}

    return concat(packet, packetSeparator)
end

hsc.addMiddleWare(function(functionName, args)
    local funcMeta = table.find(hscDoc.functions, function(v, k)
        return v.funcName == functionName
    end)
    assert(funcMeta, "Function " .. functionName .. " not found in hscDoc")
    if funcMeta.isSynchronizable then
        local hscPacket = createHscPacket(functionName, args)
        if hscPacket then
            -- logger:debug("HSC Packet: {}", hscPacket)
            broadcastMessage(hscPacket)
        end
    end
end)

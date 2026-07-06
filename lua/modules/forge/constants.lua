local constants = {}
local engine = Engine
local findTags = engine.tag.findTags
local tagClasses = engine.tag.classes

constants.bipeds = {
    monitor = findTags("monitor", tagClasses.biped)[1],
    spartan = findTags("mjolnir", tagClasses.biped)[1]
}

constants.weaponHudInterfaces = {
    monitorCrosshair = findTags("ui\\hud\\forge", tagClasses.weaponHudInterface)[1]
}

--constants.scenario = findTags("", engine.tag.classes.scenario)[1]
constants.globals = findTags("", tagClasses.globals)[1]

return constants

local constants = {}
local engine = Engine
local findTags = engine.tag.findTags

constants.bipeds = {
    monitor = findTags("monitor", engine.tag.classes.biped)[1],
    spartan = findTags("mjolnir", engine.tag.classes.biped)[1],
}

--constants.scenario = findTags("", engine.tag.classes.scenario)[1]
constants.globals = findTags("", engine.tag.classes.globals)[1]

return constants

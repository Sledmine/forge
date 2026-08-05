local constants = {}
local engine = Engine

constants.bipeds = {
    monitor = engine.tag.filterTags("biped", "monitor")[1],
    player = engine.tag.filterTags("biped", "mjolnir")[1]
}

constants.weaponHudInterfaces = {
    monitorCrosshair = engine.tag.filterTags("weapon_hud_interface", "ui\\hud\\forge")[1]
}

--constants.scenario = engine.tag.filterTags("scenario", "")[1]
constants.globals = engine.tag.filterTags("globals", "")[1]

constants.menus = {
    monitor = engine.tag.filterTags("ui_widget_definition", "monitor\\monitor_menu")[1]
}

return constants

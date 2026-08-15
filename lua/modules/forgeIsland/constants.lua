local constants = {}
local engine = Engine

local function getTagCollection(pathFilter)
    if not pathFilter then
        return nil
    end
    local matches = engine.tag.filterTags("tag_collection", pathFilter)
    return matches and matches[1] or nil
end

constants.bipeds = {
    monitor = engine.tag.filterTags("biped", "monitor")[1],
    player = engine.tag.filterTags("biped", "mjolnir")[1]
}

constants.weaponHudInterfaces = {
    monitorCrosshair = engine.tag.filterTags("weapon_hud_interface", "ui\\hud\\forge")[1]
}

local cacheHeader = engine.cacheFile.getLoadedCacheFileHeader()
local scenarioName = cacheHeader and cacheHeader.scenarioName or ""

constants.tagCollections = {
    forgeObjects = getTagCollection(scenarioName .. "_objects") or
        getTagCollection("custom_objects")
}

--constants.scenario = engine.tag.filterTags("scenario", "")[1]
constants.globals = engine.tag.filterTags("globals", "")[1]

constants.menus = {
    monitor = engine.tag.filterTags("ui_widget_definition", "monitor\\monitor_menu")[1]
}

return constants

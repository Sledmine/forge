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
        getTagCollection(scenarioName:replace("_dev", "")) or getTagCollection("custom_objects")
}

--constants.scenario = engine.tag.filterTags("scenario", "")[1]
constants.globals = engine.tag.filterTags("globals", "")[1]

constants.menus = {
    monitor = engine.tag.filterTags("ui_widget_definition", "monitor\\monitor_menu")[1]
}

constants.fonts = {
    blenderProBook = {
        small = engine.tag.filterTags("vector_font", "blender_pro_book_small")[1],
    },
    devgothic = engine.tag.filterTags("vector_font", "devgothic")[1],
    arameThin = engine.tag.filterTags("vector_font", "arame_thin")[1]
}

return constants

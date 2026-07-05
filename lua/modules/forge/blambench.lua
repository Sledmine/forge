local function now()
    if os and type(os.clock) == "function" then
        return os.clock()
    end
    if type(get_tick_count) == "function" then
        return get_tick_count() / 1000
    end
    return 0
end

local function profileFunctionCalls(tbl, key, sink)
    local original = tbl and tbl[key]
    if type(original) ~= "function" then
        return nil
    end

    sink[key] = sink[key] or {calls = 0, total = 0}

    tbl[key] = function(...)
        local t0 = now()
        local result = {original(...)}
        local elapsed = now() - t0
        local stat = sink[key]
        stat.calls = stat.calls + 1
        stat.total = stat.total + elapsed
        return table.unpack(result)
    end

    return function()
        tbl[key] = original
    end
end

local function runFindTagsBench()
    local keyword = "weapons"
    local tagGroup = "weap"
    local iterations = 2

    logger:info("Running findTags benchmark: keyword='" .. keyword .. "' tagGroup='" .. tagGroup .. "'")

    local blam2Stats = {}
    local restoreBlam2GetTag = profileFunctionCalls(blam, "getTagEntry", blam2Stats)
    local restoreBlam2Class = profileFunctionCalls(blam, "integerToTagGroup", blam2Stats)

    local t0 = now()
    for _ = 1, iterations do
        blam.tag.findTags(keyword, tagGroup)
    end
    local blam2Total = now() - t0

    if restoreBlam2GetTag then
        restoreBlam2GetTag()
    end
    if restoreBlam2Class then
        restoreBlam2Class()
    end

    local legacyStats = {}
    local restoreLegacyGetTag = profileFunctionCalls(legacyBlam, "getTag", legacyStats)
    local restoreLegacyTag = profileFunctionCalls(legacyBlam, "tag", legacyStats)

    t0 = now()
    for _ = 1, iterations do
        legacyBlam.findTagsList(keyword, tagGroup)
    end
    local legacyTotal = now() - t0

    if restoreLegacyGetTag then
        restoreLegacyGetTag()
    end
    if restoreLegacyTag then
        restoreLegacyTag()
    end

    logger:info(string.format("blam2.findTags total=%.6fs avg=%.6fs", blam2Total,
                              blam2Total / iterations))
    logger:info(string.format("blam.findTagsList total=%.6fs avg=%.6fs", legacyTotal,
                              legacyTotal / iterations))

    if legacyTotal > 0 then
        logger:warning(string.format("Relative slowdown blam2/blam = %.2fx", blam2Total /
                                         legacyTotal))
    end

    local blam2GetTagStat = blam2Stats.getTagEntry
    if blam2GetTagStat then
        logger:info(string.format("blam2.getTagEntry calls=%d total=%.6fs", blam2GetTagStat.calls,
                                  blam2GetTagStat.total))
    end
    local blam2ClassStat = blam2Stats.integerToTagGroup
    if blam2ClassStat then
        logger:info(string.format("blam2.integerToTagGroup calls=%d total=%.6fs",
                                  blam2ClassStat.calls, blam2ClassStat.total))
    end

    local legacyGetTagStat = legacyStats.getTag
    if legacyGetTagStat then
        logger:info(string.format("blam.getTag calls=%d total=%.6fs", legacyGetTagStat.calls,
                                  legacyGetTagStat.total))
    end
    local legacyTagStat = legacyStats.tag
    if legacyTagStat then
        logger:info(string.format("blam.tag calls=%d total=%.6fs", legacyTagStat.calls,
                                  legacyTagStat.total))
    end
end
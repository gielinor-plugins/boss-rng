-- Turns a boss's saved tallies into the numbers Boss RNG shows: expected and
-- received uniques, luck, and the dry streak. Plain Lua, so it can be tested offline.

local luck = require("src/luck")
local tracker = require("src/tracker")

local stats = {}

-- Share of players who would have had a unique within the dry streak, from its
-- kills per mode ({ [mode name] = kills }). Each mode's dry kills use that
-- mode's own rates: the chance of missing every time is the product of each
-- mode's chance of missing.
local function dryShare(boss, dry)
    local missAll = 1
    for _, mode in ipairs(boss.modes) do
        local dryKills = dry[mode.name] or 0
        missAll = missAll * (1 - luck.DryPercentile(luck.ChanceOfAny(mode.rolls), dryKills))
    end
    return 1 - missAll
end

-- Uniques an average player would have from kills ({ [mode name] = kills }), by
-- item id. They add up per mode, since each mode can have its own rates.
local function expectedPerItem(boss, kills)
    local expected = {}
    for _, mode in ipairs(boss.modes) do
        local modeKills = kills[mode.name] or 0
        for itemID, chance in pairs(luck.ItemChances(mode.rolls)) do
            expected[itemID] = (expected[itemID] or 0) + modeKills * chance
        end
    end
    return expected
end

-- Tracked drops per unique, { [item id text] = count }, shaped like all-time counts.
local function trackedCounts(tallies)
    local counts = {}
    for key, item in pairs(tallies.items) do
        counts[key] = item.count
    end
    return counts
end

-- Stats for one boss from its tallies (see tracker.Tallies), or nil without any.
-- Luck uses the game's all-time totals once captured, else the tracked ones.
-- Dry streaks come from tracking, since the game doesn't show them, except for
-- uniques the all-time counts say were never received: every kill is dry there.
--   allTime     true if kills and received are all-time totals
--   kills       kills
--   expected    uniques an average player would have after those kills
--   received    uniques the player received
--   luck        share of players with fewer uniques, from 0 to 1 (nil without kills)
--   dryKills    kills since the last unique
--   dryAtLeast  true if the streak may be longer: no unique tracked yet, and
--               there may be kills from before tracking
--   dryShare    share of players who would have had a unique within dryKills
--   items       { [itemID] = { expected, received, luck, dryKills, dryAtLeast } } per unique
function stats.ForBoss(boss, tallies)
    if tallies == nil then
        return nil
    end
    local allTime = tracker.AllTime(tallies)
    local kills = allTime and allTime.kills or tallies.kills
    local received = allTime and allTime.items or trackedCounts(tallies)
    local trackedKills = tracker.Total(tallies.kills)
    -- Only all-time totals can show that every kill was tracked.
    local allTracked = allTime ~= nil and tracker.Total(allTime.kills) <= trackedKills

    local result = { allTime = allTime ~= nil, kills = tracker.Total(kills), expected = 0, received = 0, items = {} }
    for itemID, expected in pairs(expectedPerItem(boss, kills)) do
        local key = tostring(itemID)
        local tracked = tallies.items[key] -- nil until a drop is tracked
        local item = { expected = expected, received = received[key] or 0 }
        if allTime and item.received == 0 then
            item.dryKills, item.dryAtLeast = result.kills, false
        else
            item.dryKills = trackedKills - (tracked and tracked.atKill or 0)
            item.dryAtLeast = tracked == nil and not allTracked
        end
        item.luck = luck.Percentile(item.expected, item.received)
        result.items[itemID] = item
        result.expected = result.expected + item.expected
        result.received = result.received + item.received
    end

    result.luck = luck.Percentile(result.expected, result.received)
    local dry = tallies.dry
    if allTime and result.received == 0 then
        dry, result.dryAtLeast = allTime.kills, false
    else
        result.dryAtLeast = next(tallies.items) == nil and not allTracked
    end
    result.dryKills = tracker.Total(dry)
    result.dryShare = dryShare(boss, dry)
    return result
end

-- Luck across several bosses' stats (nil entries are skipped): kills, expected
-- and received add up, and the same percentile applies to the totals.
function stats.Overall(bossStats)
    local kills, expected, received = 0, 0, 0
    for _, result in pairs(bossStats) do
        kills = kills + result.kills
        expected = expected + result.expected
        received = received + result.received
    end
    return { kills = kills, expected = expected, received = received, luck = luck.Percentile(expected, received) }
end

return stats

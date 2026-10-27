-- Turns a boss's saved tallies into the numbers Boss RNG shows: expected and
-- received uniques, luck, and the dry streak. Plain Lua, so it can be tested offline.

local luck = require("src/luck")
local tracker = require("src/tracker")

local stats = {}

-- Share of players who would have had a unique within the dry streak. Each mode's
-- dry kills use that mode's own rates: the chance of missing every time is the
-- product of each mode's chance of missing.
local function dryShare(boss, tallies)
    local missAll = 1
    for _, mode in ipairs(boss.modes) do
        local dryKills = tallies.dry[mode.name] or 0
        missAll = missAll * (1 - luck.DryPercentile(luck.ChanceOfAny(mode.rolls), dryKills))
    end
    return 1 - missAll
end

-- Total kills in a { [mode name] = kills } table.
local function sum(kills)
    local total = 0
    for _, n in pairs(kills) do
        total = total + n
    end
    return total
end

-- Stats for one boss from its tallies (see tracker.Tallies), or nil without any.
-- Luck uses the game's all-time totals once captured, else the tracked ones.
-- Dry streaks always come from tracking, since the game doesn't show them.
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
    local trackedKills = sum(tallies.kills)
    -- Only all-time totals can show that every kill was tracked.
    local allTracked = allTime ~= nil and sum(allTime.kills) <= trackedKills
    local result = { allTime = allTime ~= nil, kills = sum(kills), expected = 0, received = 0, items = {} }

    -- Expected drops add up per mode, since each mode can have its own rates.
    for _, mode in ipairs(boss.modes) do
        local modeKills = kills[mode.name] or 0
        for itemID, chance in pairs(luck.ItemChances(mode.rolls)) do
            local item = result.items[itemID] or { expected = 0 }
            item.expected = item.expected + modeKills * chance
            result.items[itemID] = item
        end
    end

    for itemID, item in pairs(result.items) do
        local key = tostring(itemID)
        local tracked = tallies.items[key]
        if allTime then
            item.received = allTime.items[key] or 0
        else
            item.received = tracked and tracked.count or 0
        end
        item.luck = luck.Percentile(item.expected, item.received)
        item.dryKills = trackedKills - (tracked and tracked.atKill or 0)
        item.dryAtLeast = tracked == nil and not allTracked
        result.expected = result.expected + item.expected
        result.received = result.received + item.received
    end

    result.luck = luck.Percentile(result.expected, result.received)
    result.dryKills = sum(tallies.dry)
    result.dryAtLeast = next(tallies.items) == nil and not allTracked
    result.dryShare = dryShare(boss, tallies)
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

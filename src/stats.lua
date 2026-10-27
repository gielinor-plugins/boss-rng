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

-- Stats for one boss from its tallies (see tracker.Tallies), or nil without any:
--   kills      kills since install
--   expected   uniques an average player would have after those kills
--   received   uniques the player received
--   luck       share of players with fewer uniques, from 0 to 1 (nil without kills)
--   dryKills   kills since the last unique (all kills if none yet)
--   dryShare   share of players who would have had a unique within dryKills
--   items      { [itemID] = { expected, received, luck, dryKills } } per unique
function stats.ForBoss(boss, tallies)
    if tallies == nil then
        return nil
    end
    local kills = tracker.Kills(tallies)
    local result = { kills = kills, expected = 0, received = 0, items = {} }

    -- Expected drops add up per mode, since each mode can have its own rates.
    for _, mode in ipairs(boss.modes) do
        local modeKills = tallies.kills[mode.name] or 0
        for itemID, chance in pairs(luck.ItemChances(mode.rolls)) do
            local item = result.items[itemID] or { expected = 0 }
            item.expected = item.expected + modeKills * chance
            result.items[itemID] = item
        end
    end

    for itemID, item in pairs(result.items) do
        local saved = tallies.items[tostring(itemID)]
        item.received = saved and saved.count or 0
        item.luck = luck.Percentile(item.expected, item.received)
        item.dryKills = kills - (saved and saved.atKill or 0)
        result.expected = result.expected + item.expected
        result.received = result.received + item.received
    end

    result.luck = luck.Percentile(result.expected, result.received)
    result.dryKills = 0
    for _, dryKills in pairs(tallies.dry) do
        result.dryKills = result.dryKills + dryKills
    end
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

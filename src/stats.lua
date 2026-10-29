-- Turns a boss's saved tallies into the numbers Boss RNG shows: expected and
-- received uniques, luck, and the dry streak. Plain Lua, so it can be tested offline.

local luck = require("src/luck")
local tracker = require("src/tracker")

local stats = {}

-- A mode's rolls: a table, or a function of the player's picks for the boss's
-- choices ({ [choice key] = value }, see src/choices.lua).
function stats.Rolls(mode, picks)
    if type(mode.rolls) == "function" then
        return mode.rolls(picks)
    end
    return mode.rolls
end

-- A boss's modes: its own, then one per tracked kill counted for a mode made
-- from the game's values at the kill (see killEvent in src/bosses.lua).
local function modesOf(boss, tallies)
    local modes, known = {}, {}
    for _, mode in ipairs(boss.modes) do
        table.insert(modes, mode)
        known[mode.name] = true
    end
    if boss.modeFor then
        local names = {}
        for name in pairs(tallies.kills) do
            if not known[name] then
                table.insert(names, name)
            end
        end
        table.sort(names) -- the same order every time
        for _, name in ipairs(names) do
            table.insert(modes, boss.modeFor(name))
        end
    end
    return modes
end

-- Tracked kills of modes in a kill count (all but partial Barrows chests, say).
local function trackedInKillCounts(modes, tallies)
    local total = 0
    for _, mode in ipairs(modes) do
        if mode.kc then
            total = total + (tallies.kills[mode.name] or 0)
        end
    end
    return total
end

-- A boss's kills without Boss RNG (its kill counts less the tracked kills in
-- them: from before it was installed, while it was off, or on another
-- computer) and their share of its all-time kills. Never below 0, in case the
-- game's count lags the tracked one.
function stats.Untracked(boss, tallies, allTime)
    local total = tracker.Total(allTime.kills)
    local untracked = math.max(total - trackedInKillCounts(modesOf(boss, tallies), tallies), 0)
    return untracked, total > 0 and untracked / total or 0
end

-- Each mode's chance per kill of each unique: { [mode name] = { [item id] = chance } }.
local function chancesPerMode(modes, picks)
    local chances = {}
    for _, mode in ipairs(modes) do
        chances[mode.name] = luck.ItemChances(stats.Rolls(mode, picks))
    end
    return chances
end

-- Uniques an average player would have from kills ({ [mode name] = kills }), by item id.
local function expectedFrom(modes, chances, kills)
    local expected = {}
    for _, mode in ipairs(modes) do
        for itemID, chance in pairs(chances[mode.name]) do
            expected[itemID] = (expected[itemID] or 0) + (kills[mode.name] or 0) * chance
        end
    end
    return expected
end

-- Share of players who would have had a unique within the dry streak, from its
-- kills per mode ({ [mode name] = kills }). Each mode's dry kills use that
-- mode's own rates: the chance of missing every time is the product of each
-- mode's chance of missing. counted is the set of uniques the streak counts.
local function dryShare(modes, picks, dry, counted)
    local missAll = 1
    for _, mode in ipairs(modes) do
        local dryKills = dry[mode.name] or 0
        missAll = missAll * (1 - luck.DryPercentile(luck.ChanceOfAny(stats.Rolls(mode, picks), counted), dryKills))
    end
    return 1 - missAll
end

-- The mode a kill count var's kills from before tracking go to: its only mode,
-- the one marked untracked (see src/bosses.lua), or for modes that are tiers of
-- a choice, the picked one.
local function earlierMode(modes, picks)
    if #modes == 1 then
        return modes[1]
    end
    for _, mode in ipairs(modes) do
        if mode.untracked then
            return mode
        end
    end
    for _, mode in ipairs(modes) do
        if mode.tier and picks[mode.tier.choice] == mode.tier.value then
            return mode
        end
    end
    return nil
end

-- Modes grouped by kill count var: { [var] = { modes } }. Modes outside any
-- kill count are left out.
local function modesByVar(modes)
    local groups = {}
    for _, mode in ipairs(modes) do
        if mode.kc then
            groups[mode.kc] = groups[mode.kc] or {}
            table.insert(groups[mode.kc], mode)
        end
    end
    return groups
end

-- Kills per mode, { [mode name] = kills }: the tracked kills, plus with all-time
-- totals each kill count var's kills from before tracking.
local function killsPerMode(allModes, tallies, allTime, picks)
    local kills = {}
    for _, mode in ipairs(allModes) do
        kills[mode.name] = tallies.kills[mode.name] or 0
    end
    if allTime then
        for kc, modes in pairs(modesByVar(allModes)) do
            local earlier = allTime.kills[kc]
            for _, mode in ipairs(modes) do
                earlier = earlier - kills[mode.name]
            end
            local mode = earlierMode(modes, picks)
            if mode and earlier > 0 then
                kills[mode.name] = kills[mode.name] + earlier
            end
        end
    end
    return kills
end

-- Kills of the modes that can drop an item: counts[mode name], less
-- since[mode name] if given.
local function killsThatCanDrop(modes, chances, itemID, counts, since)
    local total = 0
    for _, mode in ipairs(modes) do
        if chances[mode.name][itemID] then
            total = total + (counts[mode.name] or 0) - (since and since[mode.name] or 0)
        end
    end
    return total
end

-- True if a boss has kills Boss RNG didn't track that could drop an item: an
-- all-time kill count above its modes' tracked kills, for modes that can drop it.
local function hasUntrackedKillsThatCanDrop(boss, picks, tallies, allTime, itemID)
    local allModes = modesOf(boss, tallies)
    local chances = chancesPerMode(allModes, picks)
    for kc, modes in pairs(modesByVar(allModes)) do
        local tracked, canDrop = 0, false
        for _, mode in ipairs(modes) do
            tracked = tracked + (tallies.kills[mode.name] or 0)
            canDrop = canDrop or chances[mode.name][itemID] ~= nil
        end
        if canDrop and allTime.kills[kc] > tracked then
            return true
        end
    end
    return false
end

-- Tracked drops of a unique.
local function trackedCount(tallies, itemID)
    local drop = tallies.items[tostring(itemID)]
    return drop and drop.count or 0
end

-- An item's numbers: expected and received, its luck, and its dry streak from
-- tracking (atKills of its latest tracked drop), unless all-time counts say it
-- was never received: then every kill that could drop it is dry.
local function itemNumbers(modes, chances, itemID, expected, received, tallies, allTimeKills, allTracked)
    local drop = tallies.items[tostring(itemID)]
    local item = { expected = expected, received = received, luck = luck.Percentile(expected, received) }
    if allTimeKills and received == 0 then
        item.dryKills, item.dryAtLeast = killsThatCanDrop(modes, chances, itemID, allTimeKills), false
    else
        item.dryKills = killsThatCanDrop(modes, chances, itemID, tallies.kills, drop and drop.atKills)
        item.dryAtLeast = drop == nil and not allTracked
    end
    return item
end

-- Uniques sharing a group (see src/bosses.lua) become one row, under the group's
-- lowest item id, with the group: expected and received add up, and the dry
-- streak is the shortest of its items' (a drop of any of them ends it).
local function grouped(boss, items)
    local members = {} -- [group] = item ids
    for itemID in pairs(items) do
        local group = boss.items[itemID].group
        if group then
            members[group] = members[group] or {}
            table.insert(members[group], itemID)
        end
    end
    for group, ids in pairs(members) do
        table.sort(ids)
        local row = { group = group, expected = 0, received = 0 }
        for _, itemID in ipairs(ids) do
            local item = items[itemID]
            row.expected = row.expected + item.expected
            row.received = row.received + item.received
            if row.dryKills == nil or item.dryKills < row.dryKills
                or (item.dryKills == row.dryKills and not item.dryAtLeast) then
                row.dryKills, row.dryAtLeast = item.dryKills, item.dryAtLeast
            end
            items[itemID] = nil
        end
        row.luck = luck.Percentile(row.expected, row.received)
        items[ids[1]] = row
    end
end

-- Stats for one boss from its entry, { boss, tallies, picks, allTime }: its
-- tallies (see tracker.Tallies), the player's picks for its choices (see
-- choices.For) and the game's all-time totals (see gamevars.AllTime, nil until
-- they can be read); and the pooled uniques (see stats.Pools). Nil without tallies.
-- Luck uses the all-time totals once they can be read, else the tracked ones. Dry
-- streaks come from tracking, since the game doesn't show them, except for
-- uniques the all-time counts say were never received: every kill that could
-- drop them is dry there. A pooled unique uses tracked numbers until every boss
-- listing it has all-time totals; then its share of the one log count, once
-- known, else it's left out, table row and all, until the player splits it.
--   allTime     true if kills and received are all-time totals
--   kills       kills in the boss's kill counts
--   extraKills  tracked kills outside them (partial Barrows chests), counted
--               in the rest, called extraLabel ("partial chest")
--   expected    uniques an average player would have after those kills
--   received    uniques the player received
--   luck        share of players with fewer uniques, from 0 to 1 (nil without kills)
--   dryKills    kills since the last unique
--   dryAtLeast  true if the streak may be longer: no unique tracked yet, and
--               there may be kills from before tracking
--   dryShare    share of players who would have had a unique within dryKills
--   items       { [itemID] = { expected, received, luck, dryKills, dryAtLeast } } per
--               unique, or per group of uniques (with its group)
function stats.ForBoss(entry, pools)
    local boss, tallies, allTime = entry.boss, entry.tallies, entry.allTime
    if tallies == nil then
        return nil
    end
    local picks = entry.picks or {}
    local modes = modesOf(boss, tallies)
    local kills = killsPerMode(modes, tallies, allTime, picks)
    -- Only all-time totals can show that every kill was tracked.
    local allTracked = allTime ~= nil and tracker.Total(allTime.kills) <= trackedInKillCounts(modes, tallies)
    local chances = chancesPerMode(modes, picks)
    local trackedExpected = expectedFrom(modes, chances, tallies.kills)

    local inKillCounts, extra = 0, 0
    for _, mode in ipairs(modes) do
        if mode.kc then
            inKillCounts = inKillCounts + kills[mode.name]
        else
            extra = extra + kills[mode.name]
        end
    end
    local result = { allTime = allTime ~= nil, kills = inKillCounts, extraKills = extra,
        extraLabel = boss.extraKills, expected = 0, received = 0, items = {} }
    local counted, anyTracked = {}, false -- the uniques in the boss's numbers
    for itemID, expected in pairs(expectedFrom(modes, chances, kills)) do
        local pool = boss.items[itemID].pooledBy and pools and pools[itemID]
        if not (pool and pool.untracked and not pool.received) then
            local item
            if not allTime or (pool and pool.untracked == nil) then
                local received = trackedCount(tallies, itemID)
                item = itemNumbers(modes, chances, itemID, trackedExpected[itemID], received, tallies)
            else
                local received = pool and pool.received and pool.received[boss.key] or allTime.items[tostring(itemID)]
                item = itemNumbers(modes, chances, itemID, expected, received, tallies, kills, allTracked)
            end
            result.items[itemID] = item
            counted[itemID] = true
            anyTracked = anyTracked or tallies.items[tostring(itemID)] ~= nil
            result.expected = result.expected + item.expected
            result.received = result.received + item.received
        end
    end

    result.luck = luck.Percentile(result.expected, result.received)
    local dry = tallies.dry
    if allTime and result.received == 0 then
        dry, result.dryAtLeast = kills, false
    else
        result.dryAtLeast = not anyTracked and not allTracked
    end
    result.dryKills = tracker.Total(dry)
    result.dryShare = dryShare(modes, picks, dry, counted)
    grouped(boss, result.items)
    return result
end

-- True if split, { [boss key] = count }, gives each sharer a count, adding up to total.
local function validSplit(split, sharers, total)
    if split == nil then
        return false
    end
    local sum = 0
    for _, boss in ipairs(sharers) do
        local count = split[boss.key]
        if type(count) ~= "number" or count < 0 then
            return false
        end
        sum = sum + count
    end
    return sum == total
end

-- How a pooled unique's one log count splits between the bosses listing it
-- (sharers), from their entries by boss key and the player's saved split.
local function resolve(itemID, sharers, entries, split)
    local pool = { sharers = sharers }
    local shared, tracked, couldDrop = 0, 0, {}
    for _, boss in ipairs(sharers) do
        local entry = entries[boss.key]
        local allTime = entry and entry.allTime
        if not allTime then
            return pool -- untracked drops unknown: each boss counts what it tracked
        end
        shared = math.max(shared, allTime.items[tostring(itemID)])
        tracked = tracked + trackedCount(entry.tallies, itemID)
        if hasUntrackedKillsThatCanDrop(boss, entry.picks or {}, entry.tallies, allTime, itemID) then
            table.insert(couldDrop, boss)
        end
    end
    pool.untracked = math.max(shared - tracked, 0)
    pool.ask = pool.untracked > 0 and #couldDrop == 2 and #sharers == 2

    local untracked = {} -- per boss key
    if #couldDrop == 1 then
        untracked[couldDrop[1].key] = pool.untracked
    elseif pool.untracked > 0 then
        if not (pool.ask and validSplit(split, sharers, pool.untracked)) then
            return pool -- not split: left out until the player splits it
        end
        untracked = split
        pool.split = split
    end
    pool.received = {}
    for _, boss in ipairs(sharers) do
        pool.received[boss.key] = trackedCount(entries[boss.key].tallies, itemID) + (untracked[boss.key] or 0)
    end
    return pool
end

-- The pooled uniques (see src/bosses.lua) among entries (see stats.ForBoss),
-- and how each one's log count splits between the bosses listing it, using the
-- player's saved splits ({ [item id text] = { [boss key] = count } }):
--   sharers    the bosses listing it
--   untracked  its drops Boss RNG didn't track, once every sharer has all-time
--              totals; else nil, and each boss counts the drops it tracked
--   ask        true if the player can split them: two sharers with untracked
--              kills that could drop it
--   split      the player's split of untracked drops, { [boss key] = count },
--              while it adds up
--   received   { [boss key] = drops }, once known: tracked drops, plus the
--              player's split of untracked ones, or all of them for the only
--              sharer whose untracked kills could drop it
function stats.Pools(entries, splits)
    local byKey, pools = {}, {}
    for _, entry in ipairs(entries) do
        byKey[entry.boss.key] = entry
    end
    for _, entry in ipairs(entries) do
        for itemID, item in pairs(entry.boss.items) do
            if item.pooledBy and pools[itemID] == nil then
                pools[itemID] = resolve(itemID, item.pooledBy, byKey, splits[tostring(itemID)])
            end
        end
    end
    return pools
end

-- Luck across several bosses' stats: kills, expected and received add up, and
-- the same percentile applies to the totals.
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

-- Turns a boss's tracked tallies into the numbers Boss RNG shows, rating each kill at
-- the drop rates in effect on its day. The game's all-time totals are passed through,
-- never used for luck.

local luck = require("src/core/luck")
local rates = require("src/core/rates")
local tallies = require("src/core/tallies")

local stats = {}

-- Luck shows once an average player would have this many uniques, or from the first
-- unique. Before that a dry streak is normal, so it shows how many would still be dry.
local MIN_EXPECTED = 1

-- Adding many kills' chances leaves float error in the last digits (exactly 1 can add up
-- to 0.9999999999999999), so comparisons allow this much: far more than float error,
-- far less than any real difference.
local FLOAT_ERROR = 1e-9

local NO_RATES = {} -- the rate values of a boss without any

-- A boss's rates on a day: from boss.rates (a test boss's own history), or from the rate
-- files by its key.
local function valuesOn(boss, day)
    local history = boss.rates or rates.For(boss.key)
    return history and history:On(day) or NO_RATES
end

-- A mode's rolls on a day (nil or 0: today). mode.rolls can be a function of that day's
-- rates, the readings, and the averages of that day's sums (or nil).
function stats.Rolls(boss, mode, readings, day, means)
    local rolls = mode.rolls or {}
    if type(rolls) == "function" then
        return rolls(valuesOn(boss, day), readings, means)
    end
    return rolls
end

-- Kills of one mode in one rate version have the same chances (see "Rate versions" in
-- docs/technical/luck-math.md), so a boss's kills are worked out in batches:
-- batchesOf(byMode) adds byMode's kills up by mode and version, as a list of
-- { mode, kills, rolls, chances }.
-- A mode with sums that day (Arch-Glacor) has its own chances that day, so the day is
-- its own version. Rolls and chances are worked out once per mode and version.
local function batcher(boss, readings, t)
    local versions = {} -- [mode][version key] = { rolls, chances }
    local function versionOn(mode, day)
        local means = tallies.Means(t, mode.key, day)
        local key = means and day or valuesOn(boss, day)
        versions[mode] = versions[mode] or {}
        if versions[mode][key] == nil then
            local rolls = stats.Rolls(boss, mode, readings, day, means)
            versions[mode][key] = { rolls = rolls, chances = luck.ItemChances(rolls) }
        end
        return versions[mode][key]
    end

    local batches = {} -- [byMode] = its batches, worked out once
    return function(byMode)
        if batches[byMode] == nil then
            local list, byVersion = {}, {}
            for modeKey, byDay in pairs(byMode) do
                local mode = boss.modes[modeKey] -- nil for a mode the boss no longer has
                for day, kills in pairs(mode and byDay or {}) do
                    local version = versionOn(mode, tonumber(day))
                    local batch = byVersion[version]
                    if batch == nil then
                        batch = { mode = mode, kills = 0, rolls = version.rolls }
                        batch.chances = version.chances
                        byVersion[version] = batch
                        table.insert(list, batch)
                    end
                    batch.kills = batch.kills + kills
                end
            end
            batches[byMode] = list
        end
        return batches[byMode]
    end
end

local function killsThatCanDrop(batchesOf, byMode, itemID)
    local total = 0
    for _, batch in ipairs(batchesOf(byMode)) do
        if batch.chances[itemID] then
            total = total + batch.kills
        end
    end
    return total
end

-- Share of players who'd have got at least one of counted (a set of item ids) within
-- byMode's kills.
local function dryShare(batchesOf, byMode, counted)
    local missAll = 1
    for _, batch in ipairs(batchesOf(byMode)) do
        local chance = luck.ChanceOfAny(batch.rolls, counted)
        missAll = missAll * (1 - luck.DryPercentile(chance, batch.kills))
    end
    return 1 - missAll
end

-- Nil until expected reaches MIN_EXPECTED or a unique is received.
local function luckOf(expected, received)
    if expected > 0 and (expected >= MIN_EXPECTED - FLOAT_ERROR or received > 0) then
        return luck.Percentile(expected, received)
    end
    return nil
end

-- Kills until expected reaches MIN_EXPECTED, at rate expected uniques per kill; nil
-- without a rate.
local function killsToLuck(expected, rate)
    if rate <= 0 then
        return nil
    end
    -- Less FLOAT_ERROR, so float error can't round up to an extra kill.
    return math.max(1, math.ceil((MIN_EXPECTED - expected) / rate - FLOAT_ERROR))
end

-- Uniques sharing a group become one row under the group's lowest item id: their counts
-- add up, and the row's dry streak is its shortest member's. shareOf(itemID, ids) gives
-- a dry share.
local function grouped(boss, items, shareOf)
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
        local row = { group = group, expected = 0, received = 0, allTime = 0 }
        local streak, counted = nil, {} -- the item whose streak is the row's
        for _, itemID in ipairs(ids) do
            counted[itemID] = true
            local item = items[itemID]
            row.expected = row.expected + item.expected
            row.received = row.received + item.received
            row.allTime = item.allTime and row.allTime and row.allTime + item.allTime
            if
                row.dryKills == nil
                or item.dryKills < row.dryKills
                or (item.dryKills == row.dryKills and not item.dryAtLeast)
            then
                row.dryKills, row.dryAtLeast, streak = item.dryKills, item.dryAtLeast, itemID
            end
            items[itemID] = nil
        end
        row.luck = luckOf(row.expected, row.received)
        row.dryShare = shareOf(streak, counted)
        items[ids[1]] = row
    end
end

local function sum(values)
    local total = 0
    for _, n in pairs(values) do
        total = total + n
    end
    return total
end

-- A stacked unique's collection log count counts items, not drops, so it's shown apart
-- in stacks.
local function allTimeTotals(boss, allTime)
    local totals = { kills = sum(allTime.kills), received = 0, stacks = {} }
    for key, count in pairs(allTime.items) do
        local item = boss.items[tonumber(key)]
        local stack = item and item.stack
        if stack then
            table.insert(totals.stacks, { word = stack.word, plural = stack.plural, count = count })
        else
            totals.received = totals.received + count
        end
    end
    table.sort(totals.stacks, function(a, b)
        return a.word < b.word
    end)
    return totals
end

-- Stats from { boss, tallies, readings, allTime }, or nil without tallies:
--   kills, extraKills   tracked kills in the kill counts, and outside them (partial
--                       Barrows chests, called extraLabel)
--   piles               loot piles over tracked kills, for modes that count them
--                       (Kerapac), or nil
--   expected, received  uniques an average player would have, and uniques tracked
--   luck, killsToLuck   share of players with fewer uniques (or nil, see luckOf),
--                       and kills until it shows
--   dryKills, dryShare  kills since the last unique, and share who'd have had one
--   dryAtLeast          true if no unique is tracked and there may be earlier kills
--   allTime, unit       the game's totals (nil until read); what a kill is ("chest")
--   items               per unique, or group (with its group): { expected, received,
--                       luck, dryKills, dryAtLeast, dryShare, allTime }
function stats.ForBoss(entry)
    local boss, t, allTime = entry.boss, entry.tallies, entry.allTime
    if t == nil then
        return nil
    end
    local batchesOf = batcher(boss, entry.readings or {}, t)

    local result =
        { kills = 0, extraKills = 0, extraLabel = boss.extraKills, unit = boss.unit, items = {} }
    local expected = {} -- by item id
    local countedExpected = 0 -- over kills in the kill counts
    for _, batch in ipairs(batchesOf(t.kills)) do
        local mode, kills = batch.mode, batch.kills
        local key = mode.partial and "extraKills" or "kills"
        result[key] = result[key] + kills
        if mode.piles then
            result.piles = (result.piles or 0) + kills * mode.piles
        end
        for itemID, chance in pairs(batch.chances) do
            expected[itemID] = (expected[itemID] or 0) + kills * chance
            if not mode.partial then
                countedExpected = countedExpected + kills * chance
            end
        end
    end
    if allTime then
        result.allTime = allTimeTotals(boss, allTime)
    end
    -- Without all-time totals, there may always have been kills before tracking.
    local mayHaveEarlier = allTime == nil or result.allTime.kills > result.kills

    result.expected, result.received = 0, 0
    local counted = {} -- the uniques in the boss's dry streak
    local streaks = {} -- [streak key] = its kills, worked out once
    local function streak(key)
        streaks[key] = streaks[key] or tallies.Dry(t, key)
        return streaks[key]
    end
    local function shareOf(itemID, ids)
        return dryShare(batchesOf, streak(tostring(itemID)), ids)
    end
    for itemID, item in pairs(boss.items) do
        local key = tostring(itemID)
        local row = {
            expected = expected[itemID] or 0,
            received = t.items[key] or 0,
            dryKills = killsThatCanDrop(batchesOf, streak(key), itemID),
            dryAtLeast = t.items[key] == nil and mayHaveEarlier,
            allTime = allTime and not item.stack and allTime.items[key] or nil,
        }
        row.luck = luckOf(row.expected, row.received)
        row.dryShare = shareOf(itemID, { [itemID] = true })
        result.items[itemID] = row
        result.expected = result.expected + row.expected
        result.received = result.received + row.received
        counted[itemID] = true
    end

    result.luck = luckOf(result.expected, result.received)
    if result.luck == nil then
        -- At the kill counts' rate, so a partial chest's lower rates don't swing it.
        local rate = result.kills > 0 and countedExpected / result.kills
            or result.expected / math.max(1, result.extraKills)
        result.killsToLuck = killsToLuck(result.expected, rate)
    end
    local dry = streak(tallies.ANY)
    result.dryKills = tallies.Total(dry)
    result.dryAtLeast = result.received == 0 and mayHaveEarlier
    result.dryShare = dryShare(batchesOf, dry, counted)
    grouped(boss, result.items, shareOf)
    return result
end

return stats

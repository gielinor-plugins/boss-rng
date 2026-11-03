-- Turns a boss's tracked tallies into the numbers Boss RNG shows, each kill at its
-- day's rates. The game's all-time totals are passed through, never used for luck.

local luck = require("src/core/luck")
local rates = require("src/core/rates")
local tallies = require("src/core/tallies")

local stats = {}

-- Luck shows once an average player would have this many uniques, or from the first
-- unique. Before that a dry streak is normal, so it shows how many would still be dry.
local MIN_EXPECTED = 1

local NO_RATES = {} -- the rate values of a boss without any

-- A boss's rate values on a day, from boss.rates (a test boss's history) or its key's.
local function valuesOn(boss, day)
    local history = boss.rates or rates.For(boss.key)
    return history and history:On(day) or NO_RATES
end

-- A mode's rolls on a day (nil or 0: today); mode.rolls may be a function of (values,
-- readings, means), means being the day's averages of its kills' sums (or nil).
function stats.Rolls(boss, mode, readings, day, means)
    local rolls = mode.rolls or {}
    if type(rolls) == "function" then
        return rolls(valuesOn(boss, day), readings, means)
    end
    return rolls
end

-- Rolls(mode, day) and Chances(mode, day) for readings and t's sums, worked out once per
-- rate version, or per day for a mode with sums that day.
local function ratesTable(boss, readings, t)
    local rolls, chances = {}, {}
    local lookup = {}
    local function cached(store, mode, day, make)
        local means = tallies.Means(t, mode.key, day)
        local key = means and day or valuesOn(boss, day)
        store[mode] = store[mode] or {}
        store[mode][key] = store[mode][key] or make(means)
        return store[mode][key]
    end
    function lookup.Rolls(mode, day)
        return cached(rolls, mode, day, function(means)
            return stats.Rolls(boss, mode, readings, day, means)
        end)
    end
    function lookup.Chances(mode, day)
        return cached(chances, mode, day, function()
            return luck.ItemChances(lookup.Rolls(mode, day))
        end)
    end
    return lookup
end

-- A boss's modes, then each mode its kill events counted (see src/bosses.lua). Saved
-- kills of a mode the boss no longer has are left out.
local function modesOf(boss, t)
    local modes, known = {}, {}
    for _, mode in ipairs(boss.modes) do
        table.insert(modes, mode)
        known[mode.key] = true
    end
    local keys = {}
    for key in pairs(t.kills) do
        if not known[key] then
            table.insert(keys, key)
        end
    end
    table.sort(keys) -- the same order every time
    for _, key in ipairs(keys) do
        local mode = boss.modeFor and boss.modeFor(key)
        if mode then
            table.insert(modes, mode)
        end
    end
    return modes
end

local function eachKill(modes, byMode, fn)
    for _, mode in ipairs(modes) do
        for day, kills in pairs(byMode[mode.key] or {}) do
            fn(mode, tonumber(day), kills)
        end
    end
end

local function killsThatCanDrop(modes, lookup, byMode, itemID)
    local total = 0
    eachKill(modes, byMode, function(mode, day, kills)
        if lookup.Chances(mode, day)[itemID] then
            total = total + kills
        end
    end)
    return total
end

-- Share of players who would have had one of counted (item ids) within byMode's kills.
local function dryShare(modes, lookup, byMode, counted)
    local missAll = 1
    eachKill(modes, byMode, function(mode, day, kills)
        local chance = luck.ChanceOfAny(lookup.Rolls(mode, day), counted)
        missAll = missAll * (1 - luck.DryPercentile(chance, kills))
    end)
    return 1 - missAll
end

-- Nil until expected reaches MIN_EXPECTED or a unique is received.
local function luckOf(expected, received)
    if expected > 0 and (expected >= MIN_EXPECTED or received > 0) then
        return luck.Percentile(expected, received)
    end
    return nil
end

-- Kills until expected reaches MIN_EXPECTED at rate uniques a kill; nil without a rate.
local function killsToLuck(expected, rate)
    if rate <= 0 then
        return nil
    end
    -- Less a hair, so float error doesn't round up a whole kill.
    return math.max(1, math.ceil((MIN_EXPECTED - expected) / rate - 1e-9))
end

-- Uniques sharing a group become one row under its lowest item id: counts add up,
-- and its dry streak is its items' shortest. shareOf(itemID, ids) gives a dry share.
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

-- A stacked unique's log count is items, not drops, so it goes in stacks.
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
--   piles               loot piles over tracked kills, for modes that count them (Kerapac), or nil
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
    local lookup = ratesTable(boss, entry.readings or {}, t)
    local modes = modesOf(boss, t)

    local result =
        { kills = 0, extraKills = 0, extraLabel = boss.extraKills, unit = boss.unit, items = {} }
    local expected = {} -- by item id
    local countedExpected = 0 -- over kills in the kill counts
    eachKill(modes, t.kills, function(mode, day, kills)
        local key = mode.kc and "kills" or "extraKills"
        result[key] = result[key] + kills
        if mode.piles then
            result.piles = (result.piles or 0) + kills * mode.piles
        end
        for itemID, chance in pairs(lookup.Chances(mode, day)) do
            expected[itemID] = (expected[itemID] or 0) + kills * chance
            if mode.kc then
                countedExpected = countedExpected + kills * chance
            end
        end
    end)
    if allTime then
        result.allTime = allTimeTotals(boss, allTime)
    end
    -- Without all-time totals, there may always have been kills before tracking.
    local mayHaveEarlier = allTime == nil or result.allTime.kills > result.kills

    result.expected, result.received = 0, 0
    local counted = {} -- the uniques in the boss's dry streak
    local function shareOf(itemID, ids)
        return dryShare(modes, lookup, tallies.Dry(t, tostring(itemID)), ids)
    end
    for itemID, item in pairs(boss.items) do
        local key = tostring(itemID)
        local row = {
            expected = expected[itemID] or 0,
            received = t.items[key] or 0,
            dryKills = killsThatCanDrop(modes, lookup, tallies.Dry(t, key), itemID),
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
    local dry = tallies.Dry(t, tallies.ANY)
    result.dryKills = tallies.Total(dry)
    result.dryAtLeast = result.received == 0 and mayHaveEarlier
    result.dryShare = dryShare(modes, lookup, dry, counted)
    grouped(boss, result.items, shareOf)
    return result
end

return stats

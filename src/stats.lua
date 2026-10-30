-- Turns a boss's tracked tallies into the numbers Boss RNG shows: expected and
-- received uniques, luck, and dry streaks, each kill at the rates of its day.
-- The game's all-time totals are passed through as facts, never used for luck.
-- Plain Lua, so it can be tested offline.

local luck = require("src/luck")
local rates = require("src/rates")
local tracker = require("src/tracker")

local stats = {}

-- Luck is shown once an average player would have at least this many uniques
-- after the same kills. Before that, any result is a coin flip that reads as
-- precise (one early drop would show as "top 1%").
stats.MIN_EXPECTED = 1

local NO_RATES = {} -- the rate values of a boss without any

-- A boss's rate values on a day (see src/rates.lua): from boss.rates, a test
-- boss's own history, or its key's.
local function valuesOn(boss, day)
    local history = boss.rates or rates.For(boss.key)
    return history and history:On(day) or NO_RATES
end

-- A boss's mode's rolls on a day (nil or 0: today's), for the player's picks:
-- a table, or a function of the boss's rate values that day and the picks.
-- None for a mode counted only through its kill events.
function stats.Rolls(boss, mode, picks, day)
    local rolls = mode.rolls or {}
    if type(rolls) == "function" then
        return rolls(valuesOn(boss, day), picks)
    end
    return rolls
end

-- Rolls and chances per kill by mode and day, for picks, worked out once per
-- mode and rate version: Rolls(mode, day) and Chances(mode, day), { [item id]
-- = chance }.
local function ratesTable(boss, picks)
    local rolls, chances = {}, {}
    local lookup = {}
    -- The cache for a mode on a day: one per rate version.
    local function cache(store, mode, day)
        local version = valuesOn(boss, day)
        store[mode] = store[mode] or {}
        return store[mode], version
    end
    function lookup.Rolls(mode, day)
        local byVersion, version = cache(rolls, mode, day)
        byVersion[version] = byVersion[version] or stats.Rolls(boss, mode, picks, day)
        return byVersion[version]
    end
    function lookup.Chances(mode, day)
        local byVersion, version = cache(chances, mode, day)
        byVersion[version] = byVersion[version] or luck.ItemChances(lookup.Rolls(mode, day))
        return byVersion[version]
    end
    return lookup
end

-- A boss's modes: its own, then one per mode its kill events counted kills
-- for (see killEvents in src/bosses.lua). Saved kills of a mode the boss no
-- longer has are left out.
local function modesOf(boss, tallies)
    local modes, known = {}, {}
    for _, mode in ipairs(boss.modes) do
        table.insert(modes, mode)
        known[mode.name] = true
    end
    local names = {}
    for name in pairs(tallies.kills) do
        if not known[name] then
            table.insert(names, name)
        end
    end
    table.sort(names) -- the same order every time
    for _, name in ipairs(names) do
        local mode = boss.modeFor and boss.modeFor(name)
        if mode then
            table.insert(modes, mode)
        end
    end
    return modes
end

-- Calls fn(mode, day, kills) for each of modes' kills in byMode,
-- { [mode name] = { [day] = kills } }.
local function eachKill(modes, byMode, fn)
    for _, mode in ipairs(modes) do
        for day, kills in pairs(byMode[mode.name] or {}) do
            fn(mode, tonumber(day), kills)
        end
    end
end

-- Kills in byMode of modes that could drop itemID on their day.
local function killsThatCanDrop(modes, rates, byMode, itemID)
    local total = 0
    eachKill(modes, byMode, function(mode, day, kills)
        if rates.Chances(mode, day)[itemID] then
            total = total + kills
        end
    end)
    return total
end

-- Share of players who would have had one of counted (a set of item ids)
-- within the dry kills in byMode: 1 minus the chance of missing on every one,
-- each kill at its own mode's rates on its day.
local function dryShare(modes, rates, byMode, counted)
    local missAll = 1
    eachKill(modes, byMode, function(mode, day, kills)
        local chance = luck.ChanceOfAny(rates.Rolls(mode, day), counted)
        missAll = missAll * (1 - luck.DryPercentile(chance, kills))
    end)
    return 1 - missAll
end

-- Luck for expected and received uniques, or nil until expected is enough.
local function luckOf(expected, received)
    return expected >= stats.MIN_EXPECTED and luck.Percentile(expected, received) or nil
end

-- More kills before an average player would have MIN_EXPECTED uniques, given
-- expected so far and kills at rate (uniques a kill). Nil without a rate yet.
local function killsToLuck(expected, rate)
    if rate <= 0 then
        return nil
    end
    -- Less a hair, so float error (3.0000000004) doesn't round up a whole kill.
    return math.max(1, math.ceil((stats.MIN_EXPECTED - expected) / rate - 1e-9))
end

-- Uniques sharing a group (see src/bosses.lua) become one row, under the group's
-- lowest item id, with the group: counts add up, and the dry streak is the
-- shortest of its items' (a drop of any of them ends it).
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
        local row = { group = group, expected = 0, received = 0, allTime = 0 }
        for _, itemID in ipairs(ids) do
            local item = items[itemID]
            row.expected = row.expected + item.expected
            row.received = row.received + item.received
            row.allTime = item.allTime and row.allTime and row.allTime + item.allTime
            if row.dryKills == nil or item.dryKills < row.dryKills
                or (item.dryKills == row.dryKills and not item.dryAtLeast) then
                row.dryKills, row.dryAtLeast = item.dryKills, item.dryAtLeast
            end
            items[itemID] = nil
        end
        row.luck = luckOf(row.expected, row.received)
        items[ids[1]] = row
    end
end

-- The sum of a table's values.
local function sum(values)
    local total = 0
    for _, n in pairs(values) do
        total = total + n
    end
    return total
end

-- The game's totals for a boss: { kills, received, stacks }. A stacked unique's
-- log count is items, not drops, so it's its own count in stacks, { word, count }.
local function allTimeTotals(boss, allTime)
    local totals = { kills = sum(allTime.kills), received = 0, stacks = {} }
    for key, count in pairs(allTime.items) do
        local item = boss.items[tonumber(key)]
        local stack = item and item.stack
        if stack then
            table.insert(totals.stacks, { word = stack.word, count = count })
        else
            totals.received = totals.received + count
        end
    end
    table.sort(totals.stacks, function(a, b) return a.word < b.word end)
    return totals
end

-- Stats for one boss from its entry, { boss, tallies, picks, allTime }: its
-- tallies (see tracker.Tallies), the player's picks for its choices (see
-- choices.For) and the game's all-time totals (see gamevars.AllTime, nil until
-- they can be read). Nil without tallies.
--   kills        tracked kills in the boss's kill counts
--   extraKills   tracked kills outside them (partial Barrows chests), counted in
--                the rest, called extraLabel ("partial")
--   since        the day of the first tracked kill (see src/days.lua), or nil
--   expected     uniques an average player would have after the tracked kills
--   received     uniques tracked
--   luck         share of players with fewer uniques, from 0 to 1, or nil until
--                expected reaches MIN_EXPECTED
--   killsToLuck  tracked kills until luck shows, while it doesn't
--   dryKills     tracked kills since the last unique
--   dryAtLeast   true if the streak may be longer: no unique tracked yet, and
--                there may be kills from before tracking
--   dryShare     share of players who would have had a unique within dryKills
--   allTime      { kills, received, stacks } from the game, or nil until read
--   unit         what the boss's kills are ("chest"), or nil for kills
--   items        { [itemID] = { expected, received, luck, dryKills, dryAtLeast,
--                allTime } } per unique, or per group of uniques (with its group)
function stats.ForBoss(entry)
    local boss, tallies, allTime = entry.boss, entry.tallies, entry.allTime
    if tallies == nil then
        return nil
    end
    local rates = ratesTable(boss, entry.picks or {})
    local modes = modesOf(boss, tallies)

    local result = { kills = 0, extraKills = 0, extraLabel = boss.extraKills, unit = boss.unit, items = {} }
    local expected = {} -- by item id
    local countedExpected = 0 -- over kills in the kill counts
    eachKill(modes, tallies.kills, function(mode, day, kills)
        local key = mode.kc and "kills" or "extraKills"
        result[key] = result[key] + kills
        if day > 0 and (result.since == nil or day < result.since) then
            result.since = day
        end
        for itemID, chance in pairs(rates.Chances(mode, day)) do
            expected[itemID] = (expected[itemID] or 0) + kills * chance
            if mode.kc and boss.items[itemID].kind == "unique" then
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
    for itemID, item in pairs(boss.items) do
        if item.kind == "unique" then
            local key = tostring(itemID)
            local row = {
                expected = expected[itemID] or 0,
                received = tallies.items[key] or 0,
                dryKills = killsThatCanDrop(modes, rates, tallies.dry[key] or {}, itemID),
                dryAtLeast = tallies.items[key] == nil and mayHaveEarlier,
                allTime = allTime and not item.stack and allTime.items[key] or nil,
            }
            row.luck = luckOf(row.expected, row.received)
            result.items[itemID] = row
            result.expected = result.expected + row.expected
            result.received = result.received + row.received
            counted[itemID] = true
        end
    end

    result.luck = luckOf(result.expected, result.received)
    if result.luck == nil then
        -- At the rate of kills in the kill counts, so a kill outside them (a
        -- partial chest, with lower rates) doesn't swing the estimate.
        local rate = result.kills > 0 and countedExpected / result.kills
            or result.expected / math.max(1, result.extraKills)
        result.killsToLuck = killsToLuck(result.expected, rate)
    end
    local dry = tallies.dry[tracker.ANY] or {}
    result.dryKills = tracker.Total(dry)
    result.dryAtLeast = result.received == 0 and mayHaveEarlier
    result.dryShare = dryShare(modes, rates, dry, counted)
    grouped(boss, result.items)
    return result
end

return stats

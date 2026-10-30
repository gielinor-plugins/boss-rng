-- Keeps each character's boss tallies and saves them on this computer: every
-- kill and drop gamevars reports, by the day it happened, since Boss RNG was
-- installed. Luck comes only from these tracked kills; the game's all-time
-- totals are shown as facts (see gamevars.AllTime).

local safe = require("src/safe")
local saved = require("src/saved")

local tracker = {}

local VERSION = 4 -- of the saved shape; older records start again

-- The key of the dry streak counting every unique; the others are item ids.
tracker.ANY = "any"

local store = saved.ForCharacter("char:", VERSION, function() return { bosses = {} } end)
local record = nil -- the logged in character's, once loaded
local listeners = {}

-- Loads the logged in character's record if needed. Returns false if nobody is
-- logged in.
local function load()
    record = store.Load()
    return record ~= nil
end

local function save()
    store.Save()
    for _, listener in ipairs(listeners) do
        safe.Call("updating after a change", listener)
    end
end

-- Empty tallies. Keys are text, the only kind Jagex's saved data examples use.
--   kills  { [mode name] = { [day] = kills } }
--   dry    { [ANY or item id] = { [mode name] = { [day] = kills } } }: kills
--          since the last unique, or the last drop of that item
--   items  { [item id] = drops }
local function emptyTallies()
    return { kills = {}, dry = {}, items = {} }
end

-- A boss's tallies, created if needed.
local function talliesFor(boss)
    local tallies = record.bosses[boss.key]
    if tallies == nil then
        tallies = emptyTallies()
        record.bosses[boss.key] = tallies
    end
    return tallies
end

-- Adds n kills of a mode on a day to byMode, { [mode name] = { [day] = kills } }.
local function addKills(byMode, modeName, day, n)
    local byDay = byMode[modeName] or {}
    local key = tostring(day)
    byDay[key] = (byDay[key] or 0) + n
    byMode[modeName] = byDay
end

-- The total of { [mode name] = { [day] = kills } }.
function tracker.Total(byMode)
    local total = 0
    for _, byDay in pairs(byMode) do
        for _, n in pairs(byDay) do
            total = total + n
        end
    end
    return total
end

-- The dry streak keys of a boss: ANY, and each unique's id as text.
function tracker.DryKeys(boss)
    local keys = { [tracker.ANY] = true }
    for itemID, item in pairs(boss.items) do
        if item.kind == "unique" then
            keys[tostring(itemID)] = true
        end
    end
    return keys
end

-- count kills of a boss's mode on a day (see src/days.lua). Each kill adds to
-- every dry streak: the boss's, and each of its uniques'.
function tracker.AddKills(boss, mode, count, day)
    if not load() then
        return
    end
    local tallies = talliesFor(boss)
    addKills(tallies.kills, mode.name, day, count)
    for key in pairs(tracker.DryKeys(boss)) do
        tallies.dry[key] = tallies.dry[key] or {}
        addKills(tallies.dry[key], mode.name, day, count)
    end
    record.lastBoss = boss.key
    save()
end

-- count drops of a unique, ending the boss's dry streak and the item's. gamevars
-- reports a tick's kills before its drops, so a drop that lands with a kill ends
-- the streak after that kill. A pooled unique's one log count goes up for every
-- boss that lists it (see src/bosses.lua), so its drop is tracked only for the
-- boss killed last: the one it came from, unless its loot was left until after
-- killing another.
function tracker.AddDrops(boss, itemID, count)
    if not load() then
        return
    end
    if boss.items[itemID].pooledBy == nil or record.lastBoss == boss.key then
        local tallies = talliesFor(boss)
        local key = tostring(itemID)
        tallies.items[key] = (tallies.items[key] or 0) + count
        tallies.dry[key] = {}
        tallies.dry[tracker.ANY] = {}
    end
    save()
end

-- The logged in character's tallies for a boss (empty ones if it has none yet),
-- or nil while nobody is logged in.
function tracker.Tallies(boss)
    if not load() then
        return nil
    end
    return record.bosses[boss.key] or emptyTallies()
end

-- The key of the boss the logged in character killed most recently, or nil.
function tracker.LastBossKey()
    if not load() then
        return nil
    end
    return record.lastBoss
end

-- Calls listener() after every change.
function tracker.OnChange(listener)
    table.insert(listeners, listener)
end

return tracker

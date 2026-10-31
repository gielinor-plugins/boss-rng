-- Keeps each character's boss tallies and saves them on this computer: every
-- kill and drop gamevars reports, by the day it happened, since Boss RNG was
-- installed. Luck comes only from these tracked kills; the game's all-time
-- totals are shown as facts (see gamevars.AllTime).

local safe = require("src/safe")
local saved = require("src/saved")
local tallies = require("src/tallies")

local tracker = {}

local VERSION = 5 -- of the saved shape (see src/tallies.lua); version 4 is converted, older starts again

-- The key of the dry streak counting every unique; the others are item ids.
tracker.ANY = "any"

-- Each record as saved: every boss's tallies encoded (see tallies.Encode).
local codec = {}
local encoded = {} -- each boss's encoded tallies, kept until they change (see talliesFor)

-- Applies convert(tallies, boss key) to each boss's tallies in a record,
-- returning a new record.
local function eachBoss(from, convert, version)
    local to = { version = version, lastBoss = from.lastBoss, bosses = {} }
    for key, t in pairs(from.bosses or {}) do
        to.bosses[key] = convert(t, key)
    end
    return to
end

function codec.Encode(from)
    return eachBoss(from, function(t, key)
        encoded[key] = encoded[key] or tallies.Encode(t)
        return encoded[key]
    end, from.version)
end

function codec.Decode(saved)
    if saved.version == VERSION then
        return eachBoss(saved, tallies.Decode, VERSION)
    elseif saved.version == 4 then
        return eachBoss(saved, tallies.FromVersion4, VERSION)
    end
    return nil
end

local store = saved.ForCharacter("char:", VERSION, function() return { bosses = {} } end, codec)
local record = nil -- the logged in character's, once loaded
local listeners = {}
local changes = 0 -- counts every change to the tallies, and every character switch

-- Loads the logged in character's record if needed. Returns false if nobody is
-- logged in.
local function load()
    local loaded = store.Load()
    if loaded ~= record then
        record, encoded = loaded, {}
        changes = changes + 1
    end
    return record ~= nil
end

local function save()
    changes = changes + 1
    store.Save()
    for _, listener in ipairs(listeners) do
        safe.Call("updating after a change", listener)
    end
end

-- A boss's tallies, created if needed, to change: its saved form is encoded
-- again at the next save.
local function talliesFor(boss)
    encoded[boss.key] = nil
    local t = record.bosses[boss.key]
    if t == nil then
        t = tallies.Empty()
        record.bosses[boss.key] = t
    end
    return t
end

-- The total of { [mode name] = { [day] = kills } }.
tracker.Total = tallies.Total

-- A dry streak's kills, { [mode name] = { [day] = kills } }: key is ANY or an
-- item id as text (see src/tallies.lua).
tracker.Dry = tallies.Dry

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
-- every dry streak (the boss's, and each of its uniques'): they're read as the
-- kills since their start, so only streaks kept as counted need adding to.
function tracker.AddKills(boss, mode, count, day)
    if not load() then
        return
    end
    local t = talliesFor(boss)
    for key in pairs(tracker.DryKeys(boss)) do
        local start = t.dryFrom[key]
        if start and start.dry then
            tallies.AddKills(start.dry, mode.name, day, count)
        end
    end
    tallies.AddKills(t.kills, mode.name, day, count)
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
        local t = talliesFor(boss)
        local key = tostring(itemID)
        t.items[key] = (t.items[key] or 0) + count
        t.dryFrom[key] = tallies.StartNow(t.kills)
        t.dryFrom[tracker.ANY] = tallies.StartNow(t.kills)
    end
    save()
end

-- The logged in character's tallies for a boss (empty ones if it has none yet),
-- or nil while nobody is logged in.
function tracker.Tallies(boss)
    if not load() then
        return nil
    end
    return record.bosses[boss.key] or tallies.Empty()
end

-- The key of the boss the logged in character killed most recently, or nil.
function tracker.LastBossKey()
    if not load() then
        return nil
    end
    return record.lastBoss
end

-- A number that changes whenever any tallies the tracker gives out might have,
-- so something worked out from them can tell when to work it out again.
function tracker.Changes()
    load()
    return changes
end

-- Calls listener() after every change.
function tracker.OnChange(listener)
    table.insert(listeners, listener)
end

return tracker

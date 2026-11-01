-- Keeps each character's boss tallies, saved on this computer only: every kill and
-- drop gamevars reports, by day, since Boss RNG was installed. Luck comes only from
-- these; the game's all-time totals are shown as facts.

local safe = require("src/utils/safe")
local saved = require("src/utils/saved")
local tallies = require("src/core/tallies")

local tracker = {}

local VERSION = 5 -- of the saved shape (see src/core/tallies.lua); version 4 is converted, older starts again

-- The key of the dry streak counting every unique; the others are item ids.
tracker.ANY = "any"

local codec = {}
local encoded = {} -- each boss's encoded tallies, kept until they change (see talliesFor)

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

-- Loads the logged in character's record if needed; false if nobody is logged in.
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

-- A boss's tallies to change, created if needed; re-encoded at the next save.
local function talliesFor(boss)
    encoded[boss.key] = nil
    local t = record.bosses[boss.key]
    if t == nil then
        t = tallies.Empty()
        record.bosses[boss.key] = t
    end
    return t
end

tracker.Total = tallies.Total

-- A dry streak's kills; key is ANY or an item id as text.
tracker.Dry = tallies.Dry

function tracker.DryKeys(boss)
    local keys = { [tracker.ANY] = true }
    for itemID, item in pairs(boss.items) do
        if item.kind == "unique" then
            keys[tostring(itemID)] = true
        end
    end
    return keys
end

-- Adds kills. Streaks are read as the kills since their start, so only those kept
-- as counted need adding to.
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

-- Ends the boss's and the item's dry streaks. gamevars reports a tick's kills first,
-- so a drop ends the streak after the kill it landed with. A pooled unique's log
-- count rises for every boss listing it, so it's tracked only for the boss killed
-- last: the one it came from, unless its loot was left until after another kill.
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

-- The character's tallies for a boss (empty if none yet), or nil if nobody's logged in.
function tracker.Tallies(boss)
    if not load() then
        return nil
    end
    return record.bosses[boss.key] or tallies.Empty()
end

function tracker.LastBossKey()
    if not load() then
        return nil
    end
    return record.lastBoss
end

-- Changes whenever any tallies given out might have.
function tracker.Changes()
    load()
    return changes
end

function tracker.OnChange(listener)
    table.insert(listeners, listener)
end

return tracker

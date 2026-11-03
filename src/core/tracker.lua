-- Keeps each character's boss tallies, saved on this computer only: every kill and
-- drop gamevars reports, by day, since Boss RNG was installed. Luck comes only from
-- these; the game's all-time totals are shown as facts.

local safe = require("src/utils/safe")
local saved = require("src/utils/saved")
local tallies = require("src/core/tallies")

local tracker = {}

-- The saved shape's version (see src/core/tallies.lua): any other version starts again.
-- TODO: set to 1 before release.
local VERSION = 6

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
    end
    return nil
end

local store = saved.ForCharacter("char:", VERSION, function()
    return { bosses = {} }
end, codec)
local record = nil -- the logged in character's, once loaded
local listeners = {}
local switches = 0 -- counts character switches and resets of every boss
local changes = {} -- [boss key] = changes to its tallies

-- Loads the logged in character's record if needed; false if nobody is logged in.
local function load()
    local loaded = store.Load()
    if loaded ~= record then
        record, encoded = loaded, {}
        switches = switches + 1
    end
    return record ~= nil
end

local function save()
    store.Save()
    for _, listener in ipairs(listeners) do
        safe.Call("updating after a change", listener)
    end
end

local function changed(boss)
    encoded[boss.key] = nil
    changes[boss.key] = (changes[boss.key] or 0) + 1
end

-- A boss's tallies to change, created if needed; re-encoded at the next save.
local function talliesFor(boss)
    changed(boss)
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

-- Adds kills. Dry streaks are read as the kills since their start, so they need no change.
function tracker.AddKills(boss, mode, count, day)
    if not load() then
        return
    end
    tallies.AddKills(talliesFor(boss).kills, mode.key, day, count)
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

-- Clears the character's tallies for a boss.
function tracker.Reset(boss)
    if not load() then
        return
    end
    record.bosses[boss.key] = nil
    changed(boss)
    if record.lastBoss == boss.key then
        record.lastBoss = nil
    end
    save()
end

-- Clears the character's tallies for every boss.
function tracker.ResetAll()
    if not load() then
        return
    end
    record.bosses, record.lastBoss, encoded = {}, nil, {}
    switches = switches + 1
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

-- Changes whenever the boss's tallies given out might have.
function tracker.Changes(boss)
    load()
    return switches .. ":" .. (changes[boss.key] or 0)
end

function tracker.OnChange(listener)
    table.insert(listeners, listener)
end

return tracker

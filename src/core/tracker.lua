-- Keeps each character's tallies for every boss, saved on this computer only: every kill
-- and drop game_vars reports, by day, since Boss RNG was installed. Luck comes only from
-- these; the game's all-time totals are shown as facts.

local safe = require("src/utils/safe")
local tallies = require("src/core/tallies")

local tracker = {}

-- Saved under PREFIX and the character's display name, since every character on the
-- computer shares the plugin's saved data. A name change starts a new entry.
local PREFIX = "char:"

-- The saved shape's version (see src/core/tallies.lua): any other version starts again.
local VERSION = 1

local encoded = {} -- each boss's encoded tallies, kept until they change (see talliesFor)

local function eachBoss(from, convert)
    local to = { version = VERSION, lastBoss = from.lastBoss, bosses = {} }
    for key, t in pairs(from.bosses or {}) do
        to.bosses[key] = convert(t, key)
    end
    return to
end

-- The record as saved. A boss's encoded tallies are reused until talliesFor clears
-- them, and share dryFrom and items with its tallies (only kills and sums are
-- converted), so tallies change only through talliesFor.
local function encode(record)
    return eachBoss(record, function(t, key)
        encoded[key] = encoded[key] or tallies.Encode(t)
        return encoded[key]
    end)
end

-- The saved record as tallies, or a fresh one if there's none or it's another version.
local function decode(stored)
    if stored == nil or stored.version ~= VERSION then
        return { version = VERSION, bosses = {} }
    end
    return eachBoss(stored, tallies.Decode)
end

local function characterName()
    if not Player.IsAvailable() then
        return nil
    end
    local entity = Player.GetEntity()
    if entity == nil or entity.displayName == "" then
        return nil
    end
    return entity.displayName
end

local name, record = nil, nil -- the logged in character's, once loaded
local listeners = {}
local switches = 0 -- counts character switches and resets of every boss
local changes = {} -- [boss key] = changes to its tallies

-- Loads the logged in character's record if needed; false if nobody is logged in.
local function load()
    local current = characterName()
    if current == nil then
        return false
    end
    if current ~= name then
        name = current
        record, encoded = decode(PersistentDB:GetStructuredData(PREFIX .. name)), {}
        switches = switches + 1
    end
    return true
end

local function save()
    if not PersistentDB:SetStructuredData(PREFIX .. name, encode(record)) then
        print("[Boss RNG] Could not save data for " .. name)
    end
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

-- Adds kills, and their sums (or nil). Dry streaks are worked out as the kills since
-- their start, so adding kills doesn't touch them.
function tracker.AddKills(boss, mode, count, day, sums)
    if not load() then
        return
    end
    tallies.AddKills(talliesFor(boss), mode.key, day, count, sums)
    record.lastBoss = boss.key
    save()
end

-- Adds drops, ending the boss's and the item's dry streaks. game_vars reports a tick's
-- kills first, so a drop ends the streak after the kill it came with. A shared
-- unique's collection log count rises for every boss that lists it, so the drop is
-- tracked only for the boss killed last: the one it came from, unless its loot was
-- left until after another kill.
function tracker.AddDrops(boss, itemID, count)
    if not load() then
        return
    end
    if boss.items[itemID].pooledBy ~= nil and record.lastBoss ~= boss.key then
        return
    end
    local t = talliesFor(boss)
    local key = tostring(itemID)
    t.items[key] = (t.items[key] or 0) + count
    t.dryFrom[key] = tallies.StartNow(t.kills)
    t.dryFrom[tallies.ANY] = tallies.StartNow(t.kills)
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

-- A value that changes whenever the boss's tallies might have, so a caller knows to
-- work its stats out again.
function tracker.Changes(boss)
    load()
    return switches .. ":" .. (changes[boss.key] or 0)
end

function tracker.OnChange(listener)
    table.insert(listeners, listener)
end

return tracker

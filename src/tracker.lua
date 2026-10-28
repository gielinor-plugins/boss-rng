-- Keeps each character's boss tallies and saves them on this computer: what the
-- game doesn't keep, from each kill and drop gamevars reports since Boss RNG was
-- installed. All-time totals are the game's own (see gamevars.AllTime).

local safe = require("src/safe")
local saved = require("src/saved")

local tracker = {}

local VERSION = 3 -- of the saved shape; older records start again

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

-- A boss's tallies, created if needed. Keys are text, the only kind Jagex's saved
-- data examples use.
--   kills    { [mode name] = kills since install }
--   dry      { [mode name] = kills since the last unique }, so the dry streak
--            can use each mode's own rates
--   items    { [item id] = { count = drops since install,
--                            atKills = kills per mode at the last one } }
local function talliesFor(boss)
    local tallies = record.bosses[boss.key]
    if tallies == nil then
        tallies = { kills = {}, dry = {}, items = {} }
        record.bosses[boss.key] = tallies
    end
    return tallies
end

-- Adds n to counts[key].
local function add(counts, key, n)
    counts[key] = (counts[key] or 0) + n
end

local function copy(counts)
    local result = {}
    for key, n in pairs(counts) do
        result[key] = n
    end
    return result
end

-- The sum of a count table, such as a boss's kills per mode.
function tracker.Total(counts)
    local total = 0
    for _, n in pairs(counts) do
        total = total + n
    end
    return total
end

-- count kills of a boss's mode.
function tracker.AddKills(boss, mode, count)
    if not load() then
        return
    end
    local tallies = talliesFor(boss)
    add(tallies.kills, mode.name, count)
    add(tallies.dry, mode.name, count)
    record.lastBoss = boss.key
    save()
end

-- atKills are the boss's kills per mode when the drop's log count goes up.
-- gamevars reports a tick's kills before its drops, so a drop that lands with a
-- kill includes that kill. A pooled unique's one log count goes up for every boss
-- that lists it (see src/bosses.lua), so its drop is tracked only for the boss
-- killed last: the one it came from, unless its loot was left until after
-- killing another.
function tracker.AddDrops(boss, itemID, count)
    if not load() then
        return
    end
    local tallies = talliesFor(boss)
    local key = tostring(itemID)
    if boss.items[itemID].pooledBy == nil or record.lastBoss == boss.key then
        local item = tallies.items[key] or { count = 0 }
        item.count = item.count + count
        item.atKills = copy(tallies.kills)
        tallies.items[key] = item
        tallies.dry = {}
    end
    save()
end

-- The logged in character's tallies for a boss (empty ones if it has none yet),
-- or nil while nobody is logged in.
function tracker.Tallies(boss)
    if not load() then
        return nil
    end
    return record.bosses[boss.key] or { kills = {}, dry = {}, items = {} }
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

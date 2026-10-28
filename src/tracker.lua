-- Keeps each character's boss tallies and saves them on this computer.
-- Tallies start when Boss RNG is installed: gamevars reports each kill and drop.
-- All-time totals come from capture, whenever the game shows them.

local safe = require("src/safe")
local saved = require("src/saved")

local tracker = {}

local REF = "bossrng_tracker"
local VERSION = 3 -- of the saved shape; older records start again

local store = saved.ForCharacter("char:", VERSION, function() return { bosses = {} } end)
local record = nil -- the logged in character's, once loaded
local sessionName = nil -- the character seenThisSession is for
local listeners = {}
-- The all-time kinds ("kills", "items") seen this session, by boss key. Tracking
-- keeps those up to date, so they're known to match each other.
local seenThisSession = {}

-- Loads the logged in character's record if needed. Returns false if nobody is
-- logged in.
local function load()
    local name
    record, name = store.Load()
    if record == nil then
        return false
    end
    if name ~= sessionName then
        sessionName = name
        seenThisSession = {}
    end
    return true
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
--   allTime  the game's own totals, each captured when shown (see tracker.AllTime):
--            { kills = { [kill count var] = n }, items = { [item id] = n } }
local function talliesFor(boss)
    local tallies = record.bosses[boss.key]
    if tallies == nil then
        tallies = { kills = {}, dry = {}, items = {}, allTime = { kills = {}, items = {} } }
        record.bosses[boss.key] = tallies
    end
    return tallies
end

-- Adds n to counts[key].
local function add(counts, key, n)
    counts[key] = (counts[key] or 0) + n
end

-- Adds n to an all-time count, if it's known.
local function addAllTime(counts, key, n)
    if counts[key] then
        counts[key] = counts[key] + n
    end
end

local function copy(counts)
    local result = {}
    for key, n in pairs(counts) do
        result[key] = n
    end
    return result
end

-- Records all-time counts the game just showed: kind is "kills" or "items", and
-- counts may cover only some of them (one Beasts tab page of several). A count
-- that changed since it was last seen means something happened while Boss RNG
-- wasn't watching, so every count not seen this session may be out of date too.
-- Those are dropped until seen again, since comparing kills and uniques from
-- different times would skew luck.
local function setAllTime(boss, kind, counts)
    if not load() then
        return
    end
    local tallies = talliesFor(boss)
    local seen = seenThisSession[boss.key] or { kills = {}, items = {} }
    seenThisSession[boss.key] = seen
    local changed = false
    for key, n in pairs(counts) do
        seen[kind][key] = true
        changed = changed or tallies.allTime[kind][key] ~= n
        tallies.allTime[kind][key] = n
    end
    if not changed then
        return
    end
    for _, otherKind in ipairs({ "kills", "items" }) do
        local stored = tallies.allTime[otherKind]
        for key in pairs(stored) do
            if not seen[otherKind][key] then
                stored[key] = nil
            end
        end
    end
    save()
end

-- Kill counts from a Beasts tab page: { [kill count var] = kills }.
function tracker.SetAllTimeKills(boss, kills)
    setAllTime(boss, "kills", kills)
end

-- Boss log counts of a boss's uniques: { [item id] = count }.
function tracker.SetAllTimeItems(boss, counts)
    local byKey = {}
    for itemID, count in pairs(counts) do
        byKey[tostring(itemID)] = count
    end
    setAllTime(boss, "items", byKey)
end

-- A boss's all-time totals, { kills, items } as in its tallies, once every kill
-- count and every unique's log count is known; else nil.
function tracker.AllTime(boss, tallies)
    local allTime = tallies.allTime
    for _, mode in ipairs(boss.modes) do
        if allTime.kills[mode.kc] == nil then
            return nil
        end
    end
    for itemID, item in pairs(boss.items) do
        if item.kind == "unique" and allTime.items[tostring(itemID)] == nil then
            return nil
        end
    end
    return allTime
end

-- The sum of a count table, such as a boss's kills per mode.
function tracker.Total(counts)
    local total = 0
    for _, n in pairs(counts) do
        total = total + n
    end
    return total
end

-- Tracked kills also add to the all-time kill counts, once they're captured.
function tracker.AddKills(boss, mode, count)
    if not load() then
        return
    end
    local tallies = talliesFor(boss)
    add(tallies.kills, mode.name, count)
    add(tallies.dry, mode.name, count)
    addAllTime(tallies.allTime.kills, mode.kc, count)
    record.lastBoss = boss.key
    save()
end

-- atKills are the boss's kills per mode when the drop's log count goes up.
-- gamevars reports a tick's kills before its drops, so a drop that lands with a
-- kill includes that kill. Drops also add to the all-time log counts, once
-- captured. A pooled unique's one log count goes up for every boss that lists it
-- (see src/bosses.lua), so its drop is tracked only for the boss killed last: the
-- one it came from, unless its loot was left until after killing another.
function tracker.AddDrops(boss, itemID, count)
    if not load() then
        return
    end
    local tallies = talliesFor(boss)
    local key = tostring(itemID)
    addAllTime(tallies.allTime.items, key, count)
    if boss.items[itemID].pooledBy == nil or record.lastBoss == boss.key then
        local item = tallies.items[key] or { count = 0 }
        item.count = item.count + count
        item.atKills = copy(tallies.kills)
        tallies.items[key] = item
        tallies.dry = {}
    end
    save()
end

-- The logged in character's tallies for a boss, or nil if there are none yet.
function tracker.Tallies(boss)
    if not load() then
        return nil
    end
    return record.bosses[boss.key]
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

-- Leaving the game ends the session: while logged out, the character may play
-- elsewhere, so all-time totals must be seen again to be known up to date.
local function onGameStateChanged(event)
    if event.newState ~= GameState.GAME then
        seenThisSession = {}
    end
end

function tracker.Start()
    Event.GameStateChanged.Subscribe(REF, onGameStateChanged)
end

function tracker.Stop()
    Event.GameStateChanged.Unsubscribe(REF)
end

return tracker

-- Keeps each character's boss tallies and saves them on this computer.
-- Tallies start when Boss RNG is installed: gamevars reports each kill and drop.
-- All-time totals come from capture, whenever the game shows them.

local safe = require("src/safe")

local tracker = {}

local REF = "bossrng_tracker"
local VERSION = 2
-- Saved data is shared by every character on this computer, so each character
-- gets its own entry. A display name change starts a new entry.
local PREFIX = "char:"

local loadedName = nil -- character whose record is loaded
local record = nil
local listeners = {}
-- The all-time kinds ("kills", "items") seen this session, by boss key. Tracking
-- keeps those up to date, so they're known to match each other.
local seenThisSession = {}

-- The logged in character's display name, or nil.
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

-- Loads the logged in character's record if needed. Returns false if nobody is
-- logged in.
local function load()
    local name = characterName()
    if name == nil then
        return false
    end
    if name ~= loadedName then
        loadedName = name
        seenThisSession = {}
        record = PersistentDB:GetStructuredData(PREFIX .. name)
        if record == nil or record.version ~= VERSION then
            record = { version = VERSION, bosses = {} }
        end
    end
    return true
end

local function save()
    if not PersistentDB:SetStructuredData(PREFIX .. loadedName, record) then
        print("[Boss RNG] Could not save data for " .. loadedName)
    end
    for _, listener in ipairs(listeners) do
        safe.Call("updating after a change", listener)
    end
end

-- A boss's tallies, created if needed. Keys are text, the only kind Jagex's saved
-- data examples use.
--   kills    { [mode name] = kills since install }
--   dry      { [mode name] = kills since the last unique }, so the dry streak can
--            use each mode's own rates
--   items    { [item id] = { count = drops since install, atKill = boss kills at the last one } }
--   allTime  the game's own totals, each captured when shown (see tracker.AllTime):
--            { kills = { [mode name] = n }, items = { [item id] = n } }
local function talliesFor(boss)
    local tallies = record.bosses[boss.key]
    if tallies == nil then
        tallies = { kills = {}, dry = {}, items = {}, allTime = {} }
        record.bosses[boss.key] = tallies
    end
    tallies.allTime = tallies.allTime or {} -- missing in data saved before all-time totals
    return tallies
end

-- Adds n to counts[key].
local function add(counts, key, n)
    counts[key] = (counts[key] or 0) + n
end

-- True if two count tables (or nils) hold the same numbers.
local function sameCounts(a, b)
    if a == nil or b == nil then
        return a == b
    end
    for key, n in pairs(a) do
        if b[key] ~= n then
            return false
        end
    end
    for key in pairs(b) do
        if a[key] == nil then
            return false
        end
    end
    return true
end

-- Records all-time counts of one kind ("kills" or "items") the game just showed.
-- Counts that changed since last seen mean something happened while Boss RNG
-- wasn't watching, so the other kind is out of date too, unless it's been seen
-- this session. It's dropped until seen again, since comparing kills and uniques
-- from different times would skew luck.
local function setAllTime(boss, kind, counts)
    if not load() then
        return
    end
    local tallies = talliesFor(boss)
    local seen = seenThisSession[boss.key] or {}
    seenThisSession[boss.key] = seen
    seen[kind] = true
    if sameCounts(tallies.allTime[kind], counts) then
        return
    end
    tallies.allTime[kind] = counts
    local other = kind == "kills" and "items" or "kills"
    if not seen[other] then
        tallies.allTime[other] = nil
    end
    save()
end

-- Kill counts from the Beasts tab: { [mode name] = kills }.
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

-- A boss's all-time totals, { kills, items }, once both are known; else nil.
function tracker.AllTime(tallies)
    local allTime = tallies.allTime
    if allTime and allTime.kills and allTime.items then
        return allTime
    end
    return nil
end

-- Total kills since install across a boss's modes.
function tracker.Kills(tallies)
    local total = 0
    for _, kills in pairs(tallies.kills) do
        total = total + kills
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
    if tallies.allTime.kills then
        add(tallies.allTime.kills, mode.name, count)
    end
    record.lastBoss = boss.key
    save()
end

-- atKill is the boss's kill count when the drop's log count goes up. gamevars
-- reports a tick's kills before its drops, so a drop that lands with a kill
-- includes that kill. Drops also add to the all-time log counts, once captured.
function tracker.AddDrops(boss, itemID, count)
    if not load() then
        return
    end
    local tallies = talliesFor(boss)
    local key = tostring(itemID)
    local item = tallies.items[key] or { count = 0 }
    item.count = item.count + count
    item.atKill = tracker.Kills(tallies)
    tallies.items[key] = item
    tallies.dry = {}
    if tallies.allTime.items then
        add(tallies.allTime.items, key, count)
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

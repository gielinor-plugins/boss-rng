-- Keeps each character's boss tallies and saves them on this computer.
-- Tallies start when Boss RNG is installed: gamevars reports each kill and drop.

local safe = require("src/safe")

local tracker = {}

local VERSION = 2
-- Saved data is shared by every character on this computer, so each character
-- gets its own entry. A display name change starts a new entry.
local PREFIX = "char:"

local loadedName = nil -- character whose record is loaded
local record = nil
local listeners = {}

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
--   kills  { [mode name] = kills since install }
--   dry    { [mode name] = kills since the last unique }, so the dry streak can use
--          each mode's own rates
--   items  { [item id] = { count = drops since install, atKill = boss kills at the last one } }
local function talliesFor(boss)
    local tallies = record.bosses[boss.key]
    if tallies == nil then
        tallies = { kills = {}, dry = {}, items = {} }
        record.bosses[boss.key] = tallies
    end
    return tallies
end

-- Total kills since install across a boss's modes.
function tracker.Kills(tallies)
    local total = 0
    for _, kills in pairs(tallies.kills) do
        total = total + kills
    end
    return total
end

function tracker.AddKills(boss, mode, count)
    if not load() then
        return
    end
    local tallies = talliesFor(boss)
    tallies.kills[mode.name] = (tallies.kills[mode.name] or 0) + count
    tallies.dry[mode.name] = (tallies.dry[mode.name] or 0) + count
    record.lastBoss = boss.key
    save()
end

-- atKill is the boss's kill count when the drop's log count goes up. gamevars
-- reports a tick's kills before its drops, so a drop that lands with a kill
-- includes that kill.
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

return tracker

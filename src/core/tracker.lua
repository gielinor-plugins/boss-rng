-- Keeps each character's tallies for every boss, saved on this computer only: every kill
-- and drop game_vars reports, by day, since Boss RNG was installed. Luck comes only from
-- these; the game's all-time totals are shown as facts.

local safe = require("src/utils/safe")
local tallies = require("src/core/tallies")

local tracker = {}

-- Every character on the computer shares the plugin's saved data, so each entry's key
-- starts with PREFIX and the character's display name: "char:<name>" holds the boss
-- killed last, and "char:<name>:<boss key>" each boss's tallies. One entry per boss
-- keeps each entry small: the game failed to save an entry of 128 KB in testing (see
-- docs/data/saved-data.md). A name change starts anew.
local PREFIX = "char:"

-- Every entry's version (see src/core/tallies.lua). An entry of any other version reads
-- as empty and is replaced at its next save, so raising this needs a converter first
-- (see "Not built yet" in docs/data/compatibility.md).
local VERSION = 1

local name = nil -- the logged in character's, once loaded
local lastBoss = nil -- the key of the boss the character killed last
local bossTallies = {} -- [boss key] = tallies, or false if none; read when first needed
local listeners = {}
local switches = 0 -- counts character switches and resets of every boss
local changes = {} -- [boss key] = changes to its tallies

local function characterEntry()
    return PREFIX .. name
end

-- The start of the character's boss entries' keys.
local function bossPrefix()
    return characterEntry() .. ":"
end

local function bossEntry(boss)
    return bossPrefix() .. boss.key
end

-- An entry as saved, or nil if there's none or it's another version.
local function read(key)
    local saved = PersistentDB:GetStructuredData(key)
    if saved == nil or saved.version ~= VERSION then
        return nil
    end
    return saved
end

local function write(key, entry)
    entry.version = VERSION
    if not PersistentDB:SetStructuredData(key, entry) then
        print("[Boss RNG] Could not save data for " .. name)
    end
end

local function delete(key)
    if not PersistentDB:Delete(key) then
        print("[Boss RNG] Could not delete data for " .. name)
    end
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

-- Loads the logged in character's entry if needed; false if nobody is logged in. Bosses'
-- entries are read when first needed (see stored).
local function load()
    local current = characterName()
    if current == nil then
        return false
    end
    if current ~= name then
        name = current
        local saved = read(characterEntry())
        lastBoss = saved and saved.lastBoss
        bossTallies = {}
        switches = switches + 1
    end
    return true
end

-- The boss's tallies, read from its entry the first time; nil if it has none.
local function stored(boss)
    if bossTallies[boss.key] == nil then
        local saved = read(bossEntry(boss))
        bossTallies[boss.key] = saved and tallies.Decode(saved) or false
    end
    return bossTallies[boss.key] or nil
end

local function saveBoss(boss)
    write(bossEntry(boss), tallies.Encode(bossTallies[boss.key]))
end

local function saveCharacter()
    write(characterEntry(), { lastBoss = lastBoss })
end

local function notify()
    for _, listener in ipairs(listeners) do
        safe.Call("updating after a change", listener)
    end
end

local function changed(boss)
    changes[boss.key] = (changes[boss.key] or 0) + 1
end

-- A boss's tallies to change, created if needed.
local function talliesFor(boss)
    changed(boss)
    local t = stored(boss)
    if t == nil then
        t = tallies.Empty()
        bossTallies[boss.key] = t
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
    saveBoss(boss)
    if lastBoss ~= boss.key then
        lastBoss = boss.key
        saveCharacter()
    end
    notify()
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
    if boss.items[itemID].pooledBy ~= nil and lastBoss ~= boss.key then
        return
    end
    local t = talliesFor(boss)
    local key = tostring(itemID)
    t.items[key] = (t.items[key] or 0) + count
    t.dryFrom[key] = tallies.StartNow(t.kills)
    t.dryFrom[tallies.ANY] = tallies.StartNow(t.kills)
    saveBoss(boss)
    notify()
end

-- Clears the character's tallies for a boss.
function tracker.Reset(boss)
    if not load() then
        return
    end
    if stored(boss) then
        delete(bossEntry(boss))
    end
    bossTallies[boss.key] = false
    changed(boss)
    if lastBoss == boss.key then
        lastBoss = nil
        saveCharacter()
    end
    notify()
end

-- Clears the character's tallies for every boss, including any whose entry the plugin no
-- longer reads.
function tracker.ResetAll()
    if not load() then
        return
    end
    local prefix, keys = bossPrefix(), {}
    PersistentDB:IterateEntries(function(key)
        if key:sub(1, #prefix) == prefix then
            table.insert(keys, key)
        end
        return false -- keep going
    end)
    for _, key in ipairs(keys) do
        delete(key)
    end
    bossTallies, lastBoss = {}, nil
    saveCharacter()
    switches = switches + 1
    notify()
end

-- The character's tallies for a boss (empty if none yet), or nil if nobody's logged in.
function tracker.Tallies(boss)
    if not load() then
        return nil
    end
    return stored(boss) or tallies.Empty()
end

function tracker.LastBossKey()
    if not load() then
        return nil
    end
    return lastBoss
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

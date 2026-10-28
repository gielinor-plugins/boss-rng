-- Reads boss kill counts and boss log counts from the game: their all-time
-- totals, and each kill and drop as the count goes up. It stores nothing, and
-- it's the only module that reads game vars. These counts aren't hidden (the
-- Beasts tab and boss log show them, and Jagex confirmed they may be read without
-- either open); hidden values such as bad luck mitigation are never read.
--
-- Kill counts and log counts are varbits: slices of a bigger "base" var. At a kill
-- or drop the game sends the base var's old and new value (VarTransmit), and the
-- change in each slice is a kill or drop. Bosses whose chest hides which unique
-- dropped until it's opened would break this, so they aren't supported yet.

local choices = require("src/choices")
local safe = require("src/safe")

local gamevars = {}

local REF = "bossrng_gamevars"

-- After entering the game, wait this long before trusting vars, so the ones sent
-- at login aren't mistaken for kills or drops, or read before they've arrived.
-- The client runs 50 ticks per second.
local SETTLE_TICKS = 5 * 50

-- Each KC varbit rises by 1 per kill, and an item's count by a little per drop.
-- Bigger jumps (like a login sync) and any decrease are ignored.
local MAX_CHANGE = 3

local watched = {} -- [base var id] = slices to check when that var changes
local pending = { kills = {}, drops = {} } -- changes waiting for the next tick
local tick = 0
local readyAtTick = nil -- nil while not in the game
local onReady = nil -- called once vars can be trusted after entering the game
local announced = false -- whether onReady was called since entering the game

-- True once vars can be trusted: in the game, and settled after entering it.
local function isReady()
    return readyAtTick ~= nil and tick >= readyAtTick
end

-- Number of zero bits below a mask's lowest set bit, e.g. 0xFFFF0000 gives 16.
local function lowestBit(mask)
    local shift = 0
    while mask ~= 0 and mask & 1 == 0 do
        mask = mask >> 1
        shift = shift + 1
    end
    return shift
end

-- Watches a varbit by name. report(change) is called whenever it goes up.
-- group is "kills" or "drops".
local function watch(name, group, report)
    local varbit = var.VarPlayer[name]
    if varbit == nil or not varbit.isVarBit then
        print("[Boss RNG] Unknown varbit " .. name)
        return
    end
    local baseID = varbit.baseVar.id
    watched[baseID] = watched[baseID] or {}
    table.insert(watched[baseID], {
        mask = varbit.varBitMask,
        shift = lowestBit(varbit.varBitMask),
        group = group,
        report = report,
    })
end

local function onVarTransmit(event)
    local slices = watched[event.var.id]
    local old, new = event.oldValue, event.newValue
    if slices == nil or not isReady() then
        return
    end
    if type(old) ~= "number" or type(new) ~= "number" then
        return
    end
    for _, slice in ipairs(slices) do
        local change = ((new & slice.mask) >> slice.shift) - ((old & slice.mask) >> slice.shift)
        if change > 0 and change <= MAX_CHANGE then
            table.insert(pending[slice.group], { report = slice.report, change = change })
        end
    end
end

local function onGameStateChanged(event)
    readyAtTick = event.newState == GameState.GAME and tick + SETTLE_TICKS or nil
    announced = false
end

-- When a kill and a drop change in the same tick they can arrive in either order
-- (at Kree'arra the drop came first). Reporting a tick's changes together, kills
-- first, means a drop is always counted after the kill it landed with.
local function flush()
    for _, group in ipairs({ "kills", "drops" }) do
        for _, item in ipairs(pending[group]) do
            safe.Call("recording " .. group, item.report, item.change)
        end
        pending[group] = {}
    end
end

local function onLogic(event)
    tick = event.logicTick
    flush()
    if isReady() and not announced then
        announced = true
        safe.Call("updating once the game is ready", onReady)
    end
end

-- True if a kill counts for this mode: always, unless the mode is one tier of a
-- choice (see src/bosses.lua), when the choice's var must be in that tier. The
-- game sets the var as the fight starts, before its kill.
local function inTier(boss, mode)
    if mode.tier == nil then
        return true
    end
    local choice = choices.Find(boss, mode.tier.choice)
    return choices.Snap(choice, var.VarPlayer[choice.var].value) == mode.tier.value
end

-- The current value of a var by name, or nil if the game doesn't have it.
local function value(name)
    local found = var.VarPlayer[name]
    return found and found.value
end

-- A boss's all-time totals, read from the game: { kills = { [kill count var] = n },
-- items = { [item id text] = n } for its uniques, values = { [key] = n } for its
-- reads (see src/bosses.lua) }. Nil until vars can be trusted, or if any can't be read.
function gamevars.AllTime(boss)
    if not isReady() then
        return nil
    end
    local allTime = { kills = {}, items = {}, values = {} }
    for _, mode in ipairs(boss.modes) do
        allTime.kills[mode.kc] = value(mode.kc)
        if allTime.kills[mode.kc] == nil then
            return nil
        end
    end
    for itemID, item in pairs(boss.items) do
        if item.kind == "unique" then
            local key = tostring(itemID)
            allTime.items[key] = value(item.log)
            if allTime.items[key] == nil then
                return nil
            end
        end
    end
    for key, name in pairs(boss.reads or {}) do
        allTime.values[key] = value(name)
        if allTime.values[key] == nil then
            return nil
        end
    end
    return allTime
end

-- Starts reporting changes for every boss in bosses (the list from src/bosses.lua),
-- on the logic tick after they happen:
--   onKills(boss, mode, count)   a KC varbit of that mode went up (for modes
--                                that share one, only the mode whose tier it is)
--   onDrops(boss, itemID, count) the log count of a unique item went up
-- and calls ready() each time vars can be trusted after entering the game.
function gamevars.Start(bosses, onKills, onDrops, ready)
    onReady = ready
    for _, boss in ipairs(bosses) do
        for _, mode in ipairs(boss.modes) do
            watch(mode.kc, "kills", function(count)
                if inTier(boss, mode) then
                    onKills(boss, mode, count)
                end
            end)
        end
        for itemID, item in pairs(boss.items) do
            if item.kind == "unique" then -- only items that count toward luck
                watch(item.log, "drops", function(count) onDrops(boss, itemID, count) end)
            end
        end
    end

    -- No state change arrives if the plugin starts while already in the game. Any
    -- vars sent at login should have arrived by then, so they're trusted at once.
    readyAtTick = Player.IsAvailable() and 0 or nil

    Event.Logic.Subscribe(REF, onLogic)
    Event.GameStateChanged.Subscribe(REF, onGameStateChanged)
    Event.VarTransmit.Subscribe(REF, onVarTransmit)
end

function gamevars.Stop()
    Event.Logic.Unsubscribe(REF)
    Event.GameStateChanged.Unsubscribe(REF)
    Event.VarTransmit.Unsubscribe(REF)
    watched = {}
    pending = { kills = {}, drops = {} }
    readyAtTick = nil
    onReady, announced = nil, false
end

return gamevars

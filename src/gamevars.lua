-- Reads boss kill counts and boss log counts from the game, and reports when they
-- go up. It stores nothing. The only other module that reads game vars is
-- src/capture.lua, which reads totals while the game shows them.
--
-- Kill counts and log counts are varbits: slices of a bigger "base" var. At a kill
-- or drop the game sends the base var's old and new value (VarTransmit), and the
-- change in each slice is what we report. We use only the change, at the moment the
-- player sees the kill or drop, because a var may only be used once the game has
-- shown that information to the player. Bosses whose chest hides which unique
-- dropped until it's opened would break this, so they aren't supported yet.

local safe = require("src/safe")

local gamevars = {}

local REF = "bossrng_gamevars"

-- After entering the game, wait this long before trusting changes, so vars sent at
-- login aren't mistaken for kills or drops. The client runs 50 ticks per second.
local SETTLE_TICKS = 5 * 50

-- Each KC varbit rises by 1 per kill, and an item's count by a little per drop.
-- Bigger jumps (like a login sync) and any decrease are ignored.
local MAX_CHANGE = 3

local watched = {} -- [base var id] = slices to check when that var changes
local pending = { kills = {}, drops = {} } -- changes waiting for the next tick
local tick = 0
local readyAtTick = nil -- nil while not in the game

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
    if slices == nil or readyAtTick == nil or tick < readyAtTick then
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
    if event.newState == GameState.GAME then
        readyAtTick = tick + SETTLE_TICKS
    else
        readyAtTick = nil
    end
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
end

-- True while changes are waiting for the next tick, when a kill count can already
-- show a kill that hasn't been reported yet.
function gamevars.HasPending()
    return #pending.kills > 0 or #pending.drops > 0
end

-- Starts reporting changes for every boss in bosses (the list from src/bosses.lua),
-- on the logic tick after they happen:
--   onKills(boss, mode, count)   a KC varbit of that mode went up
--   onDrops(boss, itemID, count) the log count of a unique item went up
function gamevars.Start(bosses, onKills, onDrops)
    for _, boss in ipairs(bosses) do
        for _, mode in ipairs(boss.modes) do
            watch(mode.kc, "kills", function(count) onKills(boss, mode, count) end)
        end
        for itemID, item in pairs(boss.items) do
            if item.kind == "unique" then -- only items that count toward luck
                watch(item.log, "drops", function(count) onDrops(boss, itemID, count) end)
            end
        end
    end

    -- No state change arrives if the plugin starts while already in the game. Any
    -- vars sent at login should have arrived by then, so changes are trusted at once.
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
end

return gamevars

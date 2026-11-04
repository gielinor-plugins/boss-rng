-- Watches game vars for game_vars: reports each rise of a watched count on the logic
-- tick after it arrives, and calls followers when a followed varbit's base var
-- changes. Counts are varbits: slices of a base var, whose old and new values
-- VarTransmit sends. Vars are only trusted a few seconds after entering the game.

local bits = require("src/utils/bits")
local safe = require("src/utils/safe")

local varWatch = {}

-- Wait this long (50 ticks per second) after entering the game before trusting
-- vars, so those sent at login aren't taken for kills or drops or read too early.
local SETTLE_TICKS = 5 * 50

-- A kill count rises by 1 per kill and a collection log count by 1 per item, so a rise
-- of up to 3 at once is taken as real (a stack sets its own limit). Bigger jumps, such
-- as the login sync, and any fall are ignored.
local MAX_CHANGE = 3

-- A tick's kill and drop can arrive in either order (at Kree'arra the drop came
-- first), so kills are reported first: a drop counts after the kill it landed with.
-- Rises come before both, so a kill event sees what rose in its tick.
local GROUPS = { "rises", "kills", "drops" }

local watched = {} -- [base var id] = slices to check when that var changes
local followed = {} -- [base var id] = { name, update(value) } to call after it changes
local pending = { rises = {}, kills = {}, drops = {} } -- reports waiting for the next tick
local tick = 0
local readyAtTick = nil -- nil while not in the game

function varWatch.Value(name)
    local found = var.VarPlayer[name]
    return found and found.value
end

function varWatch.Tick()
    return tick
end

-- Whether vars can be trusted: in the game, and past the wait after entering it.
function varWatch.IsReady()
    return readyAtTick ~= nil and tick >= readyAtTick
end

-- Calls update(value) with a varbit's value after each change of its base var.
function varWatch.Follow(name, update)
    local found = var.VarPlayer[name]
    local base = found and found.baseVar
    if base == nil then
        print("[Boss RNG] Unknown varbit " .. name)
        return
    end
    followed[base.id] = followed[base.id] or {}
    table.insert(followed[base.id], { name = name, update = update })
end

-- Watches a varbit by name, or mask bits of a var; report(change) gets each rise of
-- up to most (default MAX_CHANGE), in group's turn (see GROUPS). A count reports only
-- rises above its highest this session, since the game can send counts again from 0.
function varWatch.Watch(name, group, report, mask, most)
    local found = var.VarPlayer[name]
    if found == nil or (mask == nil and not found.isVarBit) then
        print("[Boss RNG] Unknown varbit " .. name)
        return
    end
    local baseID = mask and found.id or found.baseVar.id
    watched[baseID] = watched[baseID] or {}
    table.insert(watched[baseID], {
        mask = mask or found.varBitMask,
        shift = bits.LowestBit(mask or found.varBitMask),
        group = group,
        report = report,
        count = mask == nil and name or nil, -- a named varbit
        most = most or MAX_CHANGE,
    })
end

-- Queues report(change) for the next tick, in group's turn.
function varWatch.Queue(group, report, change)
    table.insert(pending[group], { report = report, change = change })
end

local function eachCount(fn)
    for _, slices in pairs(watched) do
        for _, slice in ipairs(slices) do
            if slice.count then
                fn(slice)
            end
        end
    end
end

local function rise(slice, old, new)
    local from, to = (old & slice.mask) >> slice.shift, (new & slice.mask) >> slice.shift
    if slice.count == nil then
        return to - from
    end
    from = math.max(slice.highest or from, from)
    slice.highest = math.max(from, to)
    return to - from
end

-- Checks the slices and followers of the var that changed.
function varWatch.OnTransmit(event)
    local old, new = event.oldValue, event.newValue
    for _, slice in ipairs(watched[event.var.id] or {}) do
        local change = rise(slice, old, new) -- counts keep their highest even while settling
        if varWatch.IsReady() and change > 0 and change <= slice.most then
            varWatch.Queue(slice.group, slice.report, change)
        end
    end
    for _, entry in ipairs(followed[event.var.id] or {}) do
        local now = varWatch.Value(entry.name)
        if now then
            entry.update(now)
        end
    end
end

-- Entering the game starts the wait before vars are trusted, and leaving it stops
-- trusting them. The next character may be another, so the highest counts seen are
-- forgotten.
function varWatch.OnGameState(state)
    readyAtTick = state == GameState.GAME and tick + SETTLE_TICKS or nil
    eachCount(function(slice)
        slice.highest = nil
    end)
end

-- If the plugin starts while already in the game, no state change arrives and the login
-- vars are already in, so vars are trusted at once.
function varWatch.Start(inGame)
    readyAtTick = inGame and 0 or nil
end

-- On each logic tick: reports last tick's queued changes, group by group.
function varWatch.OnLogic(logicTick)
    tick = logicTick
    for _, group in ipairs(GROUPS) do
        for _, item in ipairs(pending[group]) do
            safe.Call("recording " .. group, item.report, item.change)
        end
        pending[group] = {}
    end
end

-- Once ready: each count's current value is its highest, so a later resend from 0
-- isn't taken for rises.
function varWatch.ReadCounts()
    eachCount(function(slice)
        slice.highest = math.max(slice.highest or 0, varWatch.Value(slice.count) or 0)
    end)
end

function varWatch.Clear()
    watched, followed = {}, {}
    pending = { rises = {}, kills = {}, drops = {} }
    readyAtTick = nil
end

return varWatch

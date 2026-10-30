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

local days = require("src/days")
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
local killedThisSession = {} -- [boss] = true once a kill is reported since entering the game

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

-- Watches a varbit by name, or with mask, bits of a var the game doesn't name
-- as a varbit. report(change) is called whenever it goes up. group is "kills"
-- or "drops". A count (a kill count or a boss log count, never mask bits) only
-- goes up, so it reports only rises above the highest value it's had this
-- session: the game can send counts again from 0, and those aren't kills or drops.
local function watch(name, group, report, mask)
    local found = var.VarPlayer[name]
    if found == nil or (mask == nil and not found.isVarBit) then
        print("[Boss RNG] Unknown varbit " .. name)
        return
    end
    local baseID = mask and found.id or found.baseVar.id
    local count = mask == nil and name or nil -- a named varbit
    mask = mask or found.varBitMask
    watched[baseID] = watched[baseID] or {}
    table.insert(watched[baseID], { mask = mask, shift = lowestBit(mask), group = group, report = report, count = count })
end

-- Calls fn(slice) for every watched slice that's a count.
local function eachCount(fn)
    for _, slices in pairs(watched) do
        for _, slice in ipairs(slices) do
            if slice.count then
                fn(slice)
            end
        end
    end
end

-- How much a slice went up from old to new: for a count, from the highest it's
-- had this session (which it then keeps).
local function rise(slice, old, new)
    local from, to = (old & slice.mask) >> slice.shift, (new & slice.mask) >> slice.shift
    if slice.count == nil then
        return to - from
    end
    from = math.max(slice.highest or from, from)
    slice.highest = math.max(from, to)
    return to - from
end

local function onVarTransmit(event)
    local slices = watched[event.var.id]
    local old, new = event.oldValue, event.newValue
    if slices == nil or type(old) ~= "number" or type(new) ~= "number" then
        return
    end
    for _, slice in ipairs(slices) do
        local change = rise(slice, old, new) -- counts keep their highest even while settling
        if isReady() and change > 0 and change <= MAX_CHANGE then
            table.insert(pending[slice.group], { report = slice.report, change = change })
        end
    end
end

local function onGameStateChanged(event)
    readyAtTick = event.newState == GameState.GAME and tick + SETTLE_TICKS or nil
    announced = false
    killedThisSession = {}
    eachCount(function(slice) slice.highest = nil end) -- maybe another character
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
        eachCount(function(slice)
            local found = var.VarPlayer[slice.count]
            slice.highest = math.max(slice.highest or 0, found and found.value or 0)
        end)
        safe.Call("updating once the game is ready", onReady)
    end
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

local CLOCK = "CLOCK_TIME_DATE_MINUTES" -- minutes since 1 January 1970 (UTC)

-- Today, from the game clock (see src/days.lua), or 0 if it can't be read.
local function today()
    local minutes = value(CLOCK)
    return minutes and days.FromMinutes(minutes) or 0
end

-- The mode a boss's kill event says the kill was (see killEvents in
-- src/bosses.lua), from the game's values as it's reported, or nil if any
-- can't be read or the event gives none.
local function eventMode(boss, event)
    local values = {}
    for key, name in pairs(event.reads) do
        values[key] = value(name)
        if values[key] == nil then
            return nil
        end
    end
    local name = event.mode(values)
    return name and boss.modeFor(name)
end

-- Starts reporting changes for every boss in bosses (the list from src/bosses.lua),
-- on the logic tick after they happen:
--   onKills(boss, mode, count, day)  a KC varbit of that mode went up (modes
--                                    counted by kill events aren't watched), or
--                                    one of the boss's kill event vars did, for
--                                    the mode it says; day is today (see today)
--   onDrops(boss, itemID, count)     the log count of a unique item went up,
--                                    for a boss killed since entering the game
-- and calls ready() each time vars can be trusted after entering the game.
--
-- The game can send boss log counts again long after login, as jumps from 0
-- that look like drops. Counts only report rises above their highest this
-- session (see watch), and only bosses killed this session can have drops.
function gamevars.Start(bosses, onKills, onDrops, ready)
    onReady = ready
    local function killed(boss, mode, count)
        killedThisSession[boss] = true
        onKills(boss, mode, count, today())
    end
    for _, boss in ipairs(bosses) do
        for _, mode in ipairs(boss.modes) do
            if not mode.byEvent then
                watch(mode.kc, "kills", function(count) killed(boss, mode, count) end)
            end
        end
        for _, event in ipairs(boss.killEvents or {}) do
            watch(event.var, "kills", function()
                local mode = eventMode(boss, event)
                if mode then
                    killed(boss, mode, 1)
                end
            end, event.mask)
        end
        for itemID, item in pairs(boss.items) do
            if item.kind == "unique" then -- only items that count toward luck
                watch(item.log, "drops", function(count)
                    if killedThisSession[boss] then
                        onDrops(boss, itemID, count)
                    end
                end)
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
    onReady, announced, killedThisSession = nil, false, {}
end

return gamevars

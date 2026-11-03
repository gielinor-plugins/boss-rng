-- Reads boss kill counts and boss log counts: all-time totals, and each kill and
-- drop as a count goes up. It stores nothing and is the only module that reads game
-- vars. These counts aren't hidden (the Beasts tab and boss log show them, and Jagex
-- confirmed they may be read without either open); hidden values such as bad luck
-- mitigation are never read. Counts are varbits, slices of a base var whose old and
-- new value VarTransmit sends. For containers, claims, kill events and piles, see their
-- modules.

local bits = require("src/utils/bits")
local claims = require("src/core/claims")
local containers = require("src/core/containers")
local days = require("src/utils/days")
local killevents = require("src/core/killevents")
local piles = require("src/core/piles")
local safe = require("src/utils/safe")

local gamevars = {}

local REF = "bossrng_gamevars"

-- Wait this long (50 ticks per second) after entering the game before trusting
-- vars, so those sent at login aren't taken for kills or drops or read too early.
local SETTLE_TICKS = 5 * 50

-- A KC rises by 1 per kill, a log count by a little per drop (more for a stack).
-- Bigger jumps (like a login sync) and any decrease are ignored.
local MAX_CHANGE = 3

-- Uniques waiting for a claim (dropsAtClaim in src/bosses.lua) reach the boss log with it;
-- allow this long after the claim.
local CLAIM_TICKS = 10 * 50

local watched = {} -- [base var id] = slices to check when that var changes
local pending = { rises = {}, kills = {}, drops = {} } -- changes waiting for the next tick
local tick = 0
local readyAtTick = nil -- nil while not in the game
local onRefresh = nil -- called when all-time totals may change without a tally changing
local announced = false -- whether onRefresh was called since entering the game
local killedThisSession = {} -- [boss] = true once a kill is reported since entering the game
local claimedAt = {} -- [boss] = tick its loot was last claimed (dropsAtClaim in src/bosses.lua)

-- [base var id] = { name, update(value) }: varbits read after each change of their base var.
local followed = {}

local function queueKill(report, change)
    table.insert(pending.kills, { report = report, change = change })
end

local function value(name)
    local found = var.VarPlayer[name]
    return found and found.value
end

local function isReady()
    return readyAtTick ~= nil and tick >= readyAtTick
end

-- Calls update(value) with a varbit's value after each change of its base var.
local function follow(name, update)
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
-- up to most (default MAX_CHANGE). A count reports only rises above its highest this
-- session, since the game can send counts again from 0.
local function watch(name, group, report, mask, most)
    local found = var.VarPlayer[name]
    if found == nil or (mask == nil and not found.isVarBit) then
        print("[Boss RNG] Unknown varbit " .. name)
        return
    end
    local baseID = mask and found.id or found.baseVar.id
    local count = mask == nil and name or nil -- a named varbit
    mask = mask or found.varBitMask
    watched[baseID] = watched[baseID] or {}
    table.insert(watched[baseID], {
        mask = mask,
        shift = bits.LowestBit(mask),
        group = group,
        report = report,
        count = count,
        most = most or MAX_CHANGE,
    })
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

local function onVarTransmit(event)
    local old, new = event.oldValue, event.newValue
    if type(old) ~= "number" or type(new) ~= "number" then
        return
    end
    for _, slice in ipairs(watched[event.var.id] or {}) do
        local change = rise(slice, old, new) -- counts keep their highest even while settling
        if isReady() and change > 0 and change <= slice.most then
            table.insert(pending[slice.group], { report = slice.report, change = change })
        end
    end
    for _, entry in ipairs(followed[event.var.id] or {}) do
        local now = value(entry.name)
        if now then
            entry.update(now)
        end
    end
    if isReady() then
        claims.OnVar(event.var.id, old, new, queueKill)
    end
end

local function onGameStateChanged(event)
    readyAtTick = event.newState == GameState.GAME and tick + SETTLE_TICKS or nil
    announced = false
    killedThisSession = {}
    containers.Forget()
    -- Maybe another character: forget the highest counts seen.
    eachCount(function(slice)
        slice.highest = nil
    end)
end

local function onInventory(event)
    if isReady() then
        containers.OnInventory(event)
    end
end

local function onPileAdded(event)
    if isReady() then
        piles.OnAdded(event)
    end
end

local function onPileChanged(event)
    if isReady() then
        piles.OnChanged(event)
    end
end

-- A tick's kill and drop can arrive in either order (at Kree'arra the drop came
-- first), so kills are reported first: a drop counts after the kill it landed with.
-- Rises come before both, so a kill event sees what rose in its tick.
local function flush()
    containers.EndTick(queueKill)
    for _, group in ipairs({ "rises", "kills", "drops" }) do
        for _, item in ipairs(pending[group]) do
            safe.Call("recording " .. group, item.report, item.change)
        end
        pending[group] = {}
    end
    killevents.EndTick()
end

local function onLogic(event)
    tick = event.logicTick
    flush() -- kill events read this tick's piles, so they're cleared after
    claims.EndTick()
    piles.EndTick()
    if isReady() and not announced then
        announced = true
        eachCount(function(slice)
            slice.highest = math.max(slice.highest or 0, value(slice.count) or 0)
        end)
        claims.Ready()
        containers.Ready()
        safe.Call("updating once the game is ready", onRefresh)
    end
end

-- A boss's all-time kills, or nil until vars can be trusted or if any can't be read.
function gamevars.AllTimeKills(boss)
    if not isReady() then
        return nil
    end
    local total = 0
    for _, mode in ipairs(boss.modes) do
        local kills = value(mode.kc)
        if kills == nil then
            return nil
        end
        total = total + kills
    end
    return total
end

-- A boss's all-time totals, nil as above: { kills = { [kill count var] = n },
-- items = { [unique's id text] = n }, values = { [reads key] = n } }.
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
        local key = tostring(itemID)
        allTime.items[key] = value(item.log)
        if allTime.items[key] == nil then
            return nil
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

-- Today, from the game clock (see src/utils/days.lua), or 0 if it can't be read.
local function today()
    local minutes = value(CLOCK)
    return minutes and days.FromMinutes(minutes) or 0
end

-- Whether a boss's unique can drop now: after a kill since entering the game or, for
-- loot that waits for a claim, just after the claim.
local function canDrop(boss)
    if boss.dropsAtClaim then
        return claimedAt[boss] ~= nil and tick - claimedAt[boss] <= CLAIM_TICKS
    end
    return killedThisSession[boss]
end

-- Called with each kill and drop (see gamevars.Start).
local onKills, onDrops = nil, nil

local function killed(boss, mode, count, sums)
    killedThisSession[boss] = true
    onKills(boss, mode, count, today(), sums)
end

-- Kills counted by a kill count rising, for modes not counted by events. A kill
-- counted later, at a chest or claim, still changes the all-time kills shown.
local function watchKillCounts(boss)
    local countedLater = boss.containers ~= nil or boss.claims ~= nil
    for _, mode in ipairs(boss.modes) do
        if not mode.byEvent then
            watch(mode.kc, "kills", function(count)
                killed(boss, mode, count)
            end)
        elseif countedLater then
            watch(mode.kc, "kills", function()
                safe.Call("updating after a kill", onRefresh)
            end)
        end
    end
end

-- How kill events read vars (see src/core/killevents.lua).
local READER = { watch = watch, follow = follow, value = value }

local function watchKillEvents(boss)
    for _, event in ipairs(boss.killEvents or {}) do
        killevents.Add(boss, event, READER, function(mode, sums)
            killed(boss, mode, 1, sums)
        end)
    end
end

local function watchClaims(boss)
    for _, claim in ipairs(boss.claims or {}) do
        local base = var.VarPlayer[claim.var]
        if base then
            local countKill = claims.Add(base, claim.mask, function(old, count)
                local mode = killevents.Mode(boss, claim, value, old)
                if mode then
                    killed(boss, mode, count)
                end
            end)
            for _, kc in ipairs(claim.kills) do
                watch(kc, "kills", countKill)
            end
        else
            print("[Boss RNG] Unknown var " .. claim.var)
        end
    end
end

local function watchContainers(boss)
    for itemID, container in pairs(boss.containers or {}) do
        for _, mode in ipairs(boss.modes) do
            if mode.key == container.mode then
                containers.Add(itemID, container.window, function(count)
                    killed(boss, mode, count)
                end)
            end
        end
    end
end

-- Drops: each unique's log count rising, after a kill or, for loot that waits for a
-- claim, after the claim.
local function watchDrops(boss)
    if boss.dropsAtClaim then
        local held = 0
        follow(boss.dropsAtClaim.var, function(now)
            if isReady() and held > 0 and now == 0 then
                claimedAt[boss] = tick
            end
            held = now
        end)
    end
    for itemID, item in pairs(boss.items) do
        local stack = item.stack and item.stack.most
        watch(item.log, "drops", function(count)
            if canDrop(boss) then
                onDrops(boss, itemID, stack and 1 or count)
            end
        end, nil, stack or (boss.dropsAtClaim and boss.dropsAtClaim.most))
    end
end

local HANDLERS = {
    Logic = onLogic,
    GameStateChanged = onGameStateChanged,
    VarTransmit = onVarTransmit,
    InventoryAdded = onInventory,
    InventoryUpdated = onInventory,
    ObjStackEntityAdded = onPileAdded,
    ObjStackEntityChanged = onPileChanged,
}

-- Reports changes for every boss in bosses on the logic tick after they happen:
--   kills(boss, mode, count, day, sums)  a KC rise, kill event, opened container or
--                                        claim; sums: a kill event's (or nil)
--   drops(boss, itemID, count)           a unique's log count rose (a stack's rise is one)
-- and calls refresh() each time vars can be trusted, and when a kill counted later (at
-- a chest or claim) raises a kill count. The game can resend log counts long
-- after login as jumps from 0, so only bosses killed this session, or just claimed,
-- can have drops.
function gamevars.Start(bosses, kills, drops, refresh)
    onKills, onDrops, onRefresh = kills, drops, refresh
    for _, boss in ipairs(bosses) do
        watchKillCounts(boss)
        watchKillEvents(boss)
        watchClaims(boss)
        watchContainers(boss)
        watchDrops(boss)
    end

    -- Started in the game: no state change arrives, and login vars are already in.
    readyAtTick = Player.IsAvailable() and 0 or nil

    for name, handler in pairs(HANDLERS) do
        Event[name].Subscribe(REF, handler)
    end
end

function gamevars.Stop()
    for name in pairs(HANDLERS) do
        Event[name].Unsubscribe(REF)
    end
    watched, followed, claimedAt = {}, {}, {}
    claims.Clear()
    killevents.Clear()
    containers.Clear()
    piles.Clear()
    pending = { rises = {}, kills = {}, drops = {} }
    readyAtTick = nil
    onKills, onDrops, onRefresh, announced, killedThisSession = nil, nil, nil, false, {}
end

return gamevars

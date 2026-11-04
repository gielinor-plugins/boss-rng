-- Reads boss kill counts and boss log counts: all-time totals, and each kill and
-- drop as a count goes up. It stores nothing; it and its helpers (vars, and the
-- containers, claims, kill events and piles modules) are the only code that reads
-- the game. These counts aren't hidden (the Beasts tab and boss log show them, and
-- Jagex confirmed they may be read without either open); hidden values such as bad
-- luck mitigation are never read.

local claims = require("src/core/claims")
local containers = require("src/core/containers")
local days = require("src/utils/days")
local killevents = require("src/core/killevents")
local piles = require("src/core/piles")
local safe = require("src/utils/safe")
local vars = require("src/core/vars")

local gamevars = {}

local REF = "bossrng_gamevars"

-- Uniques waiting for a claim (dropsAtClaim in src/bosses.lua) reach the boss log with it;
-- allow this long after the claim.
local CLAIM_TICKS = 10 * 50

local onRefresh = nil -- called when all-time totals may change without a tally changing
local announced = false -- whether onRefresh was called since entering the game
local killedThisSession = {} -- [boss] = true once a kill is reported since entering the game
local claimedAt = {} -- [boss] = tick its loot was last claimed (dropsAtClaim in src/bosses.lua)

local function queueKill(report, change)
    vars.Queue("kills", report, change)
end

local function onVarTransmit(event)
    if type(event.oldValue) ~= "number" or type(event.newValue) ~= "number" then
        return
    end
    vars.OnTransmit(event)
    if vars.IsReady() then
        claims.OnVar(event.var.id, event.oldValue, event.newValue, queueKill)
    end
end

local function onGameStateChanged(event)
    vars.OnGameState(event.newState)
    announced = false
    killedThisSession = {}
    containers.Forget()
end

local function onInventory(event)
    if vars.IsReady() then
        containers.OnInventory(event)
    end
end

local function onPileAdded(event)
    if vars.IsReady() then
        piles.OnAdded(event)
    end
end

local function onPileChanged(event)
    if vars.IsReady() then
        piles.OnChanged(event)
    end
end

local function onLogic(event)
    containers.EndTick(queueKill)
    vars.OnLogic(event.logicTick)
    -- Kill events read this tick's rises and piles, so they're cleared after.
    killevents.EndTick()
    claims.EndTick()
    piles.EndTick()
    if vars.IsReady() and not announced then
        announced = true
        vars.ReadCounts()
        claims.Ready()
        containers.Ready()
        safe.Call("updating once the game is ready", onRefresh)
    end
end

-- A boss's all-time kills, or nil until vars can be trusted or if any can't be read.
function gamevars.AllTimeKills(boss)
    if not vars.IsReady() then
        return nil
    end
    local total = 0
    for _, killCount in ipairs(boss.killCounts) do
        local kills = vars.Value(killCount.var)
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
    if not vars.IsReady() then
        return nil
    end
    local allTime = { kills = {}, items = {}, values = {} }
    for _, killCount in ipairs(boss.killCounts) do
        allTime.kills[killCount.var] = vars.Value(killCount.var)
        if allTime.kills[killCount.var] == nil then
            return nil
        end
    end
    for itemID, item in pairs(boss.items) do
        local key = tostring(itemID)
        allTime.items[key] = vars.Value(item.log)
        if allTime.items[key] == nil then
            return nil
        end
    end
    for key, name in pairs(boss.reads or {}) do
        allTime.values[key] = vars.Value(name)
        if allTime.values[key] == nil then
            return nil
        end
    end
    return allTime
end

local CLOCK = "CLOCK_TIME_DATE_MINUTES" -- minutes since 1 January 1970 (UTC)

-- Today, from the game clock (see src/utils/days.lua), or 0 if it can't be read.
local function today()
    local minutes = vars.Value(CLOCK)
    return minutes and days.FromMinutes(minutes) or 0
end

-- Whether a boss's unique can drop now: after a kill since entering the game or, for
-- loot that waits for a claim, just after the claim.
local function canDrop(boss)
    if boss.dropsAtClaim then
        return claimedAt[boss] ~= nil and vars.Tick() - claimedAt[boss] <= CLAIM_TICKS
    end
    return killedThisSession[boss]
end

-- Called with each kill and drop (see gamevars.Start).
local onKills, onDrops = nil, nil

local function killed(boss, mode, count, sums)
    killedThisSession[boss] = true
    onKills(boss, mode, count, today(), sums)
end

-- Kills counted by a kill count rising, for kill counts naming their mode. A kill
-- counted later, at a chest or claim, still changes the all-time kills shown.
local function watchKillCounts(boss)
    local countedLater = boss.containers ~= nil or boss.claims ~= nil
    for _, killCount in ipairs(boss.killCounts) do
        local mode = killCount.mode and boss.modes[killCount.mode]
        if mode then
            vars.Watch(killCount.var, "kills", function(count)
                killed(boss, mode, count)
            end)
        elseif countedLater then
            vars.Watch(killCount.var, "kills", function()
                safe.Call("updating after a kill", onRefresh)
            end)
        end
    end
end

local function watchKillEvents(boss)
    for _, event in ipairs(boss.killEvents or {}) do
        killevents.Add(boss, event, function(mode, sums)
            killed(boss, mode, 1, sums)
        end)
    end
end

local function watchClaims(boss)
    for _, claim in ipairs(boss.claims or {}) do
        local base = var.VarPlayer[claim.var]
        if base then
            local countKill = claims.Add(base, claim.mask, function(old, count)
                local mode = killevents.Mode(boss, claim, old)
                if mode then
                    killed(boss, mode, count)
                end
            end)
            for _, kc in ipairs(claim.kills) do
                vars.Watch(kc, "kills", countKill)
            end
        else
            print("[Boss RNG] Unknown var " .. claim.var)
        end
    end
end

local function watchContainers(boss)
    for itemID, container in pairs(boss.containers or {}) do
        local mode = boss.modes[container.mode]
        containers.Add(itemID, container.window, function(count)
            killed(boss, mode, count)
        end)
    end
end

-- Drops: each unique's log count rising, after a kill or, for loot that waits for a
-- claim, after the claim.
local function watchDrops(boss)
    if boss.dropsAtClaim then
        local held = 0
        vars.Follow(boss.dropsAtClaim.var, function(now)
            if vars.IsReady() and held > 0 and now == 0 then
                claimedAt[boss] = vars.Tick()
            end
            held = now
        end)
    end
    for itemID, item in pairs(boss.items) do
        local stack = item.stack and item.stack.most
        vars.Watch(item.log, "drops", function(count)
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

    vars.Start(Player.IsAvailable())

    for name, handler in pairs(HANDLERS) do
        Event[name].Subscribe(REF, handler)
    end
end

function gamevars.Stop()
    for name in pairs(HANDLERS) do
        Event[name].Unsubscribe(REF)
    end
    claimedAt = {}
    vars.Clear()
    claims.Clear()
    killevents.Clear()
    containers.Clear()
    piles.Clear()
    onKills, onDrops, onRefresh, announced, killedThisSession = nil, nil, nil, false, {}
end

return gamevars

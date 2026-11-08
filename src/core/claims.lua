-- Loot that waits in a chest until claimed (claims in src/bosses.lua). When its bits
-- fall to 0, the value they fell from is what was claimed. A claim counts only if all
-- of it was seen arriving with kills; loot waiting from before, or a kill that didn't
-- raise it, leaves that claim uncounted.
-- A batch is what game_vars reports at once (QUIET_TICKS in src/core/game_vars.lua).

local bits = require("src/utils/bits")

local claims = {}

-- Each claim keeps the loot and kills seen since its bits were last 0 (each rise is a
-- kill), and this batch's kill count rises and rises of its bits.
local byVar, list = {}, {}

-- Watches mask bits of var base; report(old, loot, kills) gets each counted claim: the
-- var's value before the claim, how much was claimed, and the kills it came from.
-- Returns a function to call with each kill count rise.
function claims.Add(base, mask, report)
    local claim = {
        base = base,
        mask = mask,
        shift = bits.LowestBit(mask),
        report = report,
        loot = 0,
        kills = 0,
        trusted = false,
        batchKills = 0,
        batchRises = 0,
    }
    byVar[base.id] = byVar[base.id] or {}
    table.insert(byVar[base.id], claim)
    table.insert(list, claim)
    return function(count)
        claim.batchKills = claim.batchKills + count
    end
end

-- Whether this var holds a claim's loot.
function claims.Watches(id)
    return byVar[id] ~= nil
end

-- Passes each counted claim's report, and how much was claimed, to queue.
function claims.OnVar(id, old, new, queue)
    for _, claim in ipairs(byVar[id] or {}) do
        local from, to = (old & claim.mask) >> claim.shift, (new & claim.mask) >> claim.shift
        if to > from then
            claim.loot, claim.kills = claim.loot + to - from, claim.kills + 1
            claim.batchRises = claim.batchRises + 1
        elseif from > 0 and to == 0 then
            if claim.trusted and claim.loot == from then
                local kills = claim.kills
                queue(function(loot)
                    claim.report(old, loot, kills)
                end, from)
            end
            claim.loot, claim.kills, claim.trusted = 0, 0, true
        end
    end
end

-- A kill that didn't raise its claim's bits means loot arrived unseen, so that claim
-- isn't trusted until the chest is empty again.
function claims.EndBatch()
    for _, claim in ipairs(list) do
        if claim.batchKills > claim.batchRises then
            claim.trusted = false
        end
        claim.batchKills, claim.batchRises = 0, 0
    end
end

-- Loot already waiting arrived unseen, so only an empty chest is trusted.
function claims.Ready()
    for _, claim in ipairs(list) do
        local held = claim.base.value
        claim.trusted = held ~= nil and (held & claim.mask) == 0
        claim.loot, claim.kills = 0, 0
    end
end

function claims.Clear()
    byVar, list = {}, {}
end

return claims

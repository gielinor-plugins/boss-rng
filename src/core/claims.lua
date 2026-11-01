-- Loot that waits in a chest until claimed (see claims in src/bosses.lua): when
-- its bits fall to 0, their old value is the claim. A claim counts only if all of
-- it was seen arriving with kills; loot waiting from before, or a kill that didn't
-- raise it, leaves that claim uncounted.

local bits = require("src/utils/bits")

local claims = {}

-- seen: loot seen since the bits were last 0; kills, rises: this tick's counts.
local byVar, list = {}, {}

-- Watches mask bits of var base; report(old, held) gets each counted claim.
-- Returns a function to call with each kill's count.
function claims.Add(base, mask, report)
    local claim = {
        base = base, mask = mask, shift = bits.LowestBit(mask), report = report,
        seen = 0, trusted = false, kills = 0, rises = 0,
    }
    byVar[base.id] = byVar[base.id] or {}
    table.insert(byVar[base.id], claim)
    table.insert(list, claim)
    return function(count) claim.kills = claim.kills + count end
end

-- Passes a counted claim to queue(report, held).
function claims.OnVar(id, old, new, queue)
    for _, claim in ipairs(byVar[id] or {}) do
        local from, to = (old & claim.mask) >> claim.shift, (new & claim.mask) >> claim.shift
        if to > from then
            claim.seen, claim.rises = claim.seen + to - from, claim.rises + 1
        elseif from > 0 and to == 0 then
            if claim.trusted and claim.seen == from then
                queue(function(count) claim.report(old, count) end, from)
            end
            claim.seen, claim.trusted = 0, true
        end
    end
end

function claims.EndTick()
    for _, claim in ipairs(list) do
        if claim.kills > claim.rises then
            claim.trusted = false
        end
        claim.kills, claim.rises = 0, 0
    end
end

-- Loot already waiting arrived unseen, so only an empty chest is trusted.
function claims.Ready()
    for _, claim in ipairs(list) do
        local held = claim.base.value
        claim.trusted, claim.seen = held ~= nil and (held & claim.mask) == 0, 0
    end
end

function claims.Clear()
    byVar, list = {}, {}
end

return claims

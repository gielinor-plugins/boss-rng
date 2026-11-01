-- Loot that waits in a chest until claimed (see claims in src/bosses.lua):
-- when its bits fall to 0, their old value is how much was claimed. A claim
-- counts only if every bit of it was seen arriving with a kill; loot waiting
-- from before, or a kill that didn't raise it, leaves that claim uncounted.

local bits = require("src/utils/bits")

local claims = {}

-- Each { base, mask, shift, report, seen, trusted, kills, rises }: seen is the
-- loot seen arriving since the bits were last 0, and kills and rises count this
-- tick's kills and loot rises. By base var id, and as a list.
local byVar, list = {}, {}

-- Watches mask bits of base (a var). report(old, held) is called for a counted
-- claim. Returns a function to call with each kill's count.
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

-- Notes a change to var id from old to new. A counted claim is passed to
-- queue(report, held).
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

-- Ends a tick: a kill that didn't raise its claim's loot makes it untrusted.
function claims.EndTick()
    for _, claim in ipairs(list) do
        if claim.kills > claim.rises then
            claim.trusted = false
        end
        claim.kills, claim.rises = 0, 0
    end
end

-- Once vars can be trusted: loot already waiting arrived unseen, so only an
-- empty chest is trusted.
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

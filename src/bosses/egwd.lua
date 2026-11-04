-- Shared by the Elder God Wars Dungeon bosses. Not a boss file. The enriched pontifex
-- shadow ring raises every unique by 2%: each unique roll is out of 98% of its usual
-- range. Source: a Jagex moderator, quoted on the RuneScape Wiki, checked 2026-11-03.
-- The game rounds that range down, which changes rates by under 0.3%. A ring that's only
-- worn can't be seen; an overcharged one works without being worn, and the game shows
-- it. So only an overcharged ring raises rates here.

local tables = require("src/utils/tables")

local egwd = {}

local RING = "EGWD_PONTIFEX_RING_PASSIVE_UNLOCKED" -- 1 once overcharged
local RING_BOOST = 1 / 0.98

-- A boss's reads (see src/bosses.lua): own, and the ring's.
function egwd.Reads(own)
    return tables.Merge({ ring = RING }, own)
end

-- A unique roll's chance, raised if the ring is overcharged.
function egwd.Boost(chance, readings)
    return readings.ring == 1 and chance * RING_BOOST or chance
end

-- A mode's rolls function, with every roll raised if the ring is overcharged.
function egwd.Boosted(rolls)
    return function(r, readings, means)
        local boosted = {}
        for i, roll in ipairs(rolls(r, readings, means)) do
            boosted[i] = { chance = egwd.Boost(roll.chance, readings), items = roll.items }
        end
        return boosted
    end
end

return egwd

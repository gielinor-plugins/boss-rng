-- The unique rolls the God Wars Dungeon generals share. Not a boss file: the
-- generals' files use it so the roll math lives in one place.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-27: a 1/64 roll for
-- the general's unique table, then an item from it at random (1/6 each for
-- Graardor's armor, 1/5 per entry for Zilyana's); only if that roll misses, a
-- 1/512 roll for the hilt. So a kill gives at most one of these, and the hilt's
-- real chance per kill is 63/64 x 1/512. Hard mode doesn't change these rates.

local godwars = {}

local UNIQUE_TABLE = 1 / 64
local HILT = (1 - UNIQUE_TABLE) / 512

-- The rolls for a general: uniques, its unique table as { [item id] = weight }
-- (equal weights split it evenly), and hilt, its hilt id. They're one roll since
-- they can't drop together: each item's weight is its chance per kill, so the
-- roll's chance is their sum.
function godwars.Rolls(uniques, hilt)
    local totalWeight = 0
    for _, weight in pairs(uniques) do
        totalWeight = totalWeight + weight
    end
    local items = { [hilt] = HILT }
    for itemID, weight in pairs(uniques) do
        items[itemID] = UNIQUE_TABLE * weight / totalWeight
    end
    return { { chance = UNIQUE_TABLE + HILT, items = items } }
end

-- Weights for a unique table split evenly between ids.
function godwars.Even(ids)
    local weights = {}
    for _, itemID in ipairs(ids) do
        weights[itemID] = 1
    end
    return weights
end

return godwars

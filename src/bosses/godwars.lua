-- The unique rolls the God Wars Dungeon generals share. Not a boss file: the
-- generals' files use it so the roll math lives in one place.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-27: a 1/64 roll for
-- the armor table, then 1/6 per piece; only if that roll misses, a 1/512 roll
-- for the hilt. So a kill gives at most one of these, and the hilt's real chance
-- per kill is 63/64 x 1/512. Hard mode doesn't change these rates.

local godwars = {}

local ARMOR = 1 / 64
local HILT = (1 - ARMOR) / 512

-- The rolls for a general: armor, a list of its six armor piece ids, and hilt,
-- its hilt id. They're one roll since they can't drop together: each item's
-- weight is its chance per kill, so the roll's chance is their sum.
function godwars.Rolls(armor, hilt)
    local items = { [hilt] = HILT }
    for _, itemID in ipairs(armor) do
        items[itemID] = ARMOR / #armor
    end
    return { { chance = ARMOR + HILT, items = items } }
end

return godwars

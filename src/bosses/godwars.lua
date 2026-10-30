-- What the God Wars Dungeon generals share. Not a boss file: the generals' files
-- use it so the roll math and shared items live in one place.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-27: a 1/64 roll for
-- the general's unique table, then an item from it at random (1/6 each for
-- Graardor's armor, 1/5 per entry for Zilyana's); only if that roll misses, a
-- 1/512 roll for the hilt. So a kill gives at most one of these, and the hilt's
-- real chance per kill is 63/64 x 1/512. Hard mode doesn't change these rates.

local godwars = {}

local UNIQUE_TABLE = 1 / 64
local HILT = (1 - UNIQUE_TABLE) / 512

-- Godsword shards come from a table shared by the God Wars bosses, so their
-- boss log counts aren't one general's.
local SHARDS = {
    [11710] = { log = "ITEMLOG_ITEM_GWD_SHARD1", kind = "shared" },
    [11712] = { log = "ITEMLOG_ITEM_GWD_SHARD2", kind = "shared" },
    [11714] = { log = "ITEMLOG_ITEM_GWD_SHARD3", kind = "shared" },
}

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

-- A general's items: its own, the Godsword shards, and its god's Warpriest set,
-- { [piece] = item id } with log counts named log .. piece. The Warpriest set
-- also drops from the bodyguards and other monsters of that god, so it's shared.
function godwars.Items(own, log, warpriest)
    local items = {}
    for _, source in ipairs({ own, SHARDS }) do
        for itemID, item in pairs(source) do
            items[itemID] = item
        end
    end
    for piece, itemID in pairs(warpriest) do
        items[itemID] = { log = log .. piece, kind = "shared" }
    end
    return items
end

return godwars

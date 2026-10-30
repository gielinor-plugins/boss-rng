-- What the God Wars Dungeon generals share. Not a boss file: the generals' files
-- use it so the roll math and shared items live in one place.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-27: a 1/64 roll for
-- the general's unique table, then an item from it at random (1/6 each for
-- Graardor's armor, 1/5 per entry for Zilyana's); only if that roll misses, a
-- 1/512 roll for the hilt. So a kill gives at most one of these, and the hilt's
-- real chance per kill is 63/64 x 1/512. Hard mode doesn't change these rates.
-- Jagex's Late-Game Rebalance raises armor (shields included) to 1/320, the
-- hilts to 1/384 and some weapons; a kill still gives at most one.

local common = require("src/bosses/common")

local godwars = {}

-- A general's rolls: chances, its items' chances per kill, { [item id] = chance },
-- with its hilt's from r, its rate values. One roll, since a kill gives at most one.
function godwars.Rolls(chances, hilt, r)
    chances[hilt] = r.hilt
    return { common.OneOf(chances) }
end

-- Godsword shards come from a table shared by the God Wars bosses, so their
-- boss log counts aren't one general's.
local SHARDS = {
    [11710] = { log = "ITEMLOG_ITEM_GWD_SHARD1", kind = "shared" },
    [11712] = { log = "ITEMLOG_ITEM_GWD_SHARD2", kind = "shared" },
    [11714] = { log = "ITEMLOG_ITEM_GWD_SHARD3", kind = "shared" },
}

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

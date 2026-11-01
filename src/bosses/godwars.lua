-- Shared by the God Wars Dungeon generals. Not a boss file. Rates: RuneScape Wiki
-- (CC BY-NC-SA 3.0), checked 2026-10-27: a unique table roll and, only if it misses, a
-- hilt roll, so a kill gives at most one. Hard mode has the same rates.

local common = require("src/bosses/common")

local godwars = {}

-- One roll: chances is { [item id] = chance per kill }, plus the hilt at r.hilt.
function godwars.Rolls(chances, hilt, r)
    chances[hilt] = r.hilt
    return { common.OneOf(chances) }
end

-- Godsword shards come from a table all God Wars bosses share.
local SHARDS = {
    [11710] = { log = "ITEMLOG_ITEM_GWD_SHARD1", kind = "shared" },
    [11712] = { log = "ITEMLOG_ITEM_GWD_SHARD2", kind = "shared" },
    [11714] = { log = "ITEMLOG_ITEM_GWD_SHARD3", kind = "shared" },
}

-- Its own items, the shards, and its god's Warpriest set ({ [piece] = item id }, logs
-- log .. piece), shared since other monsters of that god drop it too.
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

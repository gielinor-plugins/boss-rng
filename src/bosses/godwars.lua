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

return godwars

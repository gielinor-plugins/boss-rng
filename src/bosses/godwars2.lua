-- Shared by the God Wars Dungeon 2 bosses. Not a boss file. Rates: RuneScape Wiki
-- (CC BY-NC-SA 3.0), checked 2026-10-27: one table for an anima core piece, the crest or
-- the weapons, and only if it misses a roll for the essence. The anima pieces' log counts
-- are shared by all four bosses, so they aren't counted but still take table chance.

local common = require("src/bosses/common")

local godwars2 = {}

local ANIMA_PIECES = 3 -- dormant anima core helm, body and legs

-- Rolls for "normal" or "hard": nothing here drops together, so it's one roll.
function godwars2.Rolls(mode, crest, weapons, essence)
    return function(r)
        local items = common.Each(weapons, r[mode], { [crest] = r[mode .. "Crest"] })
        local tableChance = items[crest] + r[mode] * (#weapons + ANIMA_PIECES)
        items[essence] = (1 - tableChance) * r[mode .. "Essence"]
        return { common.OneOf(items) }
    end
end

return godwars2

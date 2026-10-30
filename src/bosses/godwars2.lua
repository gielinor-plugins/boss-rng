-- The unique rolls the God Wars Dungeon 2 bosses share. Not a boss file: their
-- files use it so the roll math lives in one place.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-27: each boss rolls
-- one table for a dormant anima core piece, its crest or its weapons, every item
-- at the same rate: 1/256 in normal mode (1/255 at Vindicta) and 1/179 in hard
-- mode. Only if that misses, a 1/64 (hard mode 1/44) roll for its essence.
-- Jagex's Late-Game Rebalance raises the crests to 1/128 (src/rates/).
--
-- The anima core pieces' boss log counts are shared by all four bosses, so they
-- aren't counted, but they still take up the table's chance. Nothing here can
-- drop together, so the counted items share one roll, each weighted by its
-- chance per kill.

local common = require("src/bosses/common")

local godwars2 = {}

local ANIMA_PIECES = 3 -- dormant anima core helm, body and legs

-- The rolls for a mode ("normal" or "hard"), as a function of the rate values
-- (see src/rates/base.lua): the boss's crest, its weapons and its essence. Nothing here can drop
-- together, so it's one roll; the essence is only rolled if the table misses.
function godwars2.Rolls(mode, crest, weapons, essence)
    return function(r)
        local items = common.Each(weapons, r[mode], { [crest] = r[mode .. "Crest"] })
        local tableChance = items[crest] + r[mode] * (#weapons + ANIMA_PIECES)
        items[essence] = (1 - tableChance) * r[mode .. "Essence"]
        return { common.OneOf(items) }
    end
end

-- Every God Wars 2 boss page lists these, with shared boss log counts.
godwars2.SHARED = {
    [37009] = { log = "ITEMLOG_ITEM_GWD2_HEAD", kind = "shared" }, -- Dormant anima core helm
    [37012] = { log = "ITEMLOG_ITEM_GWD2_BODY", kind = "shared" }, -- Dormant anima core body
    [37015] = { log = "ITEMLOG_ITEM_GWD2_LEGS", kind = "shared" }, -- Dormant anima core legs
}

-- A boss's items: its own, plus the shared anima core pieces.
function godwars2.Items(own)
    local items = {}
    for _, source in ipairs({ own, godwars2.SHARED }) do
        for itemID, item in pairs(source) do
            items[itemID] = item
        end
    end
    return items
end

return godwars2

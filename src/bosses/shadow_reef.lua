-- The Shadow Reef: only the Ambassador's crossbow pieces are tracked. Rates: RuneScape
-- Wiki (CC BY-NC-SA 3.0), checked 2026-10-31. Pieces drop in sequence, so they're one
-- group. Kills count as in src/bosses/elite_dungeon.lua.

local common = require("src/bosses/common")
local eliteDungeon = require("src/bosses/elite_dungeon")

local VARS = {
    kc = "BSLAY_KILLS_DUNGEON_ULTHVEN3", -- the Ambassador (Ulthven is the Shadow Reef)
    log = "ITEMLOG_ITEM_DUNGEON_2H_RANGED_", -- each piece's log count, by its name
}

local LIMB, MECHANISM, STOCK = 47490, 47494, 47492
local PIECES = common.Even({ LIMB, MECHANISM, STOCK })
local CROSSBOW = { name = "Crossbow pieces" }

local function pieces(team)
    return function(r)
        return { { chance = r[team], items = PIECES } }
    end
end

local dungeon = eliteDungeon.New()
dungeon.Add("a", VARS.kc, pieces) -- the Ambassador

return {
    key = "shadow_reef", -- saved data key: never change it
    name = "The Shadow Reef",
    assumptions = { eliteDungeon.ASSUMPTION },
    killCounts = dungeon.killCounts,
    modes = dungeon.modes,
    killEvents = dungeon.killEvents,

    items = {
        [LIMB] = { log = VARS.log .. "LIMB", group = CROSSBOW },
        [MECHANISM] = { log = VARS.log .. "MECHANISM", group = CROSSBOW },
        [STOCK] = { log = VARS.log .. "STOCK", group = CROSSBOW },
    },
}

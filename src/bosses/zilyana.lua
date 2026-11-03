-- Commander Zilyana, God Wars Dungeon. Rates: see src/bosses/godwars.lua. The two
-- Armadyl crossbows split one table entry evenly.

local common = require("src/bosses/common")
local godwars = require("src/bosses/godwars")

local VARS = {
    kc = "BSLAY_KILLS_GWD_ZILYANA",
    kcHard = "BSLAY_KILLS_GWD_ZILYANA_HARDMODE",
    log = "ITEMLOG_ITEM_GWD_SARA_", -- each unique's log count, by its item
    warpriest = "ITEMLOG_ITEM_WARPRIEST_SARA_", -- the Warpriest set's log counts
}

local SWORD, CROSSBOW, OFFHAND_CROSSBOW = 11730, 25037, 34855
local WHISPER, HISS, MURMUR, HUM, HILT = 25028, 25031, 25034, 61117, 11706

local OTHERS = { SWORD, WHISPER, HISS, MURMUR }
local CROSSBOWS = { CROSSBOW, OFFHAND_CROSSBOW }
local function rolls(r)
    return godwars.Rolls(common.Each(CROSSBOWS, r.crossbow, common.Each(OTHERS, r.other)), HILT, r)
end

return {
    key = "zilyana", -- saved data key: never change it
    name = "Commander Zilyana",
    assumptions = { common.SOLO_KILLS },

    modes = common.Modes(VARS, rolls),

    items = godwars.Items(
        {
            [SWORD] = { log = VARS.log .. "SWORD", kind = "unique" },
            [CROSSBOW] = { log = VARS.log .. "CROSSBOW", kind = "unique" },
            [OFFHAND_CROSSBOW] = { log = VARS.log .. "CROSSBOW_OFFHAND", kind = "unique" },
            [WHISPER] = { log = VARS.log .. "AMULET_MELEE", kind = "unique" },
            [HISS] = { log = VARS.log .. "AMULET_MAGIC", kind = "unique" },
            [MURMUR] = { log = VARS.log .. "AMULET_RANGED", kind = "unique" },
            [HILT] = { log = VARS.log .. "HILT", kind = "unique" },
            -- The wiki gives no rate for the hum ("very rare"), so it isn't counted.
            [HUM] = { log = VARS.log .. "AMULET_NECROMANCY", kind = "excluded" },
            [25040] = { kind = "lore" }, -- Zilyana's Notes
            [33807] = { kind = "pet" }, -- Commander Miniana
        },
        VARS.warpriest,
        { HELM = 28767, CAPE = 28770, BODY = 28761, LEGS = 28764, GLOVES = 28755, BOOTS = 28758 }
    ),
}

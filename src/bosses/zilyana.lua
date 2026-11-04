-- Commander Zilyana, God Wars Dungeon. Rates: see src/bosses/godwars.lua. The two
-- Armadyl crossbows split one table entry evenly.

local common = require("src/bosses/common")
local godwars = require("src/bosses/godwars")

local VARS = {
    kc = "BSLAY_KILLS_GWD_ZILYANA",
    kcHard = "BSLAY_KILLS_GWD_ZILYANA_HARDMODE",
    log = "ITEMLOG_ITEM_GWD_SARA_", -- each unique's log count, by its item
}

local SWORD, CROSSBOW, OFFHAND_CROSSBOW = 11730, 25037, 34855
local WHISPER, HISS, MURMUR, HILT = 25028, 25031, 25034, 11706

local OTHERS = { SWORD, WHISPER, HISS, MURMUR }
local CROSSBOWS = { CROSSBOW, OFFHAND_CROSSBOW }
local function rolls(r)
    return godwars.Rolls(common.Each(CROSSBOWS, r.crossbow, common.Each(OTHERS, r.other)), HILT, r)
end

local KILL_COUNTS, MODES = common.NormalAndHard(VARS, rolls)

return {
    key = "zilyana", -- saved data key: never change it
    name = "Commander Zilyana",
    assumptions = { common.SOLO_KILLS },

    killCounts = KILL_COUNTS,
    modes = MODES,

    items = {
        [SWORD] = { log = VARS.log .. "SWORD" },
        [CROSSBOW] = { log = VARS.log .. "CROSSBOW" },
        [OFFHAND_CROSSBOW] = { log = VARS.log .. "CROSSBOW_OFFHAND" },
        [WHISPER] = { log = VARS.log .. "AMULET_MELEE" },
        [HISS] = { log = VARS.log .. "AMULET_MAGIC" },
        [MURMUR] = { log = VARS.log .. "AMULET_RANGED" },
        [HILT] = { log = VARS.log .. "HILT" },
        -- The wiki gives no rate for the hum ("very rare"), so it isn't counted.
    },
}

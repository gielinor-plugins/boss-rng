-- Helwyr, God Wars Dungeon 2. Rates: see src/bosses/godwars2.lua.

local common = require("src/bosses/common")
local godwars2 = require("src/bosses/godwars2")

local VARS = {
    kc = "BSLAY_KILLS_HELWYR",
    kcHard = "BSLAY_KILLS_HELWYR_HARDMODE",
    log = "ITEMLOG_ITEM_GWD2_SEREN_", -- each unique's log count, by its item
}

local CREST, WAND, ORB, ESSENCE = 37027, 37085, 40600, 37033
local WEAPONS = { WAND, ORB }

local KILL_COUNTS, MODES = common.NormalAndHard(
    VARS,
    godwars2.Rolls("normal", CREST, WEAPONS, ESSENCE),
    godwars2.Rolls("hard", CREST, WEAPONS, ESSENCE)
)

return {
    key = "helwyr", -- saved data key: never change it
    name = "Helwyr",
    assumptions = { common.SOLO_KILLS },

    killCounts = KILL_COUNTS,
    modes = MODES,

    items = {
        [CREST] = { log = VARS.log .. "CREST" },
        [WAND] = { log = VARS.log .. "WEAPON" },
        [ORB] = { log = VARS.log .. "WEAPON_OFFHAND" },
        [ESSENCE] = { log = VARS.log .. "ESSENCE" }, -- Serenic essence
    },
}

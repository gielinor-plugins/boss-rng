-- Gregorovic, God Wars Dungeon 2. Rates: see src/bosses/godwars2.lua.

local common = require("src/bosses/common")
local godwars2 = require("src/bosses/godwars2")

local VARS = {
    kc = "BSLAY_KILLS_SLISKE",
    kcHard = "BSLAY_KILLS_SLISKE_HARDMODE",
    log = "ITEMLOG_ITEM_GWD2_SLISKE_", -- each unique's collection log count, by its item
}

local CREST, GLAIVE, OFFHAND_GLAIVE, ESSENCE = 37021, 37075, 37080, 37031
local WEAPONS = { GLAIVE, OFFHAND_GLAIVE }

local KILL_COUNTS, MODES = common.NormalAndHard(
    VARS,
    godwars2.Rolls("normal", CREST, WEAPONS, ESSENCE),
    godwars2.Rolls("hard", CREST, WEAPONS, ESSENCE)
)

return {
    key = "gregorovic",
    name = "Gregorovic",
    assumptions = { common.SOLO_KILLS },

    killCounts = KILL_COUNTS,
    modes = MODES,

    items = {
        [CREST] = { log = VARS.log .. "CREST" },
        [GLAIVE] = { log = VARS.log .. "WEAPON" },
        [OFFHAND_GLAIVE] = { log = VARS.log .. "WEAPON_OFFHAND" },
        [ESSENCE] = { log = VARS.log .. "ESSENCE" }, -- Sliskean essence
    },
}

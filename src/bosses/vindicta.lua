-- Vindicta & Gorvek, God Wars Dungeon 2. Rates: see src/bosses/godwars2.lua.
-- Vindicta's normal mode table rolls at 1/51 over five items, so each is 1/255.

local common = require("src/bosses/common")
local godwars2 = require("src/bosses/godwars2")

local VARS = {
    kc = "BSLAY_KILLS_VINDICTA",
    kcHard = "BSLAY_KILLS_VINDICTA_HARDMODE",
    log = "ITEMLOG_ITEM_GWD2_ZAROS_", -- each unique's log count, by its item
}

local CREST, LANCE, ESSENCE = 37018, 37070, 37030
local WEAPONS = { LANCE }

return {
    key = "vindicta", -- saved data key: never change it
    name = "Vindicta & Gorvek",
    assumptions = { common.SOLO_KILLS },

    modes = common.Modes(
        VARS,
        godwars2.Rolls("normal", CREST, WEAPONS, ESSENCE),
        godwars2.Rolls("hard", CREST, WEAPONS, ESSENCE)
    ),

    items = {
        [CREST] = { log = VARS.log .. "CREST" },
        [LANCE] = { log = VARS.log .. "WEAPON" },
        [ESSENCE] = { log = VARS.log .. "ESSENCE" }, -- Zarosian essence
    },
}

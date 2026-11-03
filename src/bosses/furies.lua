-- The Twin Furies, God Wars Dungeon 2. Rates: see src/bosses/godwars2.lua.

local common = require("src/bosses/common")
local godwars2 = require("src/bosses/godwars2")

local VARS = {
    kc = "BSLAY_KILLS_TWINDEMONS",
    kcHard = "BSLAY_KILLS_TWINDEMONS_HARDMODE",
    log = "ITEMLOG_ITEM_GWD2_ZAMORAK_", -- each unique's log count, by its item
}

local CREST, NYMORA, AVARYSS, ESSENCE = 37024, 37090, 37095, 37032
local WEAPONS = { NYMORA, AVARYSS }

return {
    key = "furies", -- saved data key: never change it
    name = "The Twin Furies",
    assumptions = { common.SOLO_KILLS },

    modes = common.Modes(
        VARS,
        godwars2.Rolls("normal", CREST, WEAPONS, ESSENCE),
        godwars2.Rolls("hard", CREST, WEAPONS, ESSENCE)
    ),

    items = {
        [CREST] = { log = VARS.log .. "CREST" },
        [NYMORA] = { log = VARS.log .. "WEAPON" },
        [AVARYSS] = { log = VARS.log .. "WEAPON_OFFHAND" },
        [ESSENCE] = { log = VARS.log .. "ESSENCE" }, -- Zamorakian essence
    },
}

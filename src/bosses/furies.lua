-- The Twin Furies, God Wars Dungeon 2. Rates: see src/bosses/godwars2.lua.

local common = require("src/bosses/common")
local godwars2 = require("src/bosses/godwars2")

local CREST, NYMORA, AVARYSS, ESSENCE = 37024, 37090, 37095, 37032
local COUNTED = { CREST, NYMORA, AVARYSS } -- the boss's crest and weapons

return {
    key = "furies", -- saved data key: never change it
    name = "The Twin Furies",
    logPage = "COLLECTION_BOSS_TWINFURIES", -- the boss log page's database row
    assumptions = { common.SOLO_KILLS },

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = "BSLAY_KILLS_TWINDEMONS", rolls = godwars2.Rolls(godwars2.NORMAL, COUNTED, ESSENCE) },
        { name = "Hard mode", kc = "BSLAY_KILLS_TWINDEMONS_HARDMODE", rolls = godwars2.Rolls(godwars2.HARD, COUNTED, ESSENCE) },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = godwars2.Items({
        [CREST] = { log = "ITEMLOG_ITEM_GWD2_ZAMORAK_CREST", kind = "unique" },
        [NYMORA] = { log = "ITEMLOG_ITEM_GWD2_ZAMORAK_WEAPON", kind = "unique" },
        [AVARYSS] = { log = "ITEMLOG_ITEM_GWD2_ZAMORAK_WEAPON_OFFHAND", kind = "unique" },
        [ESSENCE] = { log = "ITEMLOG_ITEM_GWD2_ZAMORAK_ESSENCE", kind = "unique" }, -- Zamorakian essence
        [37184] = { kind = "pet" }, -- Nylessa
        [37185] = { kind = "pet" }, -- Ava
    }),
}

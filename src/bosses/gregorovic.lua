-- Gregorovic, God Wars Dungeon 2. Rates: see src/bosses/godwars2.lua.

local common = require("src/bosses/common")
local godwars2 = require("src/bosses/godwars2")

local CREST, GLAIVE, OFFHAND_GLAIVE, ESSENCE = 37021, 37075, 37080, 37031
local COUNTED = { CREST, GLAIVE, OFFHAND_GLAIVE } -- the boss's crest and weapons

return {
    key = "gregorovic", -- saved data key: never change it
    name = "Gregorovic",
    logPage = "COLLECTION_BOSS_SLISKE", -- the boss log page's database row
    assumptions = { common.SOLO_KILLS },

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = "BSLAY_KILLS_SLISKE", rolls = godwars2.Rolls(godwars2.NORMAL, COUNTED, ESSENCE) },
        { name = "Hard mode", kc = "BSLAY_KILLS_SLISKE_HARDMODE", rolls = godwars2.Rolls(godwars2.HARD, COUNTED, ESSENCE) },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = godwars2.Items({
        [CREST] = { log = "ITEMLOG_ITEM_GWD2_SLISKE_CREST", kind = "unique" },
        [GLAIVE] = { log = "ITEMLOG_ITEM_GWD2_SLISKE_WEAPON", kind = "unique" },
        [OFFHAND_GLAIVE] = { log = "ITEMLOG_ITEM_GWD2_SLISKE_WEAPON_OFFHAND", kind = "unique" },
        [ESSENCE] = { log = "ITEMLOG_ITEM_GWD2_SLISKE_ESSENCE", kind = "unique" }, -- Sliskean essence
        [37183] = { kind = "pet" }, -- Greg
    }),
}

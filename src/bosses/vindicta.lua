-- Vindicta & Gorvek, God Wars Dungeon 2. Rates: see src/bosses/godwars2.lua.

local common = require("src/bosses/common")
local godwars2 = require("src/bosses/godwars2")

local CREST, LANCE, ESSENCE = 37018, 37070, 37030
local COUNTED = { CREST, LANCE } -- the boss's crest and weapons

return {
    key = "vindicta", -- saved data key: never change it
    name = "Vindicta & Gorvek",
    logPage = "COLLECTION_BOSS_VINDICTA", -- the boss log page's database row
    assumptions = { common.SOLO_KILLS },

    -- Mode names are saved with the player's data: never change them. Vindicta's
    -- normal table rolls at 1/51 over five items, so each is 1/255.
    modes = {
        { name = "Normal", kc = "BSLAY_KILLS_VINDICTA", rolls = godwars2.Rolls({ rate = 1 / 255, essence = 1 / 64 }, COUNTED, ESSENCE) },
        { name = "Hard mode", kc = "BSLAY_KILLS_VINDICTA_HARDMODE", rolls = godwars2.Rolls(godwars2.HARD, COUNTED, ESSENCE) },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = godwars2.Items({
        [CREST] = { log = "ITEMLOG_ITEM_GWD2_ZAROS_CREST", kind = "unique" },
        [LANCE] = { log = "ITEMLOG_ITEM_GWD2_ZAROS_WEAPON", kind = "unique" },
        [ESSENCE] = { log = "ITEMLOG_ITEM_GWD2_ZAROS_ESSENCE", kind = "unique" }, -- Zarosian essence
        [37180] = { kind = "pet" }, -- Vindiddy
        [37181] = { kind = "pet" }, -- Rawrvek
    }),
}

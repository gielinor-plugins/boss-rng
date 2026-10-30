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
local COUNTED = { CREST, LANCE } -- the boss's crest and weapons
local NORMAL = { rate = 1 / 255, essence = godwars2.NORMAL.essence }

return {
    key = "vindicta", -- saved data key: never change it
    name = "Vindicta & Gorvek",
    logPage = "COLLECTION_BOSS_VINDICTA", -- the boss log page's database row
    assumptions = { common.SOLO_KILLS },

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = VARS.kc, rolls = godwars2.Rolls(NORMAL, COUNTED, ESSENCE) },
        { name = "Hard mode", kc = VARS.kcHard, rolls = godwars2.Rolls(godwars2.HARD, COUNTED, ESSENCE) },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = godwars2.Items({
        [CREST] = { log = VARS.log .. "CREST", kind = "unique" },
        [LANCE] = { log = VARS.log .. "WEAPON", kind = "unique" },
        [ESSENCE] = { log = VARS.log .. "ESSENCE", kind = "unique" }, -- Zarosian essence
        [37180] = { kind = "pet" }, -- Vindiddy
        [37181] = { kind = "pet" }, -- Rawrvek
    }),
}

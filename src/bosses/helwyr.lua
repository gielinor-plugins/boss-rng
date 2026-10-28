-- Helwyr, God Wars Dungeon 2. Rates: see src/bosses/godwars2.lua.

local common = require("src/bosses/common")
local godwars2 = require("src/bosses/godwars2")

local CREST, WAND, ORB, ESSENCE = 37027, 37085, 40600, 37033
local COUNTED = { CREST, WAND, ORB } -- the boss's crest and weapons

return {
    key = "helwyr", -- saved data key: never change it
    name = "Helwyr",
    logPage = "COLLECTION_BOSS_HELWYR", -- the boss log page's database row
    assumptions = { common.SOLO_KILLS },

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = "BSLAY_KILLS_HELWYR", rolls = godwars2.Rolls(godwars2.NORMAL, COUNTED, ESSENCE) },
        { name = "Hard mode", kc = "BSLAY_KILLS_HELWYR_HARDMODE", rolls = godwars2.Rolls(godwars2.HARD, COUNTED, ESSENCE) },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = godwars2.Items({
        [CREST] = { log = "ITEMLOG_ITEM_GWD2_SEREN_CREST", kind = "unique" },
        [WAND] = { log = "ITEMLOG_ITEM_GWD2_SEREN_WEAPON", kind = "unique" },
        [ORB] = { log = "ITEMLOG_ITEM_GWD2_SEREN_WEAPON_OFFHAND", kind = "unique" },
        [ESSENCE] = { log = "ITEMLOG_ITEM_GWD2_SEREN_ESSENCE", kind = "unique" }, -- Serenic essence
        [37182] = { kind = "pet" }, -- Lilwyr
    }),
}

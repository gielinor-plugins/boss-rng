-- K'ril Tsutsaroth, God Wars Dungeon. Rates: see src/bosses/godwars.lua. His
-- unique table has eight entries at 1/8 each: the six subjugation pieces, the
-- spear and the steam battlestaff. The wiki's K'ril page doesn't say how the
-- hilt is rolled, so like Kree'arra's it's assumed to work as the other
-- generals' do.

local godwars = require("src/bosses/godwars")

local HOOD, GARB, GOWN, GLOVES, BOOTS, WARD = 24992, 24995, 24998, 25007, 25004, 25001
local SPEAR, STAFF, HILT = 11716, 11736, 11708

local ROLLS = godwars.Rolls(godwars.Even({ HOOD, GARB, GOWN, GLOVES, BOOTS, WARD, SPEAR, STAFF }), HILT)

return {
    key = "kril", -- saved data key: never change it
    name = "K'ril Tsutsaroth",
    logPage = "COLLECTION_BOSS_KRIL", -- the boss log page's database row
    assumptions = { godwars.SOLO_KILLS },

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = "BSLAY_KILLS_GWD_KRIL", rolls = ROLLS },
        { name = "Hard mode", kc = "BSLAY_KILLS_GWD_KRIL_HARDMODE", rolls = ROLLS },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [HOOD] = { log = "ITEMLOG_ITEM_GWD_ZAMORAK_HEAD", kind = "unique" },
        [GARB] = { log = "ITEMLOG_ITEM_GWD_ZAMORAK_BODY", kind = "unique" },
        [GOWN] = { log = "ITEMLOG_ITEM_GWD_ZAMORAK_LEGS", kind = "unique" },
        [GLOVES] = { log = "ITEMLOG_ITEM_GWD_ZAMORAK_HANDS", kind = "unique" },
        [BOOTS] = { log = "ITEMLOG_ITEM_GWD_ZAMORAK_FEET", kind = "unique" },
        [WARD] = { log = "ITEMLOG_ITEM_GWD_ZAMORAK_SHIELD", kind = "unique" },
        [SPEAR] = { log = "ITEMLOG_ITEM_GWD_ZAMORAK_SPEAR", kind = "unique" },
        [STAFF] = { log = "ITEMLOG_ITEM_GWD_STEAM_BATTLESTAFF", kind = "unique" },
        [HILT] = { log = "ITEMLOG_ITEM_GWD_ZAMORAK_HILT", kind = "unique" },

        -- Godsword shards come from a table shared by the God Wars bosses.
        [11710] = { log = "ITEMLOG_ITEM_GWD_SHARD1", kind = "shared" },
        [11712] = { log = "ITEMLOG_ITEM_GWD_SHARD2", kind = "shared" },
        [11714] = { log = "ITEMLOG_ITEM_GWD_SHARD3", kind = "shared" },

        -- Warpriest of Zamorak also drops from the bodyguards and other Zamorak monsters.
        [28785] = { log = "ITEMLOG_ITEM_WARPRIEST_ZAMORAK_HELM", kind = "shared" },
        [28788] = { log = "ITEMLOG_ITEM_WARPRIEST_ZAMORAK_CAPE", kind = "shared" },
        [28779] = { log = "ITEMLOG_ITEM_WARPRIEST_ZAMORAK_BODY", kind = "shared" },
        [28782] = { log = "ITEMLOG_ITEM_WARPRIEST_ZAMORAK_LEGS", kind = "shared" },
        [28773] = { log = "ITEMLOG_ITEM_WARPRIEST_ZAMORAK_GLOVES", kind = "shared" },
        [28776] = { log = "ITEMLOG_ITEM_WARPRIEST_ZAMORAK_BOOTS", kind = "shared" },

        [25041] = { kind = "lore" }, -- Razulei's Tale
        [33805] = { kind = "pet" }, -- K'ril Tinyroth
    },
}

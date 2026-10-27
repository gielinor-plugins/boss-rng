-- General Graardor, God Wars Dungeon. Rates: see src/bosses/godwars.lua.

local godwars = require("src/bosses/godwars")

local HELMET, CHESTPLATE, TASSETS = 25022, 11724, 11726
local GLOVES, BOOTS, WARSHIELD, HILT = 25025, 11728, 25019, 11704

local ROLLS = godwars.Rolls({ HELMET, CHESTPLATE, TASSETS, GLOVES, BOOTS, WARSHIELD }, HILT)

return {
    key = "graardor", -- saved data key: never change it
    name = "General Graardor",
    logPage = "COLLECTION_BOSS_GRAARDOR", -- the boss log page's database row

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = "BSLAY_KILLS_GWD_GRAARDOR", rolls = ROLLS },
        { name = "Hard mode", kc = "BSLAY_KILLS_GWD_GRAARDOR_HARDMODE", rolls = ROLLS },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [HELMET] = { log = "ITEMLOG_ITEM_GWD_BANDOS_HEAD", kind = "unique" },
        [CHESTPLATE] = { log = "ITEMLOG_ITEM_GWD_BANDOS_BODY", kind = "unique" },
        [TASSETS] = { log = "ITEMLOG_ITEM_GWD_BANDOS_LEGS", kind = "unique" },
        [GLOVES] = { log = "ITEMLOG_ITEM_GWD_BANDOS_HANDS", kind = "unique" },
        [BOOTS] = { log = "ITEMLOG_ITEM_GWD_BANDOS_FEET", kind = "unique" },
        [WARSHIELD] = { log = "ITEMLOG_ITEM_GWD_BANDOS_SHIELD", kind = "unique" },
        [HILT] = { log = "ITEMLOG_ITEM_GWD_BANDOS_HILT", kind = "unique" },

        -- Godsword shards come from a table shared by the God Wars bosses.
        [11710] = { log = "ITEMLOG_ITEM_GWD_SHARD1", kind = "shared" },
        [11712] = { log = "ITEMLOG_ITEM_GWD_SHARD2", kind = "shared" },
        [11714] = { log = "ITEMLOG_ITEM_GWD_SHARD3", kind = "shared" },

        -- Warpriest of Bandos also drops from the bodyguards and other Bandos monsters.
        [30318] = { log = "ITEMLOG_ITEM_WARPRIEST_BANDOS_HELM", kind = "shared" },
        [30321] = { log = "ITEMLOG_ITEM_WARPRIEST_BANDOS_CAPE", kind = "shared" },
        [30312] = { log = "ITEMLOG_ITEM_WARPRIEST_BANDOS_BODY", kind = "shared" },
        [30315] = { log = "ITEMLOG_ITEM_WARPRIEST_BANDOS_LEGS", kind = "shared" },
        [30306] = { log = "ITEMLOG_ITEM_WARPRIEST_BANDOS_GLOVES", kind = "shared" },
        [30309] = { log = "ITEMLOG_ITEM_WARPRIEST_BANDOS_BOOTS", kind = "shared" },

        [25042] = { kind = "lore" }, -- The Glory of General Graardor
        [33806] = { kind = "pet" }, -- General Awwdor
    },
}

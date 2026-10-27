-- Commander Zilyana, God Wars Dungeon. Rates: see src/bosses/godwars.lua. Her
-- unique table has five entries at 1/5 each: the sword, an Armadyl crossbow (the
-- main hand and off-hand split that entry evenly), and three of her amulets.

local godwars = require("src/bosses/godwars")

local SWORD, CROSSBOW, OFFHAND_CROSSBOW = 11730, 25037, 34855
local WHISPER, HISS, MURMUR, HUM, HILT = 25028, 25031, 25034, 61117, 11706

local ROLLS = godwars.Rolls({
    [SWORD] = 2,
    [CROSSBOW] = 1,
    [OFFHAND_CROSSBOW] = 1,
    [WHISPER] = 2,
    [HISS] = 2,
    [MURMUR] = 2,
}, HILT)

return {
    key = "zilyana", -- saved data key: never change it
    name = "Commander Zilyana",
    logPage = "COLLECTION_BOSS_ZILYANA", -- the boss log page's database row

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = "BSLAY_KILLS_GWD_ZILYANA", rolls = ROLLS },
        { name = "Hard mode", kc = "BSLAY_KILLS_GWD_ZILYANA_HARDMODE", rolls = ROLLS },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [SWORD] = { log = "ITEMLOG_ITEM_GWD_SARA_SWORD", kind = "unique" },
        [CROSSBOW] = { log = "ITEMLOG_ITEM_GWD_SARA_CROSSBOW", kind = "unique" },
        [OFFHAND_CROSSBOW] = { log = "ITEMLOG_ITEM_GWD_SARA_CROSSBOW_OFFHAND", kind = "unique" },
        [WHISPER] = { log = "ITEMLOG_ITEM_GWD_SARA_AMULET_MELEE", kind = "unique" },
        [HISS] = { log = "ITEMLOG_ITEM_GWD_SARA_AMULET_MAGIC", kind = "unique" },
        [MURMUR] = { log = "ITEMLOG_ITEM_GWD_SARA_AMULET_RANGED", kind = "unique" },
        [HILT] = { log = "ITEMLOG_ITEM_GWD_SARA_HILT", kind = "unique" },
        -- The wiki gives no rate for the hum ("very rare"), so it isn't counted.
        [HUM] = { log = "ITEMLOG_ITEM_GWD_SARA_AMULET_NECROMANCY", kind = "excluded" },

        -- Godsword shards come from a table shared by the God Wars bosses.
        [11710] = { log = "ITEMLOG_ITEM_GWD_SHARD1", kind = "shared" },
        [11712] = { log = "ITEMLOG_ITEM_GWD_SHARD2", kind = "shared" },
        [11714] = { log = "ITEMLOG_ITEM_GWD_SHARD3", kind = "shared" },

        -- Warpriest of Saradomin also drops from the bodyguards and other Saradomin monsters.
        [28767] = { log = "ITEMLOG_ITEM_WARPRIEST_SARA_HELM", kind = "shared" },
        [28770] = { log = "ITEMLOG_ITEM_WARPRIEST_SARA_CAPE", kind = "shared" },
        [28761] = { log = "ITEMLOG_ITEM_WARPRIEST_SARA_BODY", kind = "shared" },
        [28764] = { log = "ITEMLOG_ITEM_WARPRIEST_SARA_LEGS", kind = "shared" },
        [28755] = { log = "ITEMLOG_ITEM_WARPRIEST_SARA_GLOVES", kind = "shared" },
        [28758] = { log = "ITEMLOG_ITEM_WARPRIEST_SARA_BOOTS", kind = "shared" },

        [25040] = { kind = "lore" }, -- Zilyana's Notes
        [33807] = { kind = "pet" }, -- Commander Miniana
    },
}

-- Kree'arra, God Wars Dungeon.
-- Rates from the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-27.
-- Hard mode has the same rates for these uniques. The wiki doesn't say whether the
-- hilt shares a roll with the armor, so it is its own roll here.

local HELMET, CHESTPLATE, CHAINSKIRT = 11718, 11720, 11722
local GLOVES, BOOTS, BUCKLER, HILT = 25016, 25010, 25013, 11702

local ROLLS = {
    -- 1/64 to reach the unique table, then 1/6 per item: 1/384 each.
    { chance = 1 / 64, items = { [HELMET] = 1, [CHESTPLATE] = 1, [CHAINSKIRT] = 1,
                                 [GLOVES] = 1, [BOOTS] = 1, [BUCKLER] = 1 } },
    { chance = 1 / 512, items = { [HILT] = 1 } },
}

return {
    key = "kreearra", -- saved data key: never change it
    name = "Kree'arra",
    logPage = "COLLECTION_BOSS_KREEARRA", -- the boss log page's database row

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = "BSLAY_KILLS_GWD_KREEARRA", rolls = ROLLS },
        { name = "Hard mode", kc = "BSLAY_KILLS_GWD_KREEARRA_HARDMODE", rolls = ROLLS },
    },

    -- Every item on the boss log page, with its log count varbit and kind:
    --   unique  counted in luck
    --   shared  its log count includes drops from other monsters, so not counted
    --   lore, pet  not counted (no log count varbit found for these)
    items = {
        [HELMET] = { log = "ITEMLOG_ITEM_GWD_ARMADYL_HEAD", kind = "unique" },
        [CHESTPLATE] = { log = "ITEMLOG_ITEM_GWD_ARMADYL_BODY", kind = "unique" },
        [CHAINSKIRT] = { log = "ITEMLOG_ITEM_GWD_ARMADYL_LEGS", kind = "unique" },
        [GLOVES] = { log = "ITEMLOG_ITEM_GWD_ARMADYL_HANDS", kind = "unique" },
        [BOOTS] = { log = "ITEMLOG_ITEM_GWD_ARMADYL_FEET", kind = "unique" },
        [BUCKLER] = { log = "ITEMLOG_ITEM_GWD_ARMADYL_SHIELD", kind = "unique" },
        [HILT] = { log = "ITEMLOG_ITEM_GWD_ARMADYL_HILT", kind = "unique" },

        -- Godsword shards come from a table shared by the God Wars bosses.
        [11710] = { log = "ITEMLOG_ITEM_GWD_SHARD1", kind = "shared" },
        [11712] = { log = "ITEMLOG_ITEM_GWD_SHARD2", kind = "shared" },
        [11714] = { log = "ITEMLOG_ITEM_GWD_SHARD3", kind = "shared" },

        -- Warpriest of Armadyl also drops from the bodyguards and other Armadyl monsters.
        [30300] = { log = "ITEMLOG_ITEM_WARPRIEST_ARMADYL_HELM", kind = "shared" },
        [30303] = { log = "ITEMLOG_ITEM_WARPRIEST_ARMADYL_CAPE", kind = "shared" },
        [30294] = { log = "ITEMLOG_ITEM_WARPRIEST_ARMADYL_BODY", kind = "shared" },
        [30297] = { log = "ITEMLOG_ITEM_WARPRIEST_ARMADYL_LEGS", kind = "shared" },
        [30288] = { log = "ITEMLOG_ITEM_WARPRIEST_ARMADYL_GLOVES", kind = "shared" },
        [30291] = { log = "ITEMLOG_ITEM_WARPRIEST_ARMADYL_BOOTS", kind = "shared" },

        [25043] = { kind = "lore" }, -- Armadyl lore book
        [33804] = { kind = "pet" }, -- Chick'arra
    },
}

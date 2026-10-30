-- Nex, God Wars Dungeon (not Nex: Angel of Death, which has its own page).
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-27: a 6/128 chance
-- per kill of her unique table, and every one of its 18 items is listed at 1/384.
-- 6/128 split evenly over 18 gives exactly that, so the table is taken to pick
-- one item at random (inferred from the rates; the wiki doesn't say so).

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_GWD_NEX",
    log = "ITEMLOG_ITEM_GWD_NEX_", -- each unique's log count, by its piece
}

local TORVA_HELM, TORVA_BODY, TORVA_LEGS, TORVA_GLOVES, TORVA_BOOTS = 20135, 20139, 20143, 25060, 25064
local PERNIX_COWL, PERNIX_BODY, PERNIX_CHAPS, PERNIX_GLOVES, PERNIX_BOOTS = 20147, 20151, 20155, 25058, 25068
local VIRTUS_MASK, VIRTUS_TOP, VIRTUS_LEGS, VIRTUS_GLOVES, VIRTUS_BOOTS = 20159, 20163, 20167, 25062, 25066
local VIRTUS_BOOK, VIRTUS_WAND, ZARYTE_BOW = 25664, 25654, 20171

local ROLLS = {
    {
        chance = 6 / 128,
        items = common.Even({
            TORVA_HELM, TORVA_BODY, TORVA_LEGS, TORVA_GLOVES, TORVA_BOOTS,
            PERNIX_COWL, PERNIX_BODY, PERNIX_CHAPS, PERNIX_GLOVES, PERNIX_BOOTS,
            VIRTUS_MASK, VIRTUS_TOP, VIRTUS_LEGS, VIRTUS_GLOVES, VIRTUS_BOOTS,
            VIRTUS_BOOK, VIRTUS_WAND, ZARYTE_BOW,
        }),
    },
}

return {
    key = "nex", -- saved data key: never change it
    name = "Nex",
    logPage = "COLLECTION_BOSS_NEX", -- the boss log page's database row
    assumptions = { common.SOLO_KILLS },

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = VARS.kc, rolls = ROLLS },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [TORVA_HELM] = { log = VARS.log .. "HEAD_MELEE", kind = "unique" },
        [TORVA_BODY] = { log = VARS.log .. "BODY_MELEE", kind = "unique" },
        [TORVA_LEGS] = { log = VARS.log .. "LEGS_MELEE", kind = "unique" },
        [TORVA_GLOVES] = { log = VARS.log .. "HANDS_MELEE", kind = "unique" },
        [TORVA_BOOTS] = { log = VARS.log .. "FEET_MELEE", kind = "unique" },
        [PERNIX_COWL] = { log = VARS.log .. "HEAD_RANGED", kind = "unique" },
        [PERNIX_BODY] = { log = VARS.log .. "BODY_RANGED", kind = "unique" },
        [PERNIX_CHAPS] = { log = VARS.log .. "LEGS_RANGED", kind = "unique" },
        [PERNIX_GLOVES] = { log = VARS.log .. "HANDS_RANGED", kind = "unique" },
        [PERNIX_BOOTS] = { log = VARS.log .. "FEET_RANGED", kind = "unique" },
        [VIRTUS_MASK] = { log = VARS.log .. "HEAD_MAGIC", kind = "unique" },
        [VIRTUS_TOP] = { log = VARS.log .. "BODY_MAGIC", kind = "unique" },
        [VIRTUS_LEGS] = { log = VARS.log .. "LEGS_MAGIC", kind = "unique" },
        [VIRTUS_GLOVES] = { log = VARS.log .. "HANDS_MAGIC", kind = "unique" },
        [VIRTUS_BOOTS] = { log = VARS.log .. "FEET_MAGIC", kind = "unique" },
        [VIRTUS_BOOK] = { log = VARS.log .. "BOOK", kind = "unique" },
        [VIRTUS_WAND] = { log = VARS.log .. "WAND", kind = "unique" },
        [ZARYTE_BOW] = { log = VARS.log .. "BOW", kind = "unique" },

        -- Only drops to players carrying a tier 70+ defender, so it isn't counted.
        [36159] = { kind = "excluded" }, -- Ancient emblem
        [25044] = { kind = "lore" }, -- Nex's Followers
        [33808] = { kind = "pet" }, -- Nexterminator
    },
}

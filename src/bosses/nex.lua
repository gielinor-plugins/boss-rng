-- Nex (not Nex: Angel of Death). Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked
-- 2026-10-27. All 18 items are 1/384, so the table is inferred to pick one evenly.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_GWD_NEX",
    log = "ITEMLOG_ITEM_GWD_NEX_", -- each unique's log count, by its piece
}

local TORVA_HELM, TORVA_BODY, TORVA_LEGS, TORVA_GLOVES, TORVA_BOOTS = 20135, 20139, 20143, 25060, 25064
local PERNIX_COWL, PERNIX_BODY, PERNIX_CHAPS, PERNIX_GLOVES, PERNIX_BOOTS = 20147, 20151, 20155, 25058, 25068
local VIRTUS_MASK, VIRTUS_TOP, VIRTUS_LEGS, VIRTUS_GLOVES, VIRTUS_BOOTS = 20159, 20163, 20167, 25062, 25066
local VIRTUS_BOOK, VIRTUS_WAND, ZARYTE_BOW = 25664, 25654, 20171

local UNIQUES = common.Even({
    TORVA_HELM, TORVA_BODY, TORVA_LEGS, TORVA_GLOVES, TORVA_BOOTS,
    PERNIX_COWL, PERNIX_BODY, PERNIX_CHAPS, PERNIX_GLOVES, PERNIX_BOOTS,
    VIRTUS_MASK, VIRTUS_TOP, VIRTUS_LEGS, VIRTUS_GLOVES, VIRTUS_BOOTS,
    VIRTUS_BOOK, VIRTUS_WAND, ZARYTE_BOW,
})

local function rolls(r)
    return { { chance = r.table, items = UNIQUES } }
end

return {
    key = "nex", -- saved data key: never change it
    name = "Nex",
    assumptions = { common.SOLO_KILLS },

    -- Mode keys are saved: never change them.
    modes = {
        { key = "n", kc = VARS.kc, rolls = rolls },
    },

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

        -- Only drops with a tier 70+ defender, so it isn't counted.
        [36159] = { kind = "excluded" }, -- Ancient emblem
        [25044] = { kind = "lore" }, -- Nex's Followers
        [33808] = { kind = "pet" }, -- Nexterminator
    },
}

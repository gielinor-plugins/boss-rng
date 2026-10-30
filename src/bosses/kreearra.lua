-- Kree'arra, God Wars Dungeon. Rates: see src/bosses/godwars.lua. The wiki's
-- Kree'arra page doesn't say how its hilt is rolled; Graardor's and Zilyana's
-- pages say the hilt is only rolled when the armor roll misses, and the generals
-- share one drop system, so Kree'arra is assumed to work the same way.

local common = require("src/bosses/common")
local godwars = require("src/bosses/godwars")

local VARS = {
    kc = "BSLAY_KILLS_GWD_KREEARRA",
    kcHard = "BSLAY_KILLS_GWD_KREEARRA_HARDMODE",
    log = "ITEMLOG_ITEM_GWD_ARMADYL_", -- each unique's log count, by its piece
    warpriest = "ITEMLOG_ITEM_WARPRIEST_ARMADYL_", -- the Warpriest set's log counts
}

local HELMET, CHESTPLATE, CHAINSKIRT = 11718, 11720, 11722
local GLOVES, BOOTS, BUCKLER, HILT = 25016, 25010, 25013, 11702

local ARMOR = { HELMET, CHESTPLATE, CHAINSKIRT, GLOVES, BOOTS, BUCKLER }
-- A kill's rolls at rate values r (see src/rates/base.lua).
local function rolls(r)
    return godwars.Rolls(common.Each(ARMOR, r.armor), HILT, r)
end

return {
    key = "kreearra", -- saved data key: never change it
    name = "Kree'arra",
    logPage = "COLLECTION_BOSS_KREEARRA", -- the boss log page's database row
    assumptions = { common.SOLO_KILLS },

    modes = common.Modes(VARS, rolls),

    -- Every item on the boss log page, with its log count varbit and kind:
    --   unique  counted in luck
    --   shared  its log count includes drops from other monsters, so not counted
    --   lore, pet  not counted (no log count varbit found for these)
    --   excluded  on the page but not counted, e.g. no published drop rate
    items = godwars.Items({
        [HELMET] = { log = VARS.log .. "HEAD", kind = "unique" },
        [CHESTPLATE] = { log = VARS.log .. "BODY", kind = "unique" },
        [CHAINSKIRT] = { log = VARS.log .. "LEGS", kind = "unique" },
        [GLOVES] = { log = VARS.log .. "HANDS", kind = "unique" },
        [BOOTS] = { log = VARS.log .. "FEET", kind = "unique" },
        [BUCKLER] = { log = VARS.log .. "SHIELD", kind = "unique" },
        [HILT] = { log = VARS.log .. "HILT", kind = "unique" },
        [25043] = { kind = "lore" }, -- Armadyl lore book
        [33804] = { kind = "pet" }, -- Chick'arra
    }, VARS.warpriest, { HELM = 30300, CAPE = 30303, BODY = 30294, LEGS = 30297, GLOVES = 30288, BOOTS = 30291 }),
}

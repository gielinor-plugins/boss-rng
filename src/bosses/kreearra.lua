-- Kree'arra, God Wars Dungeon. Rates: see src/bosses/godwars.lua. The wiki doesn't say
-- how its hilt rolls; the generals share one drop system, so it's assumed the same.

local common = require("src/bosses/common")
local godwars = require("src/bosses/godwars")

local VARS = {
    kc = "BSLAY_KILLS_GWD_KREEARRA",
    kcHard = "BSLAY_KILLS_GWD_KREEARRA_HARDMODE",
    log = "ITEMLOG_ITEM_GWD_ARMADYL_", -- each unique's log count, by its piece
}

local HELMET, CHESTPLATE, CHAINSKIRT = 11718, 11720, 11722
local GLOVES, BOOTS, BUCKLER, HILT = 25016, 25010, 25013, 11702

local ARMOR = { HELMET, CHESTPLATE, CHAINSKIRT, GLOVES, BOOTS, BUCKLER }
local function rolls(r)
    return godwars.Rolls(common.Each(ARMOR, r.armor), HILT, r)
end

return {
    key = "kreearra", -- saved data key: never change it
    name = "Kree'arra",
    assumptions = { common.SOLO_KILLS },

    modes = common.Modes(VARS, rolls),

    items = {
        [HELMET] = { log = VARS.log .. "HEAD" },
        [CHESTPLATE] = { log = VARS.log .. "BODY" },
        [CHAINSKIRT] = { log = VARS.log .. "LEGS" },
        [GLOVES] = { log = VARS.log .. "HANDS" },
        [BOOTS] = { log = VARS.log .. "FEET" },
        [BUCKLER] = { log = VARS.log .. "SHIELD" },
        [HILT] = { log = VARS.log .. "HILT" },
    },
}

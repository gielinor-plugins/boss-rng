-- General Graardor, God Wars Dungeon. Rates: see src/bosses/godwars.lua.

local common = require("src/bosses/common")
local godwars = require("src/bosses/godwars")

local VARS = {
    kc = "BSLAY_KILLS_GWD_GRAARDOR",
    kcHard = "BSLAY_KILLS_GWD_GRAARDOR_HARDMODE",
    log = "ITEMLOG_ITEM_GWD_BANDOS_", -- each unique's log count, by its piece
}

local HELMET, CHESTPLATE, TASSETS = 25022, 11724, 11726
local GLOVES, BOOTS, WARSHIELD, HILT = 25025, 11728, 25019, 11704

local ARMOR = { HELMET, CHESTPLATE, TASSETS, GLOVES, BOOTS, WARSHIELD }
local function rolls(r)
    return godwars.Rolls(common.Each(ARMOR, r.armor), HILT, r)
end

return {
    key = "graardor", -- saved data key: never change it
    name = "General Graardor",
    assumptions = { common.SOLO_KILLS },

    modes = common.Modes(VARS, rolls),

    items = {
        [HELMET] = { log = VARS.log .. "HEAD" },
        [CHESTPLATE] = { log = VARS.log .. "BODY" },
        [TASSETS] = { log = VARS.log .. "LEGS" },
        [GLOVES] = { log = VARS.log .. "HANDS" },
        [BOOTS] = { log = VARS.log .. "FEET" },
        [WARSHIELD] = { log = VARS.log .. "SHIELD" },
        [HILT] = { log = VARS.log .. "HILT" },
    },
}

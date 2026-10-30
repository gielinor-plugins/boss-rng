-- General Graardor, God Wars Dungeon. Rates: see src/bosses/godwars.lua.

local common = require("src/bosses/common")
local godwars = require("src/bosses/godwars")

local VARS = {
    kc = "BSLAY_KILLS_GWD_GRAARDOR",
    kcHard = "BSLAY_KILLS_GWD_GRAARDOR_HARDMODE",
    log = "ITEMLOG_ITEM_GWD_BANDOS_", -- each unique's log count, by its piece
    warpriest = "ITEMLOG_ITEM_WARPRIEST_BANDOS_", -- the Warpriest set's log counts
}

local HELMET, CHESTPLATE, TASSETS = 25022, 11724, 11726
local GLOVES, BOOTS, WARSHIELD, HILT = 25025, 11728, 25019, 11704

local ARMOR = { HELMET, CHESTPLATE, TASSETS, GLOVES, BOOTS, WARSHIELD }
-- Chances per kill, before and after the Late-Game Rebalance.
local RATES = godwars.Rates({ armor = 1 / 384 }, { armor = 1 / 320 })

local function rolls(_, r)
    return godwars.Rolls(common.Each(ARMOR, r.armor), HILT, r)
end

return {
    key = "graardor", -- saved data key: never change it
    name = "General Graardor",
    logPage = "COLLECTION_BOSS_GRAARDOR", -- the boss log page's database row
    assumptions = { common.SOLO_KILLS },
    rates = RATES,

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = VARS.kc, rolls = rolls },
        { name = "Hard mode", kc = VARS.kcHard, rolls = rolls },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = godwars.Items({
        [HELMET] = { log = VARS.log .. "HEAD", kind = "unique" },
        [CHESTPLATE] = { log = VARS.log .. "BODY", kind = "unique" },
        [TASSETS] = { log = VARS.log .. "LEGS", kind = "unique" },
        [GLOVES] = { log = VARS.log .. "HANDS", kind = "unique" },
        [BOOTS] = { log = VARS.log .. "FEET", kind = "unique" },
        [WARSHIELD] = { log = VARS.log .. "SHIELD", kind = "unique" },
        [HILT] = { log = VARS.log .. "HILT", kind = "unique" },
        [25042] = { kind = "lore" }, -- The Glory of General Graardor
        [33806] = { kind = "pet" }, -- General Awwdor
    }, VARS.warpriest, { HELM = 30318, CAPE = 30321, BODY = 30312, LEGS = 30315, GLOVES = 30306, BOOTS = 30309 }),
}

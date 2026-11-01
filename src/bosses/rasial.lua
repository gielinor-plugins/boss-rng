-- Rasial. A solo fight. Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-29.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_RASIAL_BOSS",
    log = "ITEMLOG_ITEM_NECRO_RASIAL_", -- each unique's log count, by its piece
}

local GUARD, LANTERN = 55480, 55482
local CROWN, TOP, BOTTOM, HANDS, FEET = 55488, 55490, 55492, 55494, 55496
local WEAPONS = common.Even({ GUARD, LANTERN })
local ARMOR = common.Even({ CROWN, TOP, BOTTOM, HANDS, FEET })

local function rolls(r)
    return {
        { chance = r.weapon, items = WEAPONS },
        { chance = r.armor, items = ARMOR },
    }
end

return {
    key = "rasial", -- saved data key: never change it
    name = "Rasial, the First Necromancer",
    assumptions = {},

    -- Mode names are saved: never change them.
    modes = {
        { name = "Normal", kc = VARS.kc, rolls = rolls },
    },

    items = {
        [GUARD] = { log = VARS.log .. "ARMGUARD_T95", kind = "unique" },
        [LANTERN] = { log = VARS.log .. "LANTERN_T95", kind = "unique" },
        [CROWN] = { log = VARS.log .. "HEAD_T95", kind = "unique" },
        [TOP] = { log = VARS.log .. "BODY_T95", kind = "unique" },
        [BOTTOM] = { log = VARS.log .. "LEGS_T95", kind = "unique" },
        [HANDS] = { log = VARS.log .. "HANDS_T95", kind = "unique" },
        [FEET] = { log = VARS.log .. "FEET_T95", kind = "unique" },
        [55672] = { kind = "pet" }, -- Miso
    },
}

-- Rise of the Six. Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28. Every
-- player gets their own chest and rolls.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_BARROWSROTS", -- goes up at the kill, looted or not
    log = "ITEMLOG_ITEM_ROTS_", -- each item's log count, by its name
}

local MALEVOLENT, MERCILESS, VENGEFUL = 30014, 30022, 30018 -- magic, melee and ranged
local UNIQUES = common.Even({ MALEVOLENT, MERCILESS, VENGEFUL })

local function rolls(r)
    return { { chance = r.table, items = UNIQUES } }
end

return {
    key = "rots", -- saved data key: never change it
    name = "Barrows: Rise of the Six",
    -- The kill count can go up without the chest being looted.
    assumptions = { "Every chest looted" },

    -- Mode keys are saved: never change them.
    modes = {
        { key = "n", kc = VARS.kc, rolls = rolls },
    },

    items = {
        [MALEVOLENT] = { log = VARS.log .. "SHIELD_MAGIC", kind = "unique" },
        [MERCILESS] = { log = VARS.log .. "SHIELD_MELEE", kind = "unique" },
        [VENGEFUL] = { log = VARS.log .. "SHIELD_RANGED", kind = "unique" },
        [30027] = { log = VARS.log .. "ENERGY", kind = "excluded" }, -- Malevolent energy: guaranteed
        -- The brothers' bobbleheads: cosmetic unlocks.
        [38935] = { kind = "excluded" }, -- Ahrim
        [30032] = { kind = "excluded" }, -- Dharok
        [38937] = { kind = "excluded" }, -- Guthan
        [38938] = { kind = "excluded" }, -- Karil
        [38939] = { kind = "excluded" }, -- Torag
        [38940] = { kind = "excluded" }, -- Verac
    },
}

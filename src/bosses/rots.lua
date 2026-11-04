-- Rise of the Six. Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28. Every
-- player gets their own chest and rolls.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_BARROWSROTS", -- goes up at the kill, looted or not
    log = "ITEMLOG_ITEM_ROTS_", -- each item's collection log count, by its name
}

local MALEVOLENT, MERCILESS, VENGEFUL = 30014, 30022, 30018 -- magic, melee and ranged
local UNIQUES = common.Even({ MALEVOLENT, MERCILESS, VENGEFUL })

local function rolls(r)
    return { { chance = r.table, items = UNIQUES } }
end

local KILL_COUNTS, MODES = common.OneMode(VARS.kc, rolls)

return {
    key = "rots",
    name = "Barrows: Rise of the Six",
    -- The kill count can go up without the chest being looted.
    assumptions = { "Every chest looted" },

    killCounts = KILL_COUNTS,
    modes = MODES,

    items = {
        [MALEVOLENT] = { log = VARS.log .. "SHIELD_MAGIC" },
        [MERCILESS] = { log = VARS.log .. "SHIELD_MELEE" },
        [VENGEFUL] = { log = VARS.log .. "SHIELD_RANGED" },
    },
}

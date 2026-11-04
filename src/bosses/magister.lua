-- The Magister. A solo fight. Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked
-- 2026-10-31. A Phylactery is one item a drop, so its log count is its drops.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_MENAPHOS_SLAYER_BOSS",
    log = "ITEMLOG_ITEM_MAGISTER_", -- each unique's log count, by its name
}

local PHYLACTERY, GLOVES = 40650, 40320

local function rolls(r)
    return {
        { chance = r.phylactery, items = { [PHYLACTERY] = 1 } },
        { chance = r.gloves, items = { [GLOVES] = 1 } },
    }
end

local KILL_COUNTS, MODES = common.OneMode(VARS.kc, rolls)

return {
    key = "magister", -- saved data key: never change it
    name = "The Magister",
    assumptions = {},

    killCounts = KILL_COUNTS,
    modes = MODES,

    items = {
        [PHYLACTERY] = { log = VARS.log .. "PHYLACTERY" },
        [GLOVES] = { log = VARS.log .. "HANDS" },
    },
}

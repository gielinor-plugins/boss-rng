-- Gate of Elidinis. Rates: Jagex's "Gate of Elidinis Drop Rates" via the RuneScape Wiki
-- (CC BY-NC-SA 3.0), checked 2026-10-31. Each Offering is one drop, so its log count is
-- its drops. The rebalanced
-- rares are taken as still one roll. Nearly every kill is solo, so solo is assumed.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_ELIDINIS_BOSS",
    log = "ITEMLOG_ITEM_ELIDINIS_BOSS_", -- each unique's log count, by its name
    codex = "ITEMLOG_ITEM_COMBATV2_PRAYER_CODEX_ECLIPSED_SOUL",
}

local ATTUNER, DOWSER, SCRIPTURE, CODEX, OFFERING = 57519, 57521, 57524, 57544, 57528
local RARES = { ATTUNER, DOWSER, SCRIPTURE, CODEX }

local function rolls(r)
    return {
        common.OneOf(common.Each(RARES, r.rare)),
        { chance = r.offering, items = { [OFFERING] = 1 } },
    }
end

local KILL_COUNTS, MODES = common.OneMode(VARS.kc, rolls)

return {
    key = "elidinis", -- saved data key: never change it
    name = "The Gate of Elidinis",
    assumptions = { common.SOLO_KILLS },

    killCounts = KILL_COUNTS,
    modes = MODES,

    items = {
        [ATTUNER] = { log = VARS.log .. "SKILLING_OFFHAND_RUNECRAFTING" },
        [DOWSER] = { log = VARS.log .. "SKILLING_OFFHAND_DIVINATION" },
        [SCRIPTURE] = { log = VARS.log .. "ELIDINIS_BOOK_UNLOCK_TOKEN" },
        [CODEX] = { log = VARS.codex },
        [OFFERING] = { log = VARS.log .. "OFFERINGS_AMULET_UPGRADE_MATERIAL" },
    },
}

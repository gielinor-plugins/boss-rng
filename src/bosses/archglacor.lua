-- Arch-Glacor, hard mode only: a solo fight. Rates: RuneScape Wiki (CC BY-NC-SA 3.0),
-- checked 2026-11-03. A kill's unique chance rises with the fight's enrage and the
-- kill's place in the streak. Both are read at the kill and saved as daily totals, and
-- each day's kills are rated at their averages. Uniques reach the collection log only
-- when the streak's loot is claimed, even after a death, so drops count only just after
-- a claim (tests: docs/bosses/archglacor.md). Dark nilas come in stacks: a claim's
-- count as one drop, and their collection log count is shown on its own, like
-- Vorkath's spikes. The pontifex shadow ring raises every unique (src/bosses/egwd.lua).

local egwd = require("src/bosses/egwd")

local VARS = {
    kc = "BSLAY_KILLS_EGWD_WEN_BOSS_HARDMODE",
    -- Each item's collection log count (Arch-Glacor's internal name is Wen)
    log = "ITEMLOG_ITEM_EGWD_WEN_",
    enrage = "EGWD_WEN_BOSS_CURRENT_ENRAGE", -- the fight's, until the next one starts
    -- Kills in the streak, this one included; 0 once claimed
    streak = "EGWD_WEN_BOSS_CURRENT_STREAK",
}

local CORE, SCRIPTURE, ARTEFACT, NILAS = 52020, 52115, 52021, 52019
local SHARES = { [CORE] = 24, [SCRIPTURE] = 38, [ARTEFACT] = 38 } -- percent of uniques
local FIRST_KILL = { enrage = 0, streak = 1 } -- for a day saved without sums: the lowest chance
local CLAIM_MOST = 10000 -- more of one item than any claim brings

local function rolls(r, readings, means)
    means = means or FIRST_KILL
    local chance = r.base + r.perEnrage * means.enrage + r.perStreak * means.streak
    return {
        { chance = egwd.Boost(chance, readings), items = SHARES },
        { chance = r.nilas, items = { [NILAS] = 1 } },
    }
end

return {
    key = "archglacor",
    name = "Arch-Glacor (Hard Mode)",
    reads = egwd.Reads(),
    assumptions = { "A claim's dark nilas count as one drop" },
    tip = "Uniques are only tracked when you claim the loot",

    -- Counted through its kill event, which reads the enrage and streak.
    killCounts = { { var = VARS.kc } },
    modes = { h = { rolls = rolls } },
    killEvents = {
        {
            var = VARS.kc,
            reads = { enrage = VARS.enrage, streak = VARS.streak },
            sums = { "enrage", "streak" },
            mode = function()
                return "h"
            end,
        },
    },
    dropsAtClaim = { var = VARS.streak, most = CLAIM_MOST },

    items = {
        [CORE] = { log = VARS.log .. "BOSS_INGREDIENT_HARDMODE" },
        [SCRIPTURE] = { log = VARS.log .. "BOOK_UNLOCK_TOKEN" },
        [ARTEFACT] = { log = VARS.log .. "BOSS_GLOVES_UPGRADE" },
        [NILAS] = {
            log = VARS.log .. "BOSS_INGREDIENT_RARE_NEW",
            stack = { most = CLAIM_MOST, word = "dark nilas", plural = "dark nilas" },
        },
    },
}

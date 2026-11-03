-- Arch-Glacor, hard mode only. A solo fight. Rates: RuneScape Wiki (CC BY-NC-SA 3.0),
-- checked 2026-11-03. Each kill's unique chance rises with the fight's enrage and the
-- kill's place in the streak, both read at the kill and averaged by day. Uniques reach
-- the boss log when the streak's loot is claimed, even after a death, so drops count
-- only at a claim (tested: docs/bosses/archglacor.md). The pontifex shadow ring raises
-- every unique (src/bosses/egwd.lua). Dark nilas count like Vorkath's spikes: a claim's
-- are one drop, the log counting items.

local egwd = require("src/bosses/egwd")

local VARS = {
    kc = "BSLAY_KILLS_EGWD_WEN_BOSS_HARDMODE",
    log = "ITEMLOG_ITEM_EGWD_WEN_", -- each item's log count (Arch-Glacor's internal name is Wen)
    enrage = "EGWD_WEN_BOSS_CURRENT_ENRAGE", -- the fight's, until the next one starts
    -- Kills in the streak, this one included; 0 once claimed
    streak = "EGWD_WEN_BOSS_CURRENT_STREAK",
}

local CORE, SCRIPTURE, ARTEFACT, NILAS = 52020, 52115, 52021, 52019
local SHARES = { [CORE] = 24, [SCRIPTURE] = 38, [ARTEFACT] = 38 } -- of a unique
local FIRST_KILL = { enrage = 0, streak = 1 } -- the lowest chance, for a day without sums
local CLAIM_MOST = 10000 -- more of one item than any claim brings

local function rolls(r, readings, means)
    means = means or FIRST_KILL
    local chance = r.base + r.perEnrage * means.enrage + r.perStreak * means.streak
    return {
        { chance = egwd.Boost(chance, readings), items = SHARES },
        { chance = r.nilas, items = { [NILAS] = 1 } },
    }
end

-- Keys are saved: never change them.
local HARD = { key = "h", kc = VARS.kc, byEvent = true, rolls = rolls }

return {
    key = "archglacor", -- saved data key: never change it
    name = "Arch-Glacor (Hard Mode)",
    reads = egwd.Reads(),
    assumptions = { "A claim's dark nilas count as one drop" },
    tip = "Uniques are only tracked when you claim the loot",

    modes = { HARD },
    killEvents = {
        {
            var = VARS.kc,
            reads = { enrage = VARS.enrage, streak = VARS.streak },
            sums = { "enrage", "streak" },
            mode = function()
                return HARD.key
            end,
        },
    },
    modeFor = function(key)
        return key == HARD.key and HARD or nil
    end,
    dropsAtClaim = { var = VARS.streak, most = CLAIM_MOST },

    items = {
        [CORE] = { log = VARS.log .. "BOSS_INGREDIENT_HARDMODE" },
        [SCRIPTURE] = { log = VARS.log .. "BOOK_UNLOCK_TOKEN" },
        [ARTEFACT] = { log = VARS.log .. "BOSS_GLOVES_UPGRADE" },
        [NILAS] = {
            log = VARS.log .. "BOSS_INGREDIENT_RARE_NEW",
            stack = { most = CLAIM_MOST, word = "dark nilas", plural = "dark nilas" }, -- a claim's
        },
    },
}

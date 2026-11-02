-- Kerapac. Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28. Each kill gives
-- three loot piles, each rolling a unique; staff pieces drop in sequence, so they're one
-- group. The kill count doesn't say how many piles the player got, and counting them as
-- they land isn't reliable, so the player sets their average per mode.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_EGWD_JAS_BOSS",
    kcHard = "BSLAY_KILLS_EGWD_JAS_BOSS_HARDMODE",
    log = "ITEMLOG_ITEM_EGWD_JAS_", -- each item's log count (Kerapac's internal name is Jas)
    codex = "ITEMLOG_ITEM_COMBATV2_ABILITY_CODEX_MAGIC_GREATER_CONCENTRATED_BLAST",
}

local SYMBOL, GEM, SHAFT = 51776, 51779, 51782
local WRAPS, CODEX, SCRIPTURE = 51767, 51843, 51812
local STAFF = { name = "Staff pieces" }

-- A pile's rolls for each loot pile, scaled to the share (count of r.piles) the player gets.
local function piles(count, pile, r)
    local share = count / r.piles
    local rolls = {}
    for _, roll in ipairs(pile) do
        common.Repeat(rolls, r.piles, { chance = roll.chance * share, items = roll.items })
    end
    return rolls
end

local OTHERS = common.Even({ WRAPS, CODEX, SCRIPTURE })

local function normalPile(r)
    return { { chance = r.normal, items = OTHERS } }
end

local function hardPile(r)
    return {
        { chance = r.hardStaff, items = common.Even({ SYMBOL, GEM, SHAFT }) },
        { chance = (1 - r.hardStaff) * r.hard, items = OTHERS },
    }
end

local function pilesChoice(key, label)
    return { key = key, label = label, unit = " loot piles per kill", default = 3, min = 1, max = 3, step = 0.25 }
end

return {
    key = "kerapac", -- saved data key: never change it
    name = "Kerapac",
    assumptions = {},
    choicesHelp = {
        "Set the loot piles you usually get per kill in each mode: 3 solo, about 1.5 in a duo, 1 in a "
            .. "trio. It applies to all your tracked kills in that mode.",
        "Each pile is its own chance at a unique. Fewer piles lower the uniques an average player would "
            .. "expect, so the same drops rate as luckier.",
    },
    choices = {
        pilesChoice("normalPiles", "Normal Mode"), -- saved data keys: never change them
        pilesChoice("hardPiles", "Hard Mode"),
    },

    -- Mode keys are saved: never change them.
    modes = {
        { key = "n", kc = VARS.kc, rolls = function(r, picks)
            return piles(picks.normalPiles, normalPile(r), r)
        end },
        { key = "h", kc = VARS.kcHard, rolls = function(r, picks)
            return piles(picks.hardPiles, hardPile(r), r)
        end },
    },

    items = {
        [SYMBOL] = { log = VARS.log .. "BOSS_MAGIC_WEAPON_TOP", kind = "unique", group = STAFF },
        [GEM] = { log = VARS.log .. "BOSS_MAGIC_WEAPON_MIDDLE", kind = "unique", group = STAFF },
        [SHAFT] = { log = VARS.log .. "BOSS_MAGIC_WEAPON_BOTTOM", kind = "unique", group = STAFF },
        [WRAPS] = { log = VARS.log .. "BOSS_MAGIC_GLOVES", kind = "unique" },
        [CODEX] = { log = VARS.codex, kind = "unique" },
        [SCRIPTURE] = { log = VARS.log .. "BOOK_UNLOCK_TOKEN", kind = "unique" },
        [51861] = { kind = "pet" }, -- Kerry
    },
}

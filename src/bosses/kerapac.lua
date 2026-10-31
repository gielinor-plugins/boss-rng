-- Kerapac, the bound, in the Elder God Wars Dungeon.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28: each kill gives
-- three loot piles, each rolling a unique. Normal mode: 1/256 for one of three
-- evenly. Hard mode: 1/400 for a staff piece, and if that misses, 1/180 for one
-- of the same three. Staff pieces drop in sequence (shaft, gem, symbol), so
-- they're shown as one group.
--
-- A solo player gets all three piles. In a duo the top damager gets two and the
-- other player one, so a duo player averages one and a half. In a trio each
-- player gets one. The kill count doesn't say how many piles the player got,
-- and counting them as they land isn't reliable, so for now the player sets
-- their average loot piles per kill for each mode (3, solo, by default).

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

-- A kill's rolls at rate values r for a player averaging count piles a kill: a
-- pile's rolls for each loot pile, scaled to the share of them they get.
local function piles(count, pile, r)
    local share = count / r.piles
    local rolls = {}
    for _, roll in ipairs(pile) do
        common.Repeat(rolls, r.piles, { chance = roll.chance * share, items = roll.items })
    end
    return rolls
end

local OTHERS = common.Even({ WRAPS, CODEX, SCRIPTURE })

-- Each mode's pile at rate values r, per loot pile (see src/rates/base.lua).
local function normalPile(r)
    return { { chance = r.normal, items = OTHERS } }
end

local function hardPile(r)
    return {
        { chance = r.hardStaff, items = common.Even({ SYMBOL, GEM, SHAFT }) },
        { chance = (1 - r.hardStaff) * r.hard, items = OTHERS },
    }
end

-- A slider for a mode's average loot piles per kill.
local function pilesChoice(key, label)
    return { key = key, label = label, unit = " loot piles per kill", default = 3, min = 1, max = 3, step = 0.25 }
end

return {
    key = "kerapac", -- saved data key: never change it
    name = "Kerapac",
    logPage = "COLLECTION_BOSS_EGWD_JAS_BOSS", -- the boss log page's database row
    assumptions = {},
    choicesHelp = {
        "Each kill drops 3 loot piles, and each pile has its own chance at a unique. Solo, you get all 3. "
            .. "In a duo, the top damager gets 2 and the other player 1. In a trio, everyone gets 1.",
        "Set your average for each mode here: 3 if you kill solo, about 1.5 in a duo, 1 in a trio, or in "
            .. "between if you mix. It applies to all your tracked kills in that mode.",
        "Fewer piles means fewer chances at a unique, so the same drops count as luckier.",
    },
    choices = {
        pilesChoice("normalPiles", "Normal Mode"), -- saved data keys: never change them
        pilesChoice("hardPiles", "Hard Mode"),
    },

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = VARS.kc, rolls = function(r, picks)
            return piles(picks.normalPiles, normalPile(r), r)
        end },
        { name = "Hard mode", kc = VARS.kcHard, rolls = function(r, picks)
            return piles(picks.hardPiles, hardPile(r), r)
        end },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
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

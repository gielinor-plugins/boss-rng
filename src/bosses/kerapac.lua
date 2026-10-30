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
-- player gets one. Kill counts don't say the team size, so the player picks it
-- for each mode.

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

local TEAMS = { "solo", "duo", "trio", "soloDuo", "duoTrio", "mixed" }

-- A kill's rolls: a pile's rolls for each of the three piles, scaled to the
-- share of them a player averages for their team (3 solo, 1.5 duo, 1 trio).
local function piles(pick, pile)
    local share = common.TeamMix(pick, 3, 1.5, 1) / 3
    local rolls = {}
    for _, roll in ipairs(pile) do
        common.Repeat(rolls, 3, { chance = roll.chance * share, items = roll.items })
    end
    return rolls
end

local OTHERS = common.Even({ WRAPS, CODEX, SCRIPTURE })

return {
    key = "kerapac", -- saved data key: never change it
    name = "Kerapac",
    logPage = "COLLECTION_BOSS_EGWD_JAS_BOSS", -- the boss log page's database row
    -- In a duo the top damager gets the extra pile, which the even split assumes.
    assumptions = function(picks)
        if common.HasDuo(picks.normalTeam) or common.HasDuo(picks.hardTeam) then
            return { "Top damage on half of duo kills" }
        end
        return {}
    end,
    choices = {
        common.Team("normalTeam", "Normal mode kills done", TEAMS), -- saved data keys: never change them
        common.Team("hardTeam", "Hard mode kills done", TEAMS),
    },

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = VARS.kc, rolls = function(picks)
            return piles(picks.normalTeam, { { chance = 1 / 256, items = OTHERS } })
        end },
        { name = "Hard mode", kc = VARS.kcHard, rolls = function(picks)
            return piles(picks.hardTeam, {
                { chance = 1 / 400, items = common.Even({ SYMBOL, GEM, SHAFT }) },
                { chance = 399 / 400 / 180, items = OTHERS },
            })
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

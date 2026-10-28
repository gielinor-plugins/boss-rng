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

local SYMBOL, GEM, SHAFT = 51776, 51779, 51782
local WRAPS, CODEX, SCRIPTURE = 51767, 51843, 51812
local STAFF = { name = "Staff pieces" }

-- Each team option's average loot piles per kill. Mixes are even splits.
local PILES = { solo = 3, duo = 1.5, trio = 1, soloDuo = 2.25, duoTrio = 1.25, mixed = 11 / 6 }
local TEAM_OPTIONS = {
    { value = "solo", label = "Solo" },
    { value = "duo", label = "Duo" },
    { value = "trio", label = "Trio" },
    { value = "soloDuo", label = "Solo/duo", note = "Half solo, half duo" },
    { value = "duoTrio", label = "Duo/trio", note = "Half duo, half trio" },
    { value = "mixed", label = "Mixed", note = "A third each of solo, duo and trio" },
}
local SOLO_OR_TRIO = { solo = true, trio = true } -- the picks without duo kills

-- A choice of team for one mode's kills.
local function team(key, label)
    return { key = key, label = label, default = "solo", options = TEAM_OPTIONS }
end

-- A kill's rolls: a pile's rolls for each of the three piles, scaled to the
-- share of them a player averages for their team.
local function piles(pick, pile)
    local rolls = {}
    for _, roll in ipairs(pile) do
        common.Repeat(rolls, 3, { chance = roll.chance * PILES[pick] / 3, items = roll.items })
    end
    return rolls
end

local OTHERS = common.Even({ WRAPS, CODEX, SCRIPTURE })

local LOG = "ITEMLOG_ITEM_EGWD_JAS_" -- Kerapac's internal name is Jas

return {
    key = "kerapac", -- saved data key: never change it
    name = "Kerapac",
    logPage = "COLLECTION_BOSS_EGWD_JAS_BOSS", -- the boss log page's database row
    -- In a duo the top damager gets the extra pile, which the even split assumes.
    assumptions = function(picks)
        if SOLO_OR_TRIO[picks.normalTeam] and SOLO_OR_TRIO[picks.hardTeam] then
            return {}
        end
        return { "Top damage on half of duo kills" }
    end,
    choices = {
        team("normalTeam", "Normal mode kills done"), -- saved data keys: never change them
        team("hardTeam", "Hard mode kills done"),
    },

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = "BSLAY_KILLS_EGWD_JAS_BOSS", rolls = function(picks)
            return piles(picks.normalTeam, { { chance = 1 / 256, items = OTHERS } })
        end },
        { name = "Hard mode", kc = "BSLAY_KILLS_EGWD_JAS_BOSS_HARDMODE", rolls = function(picks)
            return piles(picks.hardTeam, {
                { chance = 1 / 400, items = common.Even({ SYMBOL, GEM, SHAFT }) },
                { chance = 399 / 400 / 180, items = OTHERS },
            })
        end },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [SYMBOL] = { log = LOG .. "BOSS_MAGIC_WEAPON_TOP", kind = "unique", group = STAFF },
        [GEM] = { log = LOG .. "BOSS_MAGIC_WEAPON_MIDDLE", kind = "unique", group = STAFF },
        [SHAFT] = { log = LOG .. "BOSS_MAGIC_WEAPON_BOTTOM", kind = "unique", group = STAFF },
        [WRAPS] = { log = LOG .. "BOSS_MAGIC_GLOVES", kind = "unique" },
        [CODEX] = { log = "ITEMLOG_ITEM_COMBATV2_ABILITY_CODEX_MAGIC_GREATER_CONCENTRATED_BLAST", kind = "unique" },
        [SCRIPTURE] = { log = LOG .. "BOOK_UNLOCK_TOKEN", kind = "unique" },
        [51861] = { kind = "pet" }, -- Kerry
    },
}

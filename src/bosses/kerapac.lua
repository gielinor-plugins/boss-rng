-- Kerapac. Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28. Each kill gives
-- three loot piles, split by damage (solo all three, duo two and one, trio one each), and
-- each rolls for a unique; staff pieces drop in sequence, so they're one group. Each kill
-- counts the player's piles, seen as the ground stacks they own that gain Resonant anima
-- of Jas at the kill (tested: docs/bosses/kerapac.md).

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
local OTHERS = common.Even({ WRAPS, CODEX, SCRIPTURE })

local ANIMA = { 51804, 51805 } -- Resonant anima of Jas, tradeable or not: in every pile
local MAX_PILES = 3

local function normalPile(r)
    return { { chance = r.normal, items = OTHERS } }
end

local function hardPile(r)
    return {
        { chance = r.hardStaff, items = common.Even({ SYMBOL, GEM, SHAFT }) },
        { chance = (1 - r.hardStaff) * r.hard, items = OTHERS },
    }
end

local TRACKED = {}

-- Modes for 1 to 3 piles in one difficulty ("n2": normal mode, 2 piles), each pile
-- rolling pile(r). Keys are saved: never change them.
local function addPileModes(prefix, kc, pile)
    for count = 1, MAX_PILES do
        TRACKED[prefix .. count] = { key = prefix .. count, kc = kc, piles = count, rolls = function(r)
            local rolls = {}
            for _ = 1, count do
                for _, roll in ipairs(pile(r)) do
                    table.insert(rolls, roll)
                end
            end
            return rolls
        end }
    end
end

addPileModes("n", VARS.kc, normalPile)
addPileModes("h", VARS.kcHard, hardPile)

-- A kill's mode by the piles seen at it. None seen means the player was away, most
-- likely not the top damager, so it counts as 1.
local function killEvent(kc, prefix)
    return { var = kc, reads = {}, piles = ANIMA, mode = function(values)
        return prefix .. math.max(1, math.min(values.piles, MAX_PILES))
    end }
end

return {
    key = "kerapac", -- saved data key: never change it
    name = "Kerapac",
    assumptions = { "Kills you were away for count as 1 loot pile" },

    -- Counted only through its kill events, by piles.
    modes = {
        { key = "n", kc = VARS.kc, byEvent = true },
        { key = "h", kc = VARS.kcHard, byEvent = true },
    },
    killEvents = { killEvent(VARS.kc, "n"), killEvent(VARS.kcHard, "h") },
    modeFor = function(key) return TRACKED[key] end,

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

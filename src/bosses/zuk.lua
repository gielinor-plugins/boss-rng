-- TzKal-Zuk. A solo fight. Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-11-02.
-- Hard mode sword pieces are likelier in a run without checkpoints. Such a run, in
-- either mode, gives an Igneous stone in the kill's tick, so each hard mode kill is
-- counted by whether the stone's log count rose with it (tested: docs/bosses/zuk.md).

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_EGWD_FUL_BOSS",
    kcHard = "BSLAY_KILLS_EGWD_FUL_BOSS_HARDMODE",
    log = "ITEMLOG_ITEM_EGWD_FUL_", -- each item's log count (TzKal-Zuk's internal name is Ful)
    codex = "ITEMLOG_ITEM_COMBATV2_ABILITY_CODEX_MAGIC_MAGMA_TEMPEST",
    stones = "ITEMLOG_ITEM_EGWD_FUL_BOSS_INFERNAL_STONE", -- Igneous stones: runs without checkpoints
}

local BLADE, CORE, HILT = 52505, 52507, 52509
local CODEX, SCRIPTURE = 52530, 52492
local SWORD = { name = "Sword pieces" }
local STONE_CAP = 250 -- the boss log counts no more Igneous stones

local function books(chance)
    return {
        { chance = chance, items = { [CODEX] = 1 } },
        { chance = chance, items = { [SCRIPTURE] = 1 } },
    }
end

-- Hard mode's rolls, with a sword piece at the rate named sword.
local function hardRolls(sword)
    return function(r)
        local rolls = books(r.hard)
        table.insert(rolls, 1, { chance = r[sword], items = common.Even({ BLADE, CORE, HILT }) })
        return rolls
    end
end

-- Hard mode without and with checkpoints. Keys are saved: never change them.
local HARD = {
    h = { key = "h", kc = VARS.kcHard, byEvent = true, rolls = hardRolls("swordNoCheckpoints") },
    hc = { key = "hc", kc = VARS.kcHard, rolls = hardRolls("sword") },
}

-- A hard mode kill without checkpoints gave a stone in its tick, unless the log is full.
local function hardKill(values)
    return (values.stone or values.stones >= STONE_CAP) and "h" or "hc"
end

return {
    key = "zuk", -- saved data key: never change it
    name = "TzKal-Zuk",
    reads = { stones = VARS.stones },
    assumptions = function(readings)
        local full = (readings.stones or 0) >= STONE_CAP
        return full and { "Runs after 250 Igneous stones count as checkpoint-free" } or {}
    end,

    modes = {
        {
            key = "n",
            kc = VARS.kc,
            rolls = function(r)
                return books(r.normal)
            end,
        },
        HARD.h,
    },
    killEvents = {
        {
            var = VARS.kcHard,
            reads = { stones = VARS.stones },
            rises = { stone = VARS.stones },
            mode = hardKill,
        },
    },
    modeFor = function(key)
        return HARD[key]
    end,

    items = {
        [BLADE] = { log = VARS.log .. "BOSS_MELEE_WEAPON_TOP", kind = "unique", group = SWORD },
        [CORE] = { log = VARS.log .. "BOSS_MELEE_WEAPON_MIDDLE", kind = "unique", group = SWORD },
        [HILT] = { log = VARS.log .. "BOSS_MELEE_WEAPON_BOTTOM", kind = "unique", group = SWORD },
        [CODEX] = { log = VARS.codex, kind = "unique" },
        [SCRIPTURE] = { log = VARS.log .. "BOOK_UNLOCK_TOKEN", kind = "unique" },
        [52500] = { log = VARS.stones, kind = "excluded" }, -- Igneous stone: a run reward
        [52546] = { kind = "pet" }, -- Little Zuk
    },
}

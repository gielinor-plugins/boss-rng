-- TzKal-Zuk. A solo fight. Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28.
-- Hard mode sword pieces are likelier without checkpoints. Every run without them, in
-- either mode, gives an Igneous stone, so stones count those runs, though not by mode.

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

-- Share of hard mode kills without checkpoints: stones over all kills (1 until read).
local function noCheckpointShare(readings)
    local kills = (readings.normalKills or 0) + (readings.hardKills or 0)
    if readings.stones == nil or kills == 0 then
        return 1
    end
    return math.min(readings.stones / kills, 1)
end

-- True if the stones can't tell: some kills used checkpoints and some stones could be
-- from either mode.
local function unclear(readings)
    if readings.stones == nil then
        return false
    end
    local fewest = math.max(0, readings.stones - readings.normalKills)
    local most = math.min(readings.stones, readings.hardKills)
    return fewest < most and readings.stones < readings.normalKills + readings.hardKills
end

local function books(chance)
    return { { chance = chance, items = { [CODEX] = 1 } }, { chance = chance, items = { [SCRIPTURE] = 1 } } }
end

local function hardRolls(r, readings)
    local share = noCheckpointShare(readings)
    local rolls = books(r.hard)
    table.insert(rolls, 1, {
        chance = share * r.swordNoCheckpoints + (1 - share) * r.sword,
        items = common.Even({ BLADE, CORE, HILT }),
    })
    return rolls
end

return {
    key = "zuk", -- saved data key: never change it
    name = "TzKal-Zuk",
    reads = { stones = VARS.stones, normalKills = VARS.kc, hardKills = VARS.kcHard },
    assumptions = function(readings)
        return unclear(readings) and { "Checkpoints used as often in both modes" } or {}
    end,

    modes = common.Modes(VARS, function(r) return books(r.normal) end, hardRolls),

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

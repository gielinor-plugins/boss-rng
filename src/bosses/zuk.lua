-- TzKal-Zuk, in the Elder God Wars Dungeon.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28: the codex and
-- the scripture are 1/100 each in normal mode and 1/50 in hard mode. Hard mode
-- also drops Ek-ZekKil pieces: 1/30 for any piece, or 1/27 in a run without
-- checkpoints. They drop in sequence (a random piece, then the other two), so
-- they're shown as one group. The fight is solo.
--
-- Every run without checkpoints, in either mode, gives an Igneous stone, so the
-- stones say how many runs had none, though not in which mode.

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

-- The share of hard mode kills without checkpoints: the stones' share of all
-- kills. Until the game is read, none are assumed to have used checkpoints.
local function noCheckpointShare(picks)
    local kills = (picks.normalKills or 0) + (picks.hardKills or 0)
    if picks.stones == nil or kills == 0 then
        return 1
    end
    return math.min(picks.stones / kills, 1)
end

-- True if the stones can't say how many hard mode kills had no checkpoints:
-- some kills used them, and some stones could be from either mode.
local function unclear(picks)
    if picks.stones == nil then
        return false
    end
    local fewest = math.max(0, picks.stones - picks.normalKills)
    local most = math.min(picks.stones, picks.hardKills)
    return fewest < most and picks.stones < picks.normalKills + picks.hardKills
end

-- The codex and the scripture, each on its own roll at chance.
local function books(chance)
    return { { chance = chance, items = { [CODEX] = 1 } }, { chance = chance, items = { [SCRIPTURE] = 1 } } }
end

-- A hard mode kill's rolls at rate values r (see src/rates/base.lua): a sword
-- piece, at the share of runs without checkpoints read from the picks, then the books.
local function hardRolls(r, picks)
    local share = noCheckpointShare(picks)
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
    logPage = "COLLECTION_BOSS_EGWD_FUL_BOSS", -- the boss log page's database row
    reads = { stones = VARS.stones, normalKills = VARS.kc, hardKills = VARS.kcHard },
    assumptions = function(picks)
        return unclear(picks) and { "Checkpoints used as often in both modes" } or {}
    end,

    modes = common.Modes(VARS, function(r) return books(r.normal) end, hardRolls),

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
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

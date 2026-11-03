-- Sanctum of Rebirth: three bosses in one run with one boss log page, each with its own
-- kill counts. Rates: RuneScape Wiki (from Jagex; CC BY-NC-SA 3.0), checked 2026-10-27.
-- Every player gets their own rolls. Each boss's loot waits in a chest until claimed,
-- and the run can't be entered again until it is, so each claim is one kill, counted
-- at its mode (see docs/bosses/sanctum.md for the tests behind this).

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_RAID_REBIRTH1_", -- then each boss's name, with _HARDMODE for hard mode
    log = "ITEMLOG_ITEM_", -- then each unique's log count name
    -- Each boss's waiting loot and its difficulty (rare fields never read)
    loot = "RAID_REBIRTH1_VARP_1",
}

local CODEX, SCRIPTURE, ROAR, ODE = 57156, 57124, 57162, 57158

-- Rolls by rate names: a book, then for Nakatra a weapon and, in hard mode, the Shard.
local function rolls(books, weapons, shard)
    return function(r)
        local list = { { chance = r[books], items = common.Even({ CODEX, SCRIPTURE }) } }
        if weapons then
            table.insert(list, { chance = r[weapons], items = common.Even({ ROAR, ODE }) })
        end
        if shard then
            table.insert(list, { chance = r[shard], items = { [common.SHARD] = 1 } })
        end
        return list
    end
end

local BOOKS, HARD_BOOKS = rolls("books"), rolls("hardBooks")

-- Vermyx, Kezalam and Nakatra, each then in hard mode. Mode keys are saved: never change them.
local MODES = {
    { key = "v", kc = VARS.kc .. "WYRM_BOSS", rolls = BOOKS },
    { key = "vh", kc = VARS.kc .. "WYRM_BOSS_HARDMODE", rolls = HARD_BOOKS },
    { key = "k", kc = VARS.kc .. "BEAST_BOSS", rolls = BOOKS },
    { key = "kh", kc = VARS.kc .. "BEAST_BOSS_HARDMODE", rolls = HARD_BOOKS },
    { key = "n", kc = VARS.kc .. "SLAYER_MASTER_BOSS", rolls = rolls("books", "weapons") },
    {
        key = "nh",
        kc = VARS.kc .. "SLAYER_MASTER_BOSS_HARDMODE",
        rolls = rolls("hardBooks", "hardWeapons", "hardShard"),
    },
}
local byKey = {}
for _, mode in ipairs(MODES) do
    mode.byEvent = true -- counted through claims
    byKey[mode.key] = mode
end

-- A boss's claim, for its normal and hard mode (MODES[i] and MODES[i + 1]): its
-- loot waiting bit and difficulty field (0 normal, 1 hard) in VARS.loot.
local function claim(i, loot, difficulty)
    local normal, hard = MODES[i], MODES[i + 1]
    return {
        var = VARS.loot,
        mask = loot,
        kills = { normal.kc, hard.kc },
        reads = {},
        mode = function(_, old)
            return (old & difficulty) == 0 and normal.key or hard.key
        end,
    }
end

return {
    key = "sanctum", -- saved data key: never change it
    name = "Sanctum of Rebirth",
    assumptions = {},

    modes = MODES,
    claims = { claim(1, 0x1, 0x300), claim(3, 0x4, 0xC00), claim(5, 0x10, 0x3000) },
    modeFor = function(key)
        return byKey[key]
    end,

    items = {
        [CODEX] = { log = VARS.log .. "COMBATV2_PRAYER_CODEX_DIVINE_RAGE" },
        [SCRIPTURE] = {
            log = VARS.log .. "RAID_REBIRTH1_AMASCUT_BOOK_UNLOCK_TOKEN",
        },
        [ROAR] = { log = VARS.log .. "MAGIC_DEVOURER_WAND_T95" },
        [ODE] = { log = VARS.log .. "MAGIC_DEVOURER_ORB_T95" },
        [common.SHARD] = common.SHARD_ITEM, -- also dropped by Amascut
    },
}

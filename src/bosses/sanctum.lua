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

-- Each boss: its mode key (hard mode's adds h; keys are saved: never change them),
-- kill count name, rolls in normal then hard mode, and its loot waiting bit and
-- difficulty field (0 normal, 1 hard) in VARS.loot.
local BOSSES = {
    {
        key = "v", -- Vermyx
        kc = "WYRM_BOSS",
        rolls = BOOKS,
        hard = HARD_BOOKS,
        loot = 0x1,
        difficulty = 0x300,
    },
    {
        key = "k", -- Kezalam
        kc = "BEAST_BOSS",
        rolls = BOOKS,
        hard = HARD_BOOKS,
        loot = 0x4,
        difficulty = 0xC00,
    },
    {
        key = "n", -- Nakatra
        kc = "SLAYER_MASTER_BOSS",
        rolls = rolls("books", "weapons"),
        hard = rolls("hardBooks", "hardWeapons", "hardShard"),
        loot = 0x10,
        difficulty = 0x3000,
    },
}

-- Each boss's kill counts are counted through its claim.
local KILL_COUNTS, MODES, CLAIMS = {}, {}, {}
for _, b in ipairs(BOSSES) do
    local normal, hard = VARS.kc .. b.kc, VARS.kc .. b.kc .. "_HARDMODE"
    table.insert(KILL_COUNTS, { var = normal })
    table.insert(KILL_COUNTS, { var = hard })
    MODES[b.key], MODES[b.key .. "h"] = { rolls = b.rolls }, { rolls = b.hard }
    table.insert(CLAIMS, {
        var = VARS.loot,
        mask = b.loot,
        kills = { normal, hard },
        mode = function(_, old)
            return (old & b.difficulty) == 0 and b.key or b.key .. "h"
        end,
    })
end

return {
    key = "sanctum", -- saved data key: never change it
    name = "Sanctum of Rebirth",
    assumptions = {},

    killCounts = KILL_COUNTS,
    modes = MODES,
    claims = CLAIMS,

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

-- Amascut. Rates: Jagex's "Drop Rates Revealed" via the RuneScape Wiki (CC BY-NC-SA 3.0),
-- checked 2026-10-27. Each player rolls gear, the Nexus and, in enrage, the Shard; each
-- enrage tier has its own rates, so its own mode. A kill makes five loot piles (spares go
-- to top damagers) that wait in the chest until claimed, so piles claimed are counted
-- (tests: docs/bosses/amascut.md).

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_AMASCUT_BOSS",
    kcEnrage = "BSLAY_KILLS_AMASCUT_BOSS_HARDMODE", -- enrage mode, every tier
    enrage = "AMASCUT_BOSS_LAST_ENRAGE", -- set as an enrage instance starts
    loot = "AMASCUT_BOSS_VARP_1", -- the chest's waiting loot (below)
    log = "ITEMLOG_ITEM_", -- then each unique's log count name
}

-- Bits of VARS.loot: piles waiting (AMASCUT_BOSS_COMMON_LOOT_AVAILABLE) and difficulty
-- (_LOOT_DIFFICULTY, 0 in normal mode). Its rare fields are never read.
local PILES, DIFFICULTY = 0x70000, 0xF0000000

local MASK, TOP, BOTTOM, GLOVES, BOOTS = 59344, 59336, 59346, 59342, 59340
local LIGHT, GUARD, NEXUS = 59350, 59354, 59358

local ARMOR, WEAPONS = { MASK, TOP, BOTTOM, GLOVES, BOOTS }, { LIGHT, GUARD }

local function gear(r)
    return common.Each(ARMOR, r.armorShare / #ARMOR, common.Each(WEAPONS, (1 - r.armorShare) / #WEAPONS))
end

-- Rolls by rate names for gear, the Nexus and the Shard (none in normal mode).
local function rolls(gearRate, nexus, shard)
    return function(r)
        local list = {
            { chance = r[gearRate], items = gear(r) },
            { chance = r[nexus], items = { [NEXUS] = 1 } },
        }
        if shard then
            table.insert(list, { chance = r[shard], items = { [common.SHARD] = 1 } })
        end
        return list
    end
end

local TIERS = {
    { enrage = 100, label = "100%" },
    { enrage = 500, label = "500%" },
    { enrage = 750, label = "750%" },
    { enrage = 1000, label = "1,000%" },
    { enrage = 2000, label = "2,000%+" },
}

-- Mode names are saved: never change them.
local MODES = { Normal = { name = "Normal", kc = VARS.kc, byEvent = true, rolls = rolls("gear", "nexus") } }
for _, tier in ipairs(TIERS) do
    local name = "Enrage " .. tier.label
    local e = tier.enrage
    MODES[name] = { name = name, kc = VARS.kcEnrage, rolls = rolls("gear" .. e, "nexus" .. e, "shard" .. e) }
end

-- The highest tier at or below enrage (4,000% is 2,000%+), else the lowest.
local function tierMode(enrage)
    local found = TIERS[1]
    for _, tier in ipairs(TIERS) do
        if enrage >= tier.enrage then
            found = tier
        end
    end
    return "Enrage " .. found.label
end

-- A chest's piles share one enrage: a new instance can't start until they're claimed.
local function claimedMode(values, old)
    return (old & DIFFICULTY) == 0 and "Normal" or tierMode(values.enrage)
end

return {
    key = "amascut", -- saved data key: never change it
    name = "Amascut, the Devourer",
    assumptions = {},
    unit = "pile", -- what luck counts: loot piles claimed (see claims)
    tip = "Open the chest after each kill: stacked loot can't always be counted",

    -- Mode names are saved: never change them. Counted through piles claimed.
    modes = {
        MODES.Normal,
        { name = "Enrage", kc = VARS.kcEnrage, byEvent = true },
    },
    claims = { {
        var = VARS.loot, mask = PILES, kills = { VARS.kc, VARS.kcEnrage },
        reads = { enrage = VARS.enrage }, mode = claimedMode,
    } },
    modeFor = function(name) return MODES[name] end,

    items = {
        [MASK] = { log = VARS.log .. "MAGIC_DEVOURER_HEAD_T95", kind = "unique" },
        [TOP] = { log = VARS.log .. "MAGIC_DEVOURER_BODY_T95", kind = "unique" },
        [BOTTOM] = { log = VARS.log .. "MAGIC_DEVOURER_LEGS_T95", kind = "unique" },
        [GLOVES] = { log = VARS.log .. "MAGIC_DEVOURER_HANDS_T95", kind = "unique" },
        [BOOTS] = { log = VARS.log .. "MAGIC_DEVOURER_FEET_T95", kind = "unique" },
        [LIGHT] = { log = VARS.log .. "MELEE_DEVOURER_HALBERD_T95", kind = "unique" }, -- Tumeken's Light
        [GUARD] = { log = VARS.log .. "NECRO_DEVOURER_ARMGUARD_T95", kind = "unique" }, -- Devourer's Guard
        [NEXUS] = { log = VARS.log .. "NECRO_DEVOURER_NEXUS_T80", kind = "unique" },
        [common.SHARD] = common.SHARD_ITEM, -- also dropped by Nakatra
        [59321] = { kind = "lore" }, -- Memoirs of the Devourer
        [59363] = { kind = "pet" }, -- Amaskitty
    },
}

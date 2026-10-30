-- Amascut, the Devourer.
--
-- From Jagex's "Drop Rates Revealed: Amascut, Goddess of Destruction", via the
-- RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-27: every player gets their
-- own unique rolls each kill, whatever the team size. One roll is for weapons and
-- armor (armor three times in four, split over its five pieces; else one of
-- the two weapons), one for the Nexus and, in enrage mode, one for the Shard of
-- Genesis Essence. Enrage rates depend on the enrage tier, so each tier is a
-- mode of its own, sharing one kill count: each tracked enrage kill counts for
-- the tier of the enrage set for the instance.
--
-- Each kill makes five loot piles, each with its own unique rolls: one per player
-- in a team of five, and in smaller teams the rest go to the top damagers. Kill
-- counts don't say the team, so one pile per kill is assumed.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_AMASCUT_BOSS",
    kcEnrage = "BSLAY_KILLS_AMASCUT_BOSS_HARDMODE", -- enrage mode, every tier
    enrage = "AMASCUT_BOSS_LAST_ENRAGE", -- set as an instance starts
    log = "ITEMLOG_ITEM_", -- then each unique's log count name
}

local MASK, TOP, BOTTOM, GLOVES, BOOTS = 59344, 59336, 59346, 59342, 59340
local LIGHT, GUARD, NEXUS = 59350, 59354, 59358

-- Each armor piece is 3/4 / 5 = 6/40 of the table, each weapon 1/4 / 2 = 5/40.
local GEAR = { [MASK] = 6, [TOP] = 6, [BOTTOM] = 6, [GLOVES] = 6, [BOOTS] = 6, [LIGHT] = 5, [GUARD] = 5 }

-- The rolls, from 1 in gear for weapons and armor, 1 in nexus for the Nexus and
-- 1 in shard for the Shard (normal mode has no Shard roll).
local function rolls(gear, nexus, shard)
    local list = {
        { chance = 1 / gear, items = GEAR },
        { chance = 1 / nexus, items = { [NEXUS] = 1 } },
    }
    if shard then
        table.insert(list, { chance = 1 / shard, items = { [common.SHARD] = 1 } })
    end
    return list
end

-- The enrage tiers. Their Nexus and Shard rates are the same.
local TIERS = {
    { enrage = 100, label = "100%", gear = 70, nexus = 280 },
    { enrage = 500, label = "500%", gear = 60, nexus = 240 },
    { enrage = 750, label = "750%", gear = 50, nexus = 200 },
    { enrage = 1000, label = "1,000%", gear = 35, nexus = 140 },
    { enrage = 2000, label = "2,000%+", gear = 25, nexus = 100 },
}

-- Each tier's mode, by name. Mode names are saved with the player's data: never
-- change them.
local TIER_MODES = {}
for _, tier in ipairs(TIERS) do
    local name = "Enrage " .. tier.label
    TIER_MODES[name] = { name = name, kc = VARS.kcEnrage, rolls = rolls(tier.gear, tier.nexus, tier.nexus) }
end

-- The mode name of the tier an enrage falls in: the highest tier at or below it,
-- or the lowest tier below them all.
local function tierMode(enrage)
    local found = TIERS[1]
    for _, tier in ipairs(TIERS) do
        if enrage >= tier.enrage then
            found = tier
        end
    end
    return "Enrage " .. found.label
end

return {
    key = "amascut", -- saved data key: never change it
    name = "Amascut, the Devourer",
    logPage = "COLLECTION_BOSS_AMASCUT", -- the boss log page's database row
    assumptions = { "One loot pile per kill (teams of 5)" },

    -- Mode names are saved with the player's data: never change them. The enrage
    -- kill count's mode is counted only through its kill event (a tier's mode).
    modes = {
        { name = "Normal", kc = VARS.kc, rolls = rolls(600, 750) },
        { name = "Enrage", kc = VARS.kcEnrage, byEvent = true },
    },
    killEvents = { { var = VARS.kcEnrage, reads = { enrage = VARS.enrage }, mode = function(values)
        return tierMode(values.enrage)
    end } },
    modeFor = function(name) return TIER_MODES[name] end,

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
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

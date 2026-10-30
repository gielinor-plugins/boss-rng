-- Amascut, the Devourer.
--
-- From Jagex's "Drop Rates Revealed: Amascut, Goddess of Destruction", via the
-- RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-27: every player gets their
-- own unique rolls each kill, whatever the team size. One roll is for weapons and
-- armour (armour three times in four, split over its five pieces; else one of
-- the two weapons), one for the Nexus and, in enrage mode, one for the Shard of
-- Genesis Essence. Enrage rates depend on the enrage tier, so each tier is a
-- mode of its own. The tiers share one kill count: see src/bosses.lua.
--
-- Each kill makes five loot piles, each with its own unique rolls: one per player
-- in a team of five, and in smaller teams the rest go to the top damagers. Kill
-- counts don't say the team, so one pile per kill is assumed.

local common = require("src/bosses/common")

local MASK, TOP, BOTTOM, GLOVES, BOOTS = 59344, 59336, 59346, 59342, 59340
local LIGHT, GUARD, NEXUS = 59350, 59354, 59358

-- Each armour piece is 3/4 / 5 = 6/40 of the table, each weapon 1/4 / 2 = 5/40.
local GEAR = { [MASK] = 6, [TOP] = 6, [BOTTOM] = 6, [GLOVES] = 6, [BOOTS] = 6, [LIGHT] = 5, [GUARD] = 5 }

-- The rolls, from 1 in gear for weapons and armour, 1 in nexus for the Nexus and
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

local ENRAGE = {
    key = "enrage", -- saved data key: never change it
    label = "Average Enrage",
    note = "Average enrage of untracked kills", -- in the assumptions, away from the settings page
    default = 100,
    var = "AMASCUT_BOSS_LAST_ENRAGE", -- set as an instance starts
    untrackedOnly = true, -- tracked kills use the var
    options = {},
}

-- Mode names are saved with the player's data: never change them.
local modes = { { name = "Normal", kc = "BSLAY_KILLS_AMASCUT_BOSS", rolls = rolls(600, 750) } }
for _, tier in ipairs(TIERS) do
    table.insert(ENRAGE.options, { value = tier.enrage, label = tier.label })
    table.insert(modes, {
        name = "Enrage " .. tier.label,
        kc = "BSLAY_KILLS_AMASCUT_BOSS_HARDMODE",
        tier = { choice = ENRAGE.key, value = tier.enrage },
        rolls = rolls(tier.gear, tier.nexus, tier.nexus),
    })
end

return {
    key = "amascut", -- saved data key: never change it
    name = "Amascut, the Devourer",
    logPage = "COLLECTION_BOSS_AMASCUT", -- the boss log page's database row
    assumptions = { "One loot pile per kill (teams of 5)" },
    choices = { ENRAGE },
    modes = modes,

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [MASK] = { log = "ITEMLOG_ITEM_MAGIC_DEVOURER_HEAD_T95", kind = "unique" },
        [TOP] = { log = "ITEMLOG_ITEM_MAGIC_DEVOURER_BODY_T95", kind = "unique" },
        [BOTTOM] = { log = "ITEMLOG_ITEM_MAGIC_DEVOURER_LEGS_T95", kind = "unique" },
        [GLOVES] = { log = "ITEMLOG_ITEM_MAGIC_DEVOURER_HANDS_T95", kind = "unique" },
        [BOOTS] = { log = "ITEMLOG_ITEM_MAGIC_DEVOURER_FEET_T95", kind = "unique" },
        [LIGHT] = { log = "ITEMLOG_ITEM_MELEE_DEVOURER_HALBERD_T95", kind = "unique" }, -- Tumeken's Light
        [GUARD] = { log = "ITEMLOG_ITEM_NECRO_DEVOURER_ARMGUARD_T95", kind = "unique" }, -- Devourer's Guard
        [NEXUS] = { log = "ITEMLOG_ITEM_NECRO_DEVOURER_NEXUS_T80", kind = "unique" },
        [common.SHARD] = common.SHARD_ITEM, -- also dropped by Nakatra
        [59321] = { kind = "lore" }, -- Memoirs of the Devourer
        [59363] = { kind = "pet" }, -- Amaskitty
    },
}

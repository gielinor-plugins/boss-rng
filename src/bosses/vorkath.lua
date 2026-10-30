-- Zemouregal & Vorkath, at Fort Forinthry. Normal and hard mode (story mode has
-- no kill count or uniques). Every player who did damage gets their own chest,
-- so team size doesn't matter.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-30, with rates from
-- Jagex's 8 January 2024 post, raised 14 July 2025 (before Boss RNG came out):
-- each chest rolls once for a rare, in its first slot. Normal: Vorkath's spike
-- 1/45 or the Invoke Lord of Bones incantation codex 1/249. Hard: spike 1/15,
-- codex 1/150 or Vorkath's scale 1/150. One slot gives one item, so each mode's
-- rares are one roll.
--
-- The chest is kept as an item and can be opened any time, so luck counts
-- chests opened, not kills: each opening is counted with its drop, and a chest
-- opened while Boss RNG is off is simply untracked.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_FORT_BOSS_ZEMO_VORKATH",
    kcHard = "BSLAY_KILLS_FORT_BOSS_ZEMO_VORKATH_HARD",
    codex = "ITEMLOG_ITEM_NECROMANCY_INCANTATION_CODEX_INVOKE_LORD_OF_BONES",
    scale = "ITEMLOG_ITEM_VORKATH_DRACOLICH_UPGRADE_MATERIAL",
    spike = "ITEMLOG_ITEM_VORKATH_DRAGONHIDE_UPGRADE_MATERIAL", -- counts spikes, not drops
}

local SPIKE, SCALE, CODEX = 56079, 56321, 56068
local CHEST, CHEST_HARD = 56071, 56072 -- Zemouregal & Vorkath loot (normal), (hard)
local REWARD_WINDOW = "DROP_CASKET_REWARDINV" -- the inventory a chest opens into


return {
    key = "vorkath", -- saved data key: never change it
    name = "Zemouregal & Vorkath",
    logPage = "COLLECTION_BOSS_FORT_BOSS_ZEMO_VORKATH", -- the boss log page's database row
    assumptions = {},
    unit = "chest", -- what luck counts (see containers)

    -- Mode names are saved with the player's data: never change them. Each is
    -- counted through its chest opened, not its kill count.
    modes = {
        { name = "Normal", kc = VARS.kc, byEvent = true,
            rolls = function(r) return { common.OneOf({ [SPIKE] = r.spike, [CODEX] = r.codex }) } end },
        { name = "Hard mode", kc = VARS.kcHard, byEvent = true,
            rolls = function(r)
                return { common.OneOf({ [SPIKE] = r.hardSpike, [CODEX] = r.hardCodex, [SCALE] = r.hardScale }) }
            end },
    },
    containers = {
        [CHEST] = { mode = "Normal", window = REWARD_WINDOW },
        [CHEST_HARD] = { mode = "Hard mode", window = REWARD_WINDOW },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [SPIKE] = { log = VARS.spike, kind = "unique", stack = { most = 9, word = "spike" } }, -- 4 to 9 a drop
        [SCALE] = { log = VARS.scale, kind = "unique" },
        [CODEX] = { log = VARS.codex, kind = "unique" },
        [56143] = { kind = "excluded" }, -- Zemouregal's nexus: given at 100 kills
        [56145] = { kind = "pet" }, -- Vorki
    },
}

-- Zemouregal & Vorkath. Rates: Jagex's 8 January 2024 post, raised 14 July 2025, via the
-- RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-30.
-- Each damager gets their own chest, with one rare slot, so each mode's rares are one
-- roll. The chest is kept as an item to open later, so chests opened are counted.

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
    key = "vorkath",
    name = "Zemouregal & Vorkath",
    assumptions = {},
    unit = "chest", -- luck counts chests opened, not kills

    killCounts = { { var = VARS.kc }, { var = VARS.kcHard } }, -- counted by chests opened
    modes = {
        n = {
            rolls = function(r)
                return { common.OneOf({ [SPIKE] = r.spike, [CODEX] = r.codex }) }
            end,
        },
        h = {
            rolls = function(r)
                return {
                    common.OneOf({
                        [SPIKE] = r.hardSpike,
                        [CODEX] = r.hardCodex,
                        [SCALE] = r.hardScale,
                    }),
                }
            end,
        },
    },
    containers = {
        [CHEST] = { mode = "n", window = REWARD_WINDOW },
        [CHEST_HARD] = { mode = "h", window = REWARD_WINDOW },
    },

    items = {
        [SPIKE] = { log = VARS.spike, stack = { most = 9, word = "spike" } }, -- 4 to 9 a drop
        [SCALE] = { log = VARS.scale },
        [CODEX] = { log = VARS.codex },
    },
}

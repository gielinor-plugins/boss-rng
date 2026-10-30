-- Raksha, the Shadow Colossus. Solo or duo; in a duo, each player gets their own
-- drop at the same rates as solo.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-29: each kill rolls
-- a 1/50 unique table, split in 13ths: the Fleeting boots 5 (1/130 per kill) and
-- each other unique 2 (1/325). These rates date from 14 July 2025, before Boss
-- RNG came out.

local VARS = {
    kc = "BSLAY_KILLS_DINO_BOSS_", -- by team size: SOLO or DUO
    log = "ITEMLOG_ITEM_", -- then each unique's log count name
}

local BOOTS, SPIKE = 51082, 51086
local RICOCHET, CHAIN, DIVERT = 51094, 51096, 51098
local ROLLS = { { chance = 1 / 50, items = { [BOOTS] = 5, [SPIKE] = 2, [RICOCHET] = 2, [CHAIN] = 2, [DIVERT] = 2 } } }

return {
    key = "raksha", -- saved data key: never change it
    name = "Raksha, the Shadow Colossus",
    logPage = "COLLECTION_BOSS_DINO", -- the boss log page's database row
    assumptions = {},

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Solo", kc = VARS.kc .. "SOLO", rolls = ROLLS },
        { name = "Duo", kc = VARS.kc .. "DUO", rolls = ROLLS },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [BOOTS] = { log = VARS.log .. "DINO_SLAYER_RANGED_BOOTS", kind = "unique" },
        [SPIKE] = { log = VARS.log .. "DINO_BOSS_BOOTS_ATTACHMENT", kind = "unique" },
        [RICOCHET] = { log = VARS.log .. "COMBATV2_ABILITY_CODEX_RANGED_GREATER_RICOCHET", kind = "unique" },
        [CHAIN] = { log = VARS.log .. "COMBATV2_ABILITY_CODEX_MAGIC_GREATER_CHAIN", kind = "unique" },
        [DIVERT] = { log = VARS.log .. "COMBATV2_ABILITY_CODEX_DEFENCE_DIVERT", kind = "unique" },
        [51101] = { kind = "pet" }, -- Raklette
    },
}

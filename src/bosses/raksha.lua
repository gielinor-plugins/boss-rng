-- Raksha. Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-29. In a duo each
-- player gets their own drop at solo rates.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_DINO_BOSS_", -- by team size: SOLO or DUO
    log = "ITEMLOG_ITEM_", -- then each unique's log count name
}

local BOOTS, SPIKE = 51082, 51086
local RICOCHET, CHAIN, DIVERT = 51094, 51096, 51098
local OTHERS = { SPIKE, RICOCHET, CHAIN, DIVERT }

local function rolls(r)
    return { common.OneOf(common.Each(OTHERS, r.other, { [BOOTS] = r.boots })) }
end

return {
    key = "raksha", -- saved data key: never change it
    name = "Raksha, the Shadow Colossus",
    assumptions = {},

    -- Mode keys are saved: never change them.
    modes = {
        { key = "s", kc = VARS.kc .. "SOLO", rolls = rolls },
        { key = "d", kc = VARS.kc .. "DUO", rolls = rolls },
    },

    items = {
        [BOOTS] = { log = VARS.log .. "DINO_SLAYER_RANGED_BOOTS", kind = "unique" },
        [SPIKE] = { log = VARS.log .. "DINO_BOSS_BOOTS_ATTACHMENT", kind = "unique" },
        [RICOCHET] = { log = VARS.log .. "COMBATV2_ABILITY_CODEX_RANGED_GREATER_RICOCHET", kind = "unique" },
        [CHAIN] = { log = VARS.log .. "COMBATV2_ABILITY_CODEX_MAGIC_GREATER_CHAIN", kind = "unique" },
        [DIVERT] = { log = VARS.log .. "COMBATV2_ABILITY_CODEX_DEFENCE_DIVERT", kind = "unique" },
        [51101] = { kind = "pet" }, -- Raklette
    },
}

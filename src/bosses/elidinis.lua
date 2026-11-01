-- The Gate of Elidinis, a skilling boss.
--
-- From Jagex's "Gate of Elidinis Drop Rates" (via the RuneScape Wiki, CC BY-NC-SA
-- 3.0), checked 2026-10-31: each cleanse rolls 1/120 for the rare table, then one
-- of its four uniques evenly (1/480 each), and 1/71 for a Latent Offering (one a
-- drop, so its log count is its drops). Jagex's Late-Game Rebalance raises each
-- rare to 1/256, taken as still one roll. Nearly every kill is solo, so solo is
-- assumed.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_ELIDINIS_BOSS",
    log = "ITEMLOG_ITEM_ELIDINIS_BOSS_", -- each unique's log count, by its name
    codex = "ITEMLOG_ITEM_COMBATV2_PRAYER_CODEX_ECLIPSED_SOUL",
}

local ATTUNER, DOWSER, SCRIPTURE, CODEX, OFFERING = 57519, 57521, 57524, 57544, 57528
local RARES = { ATTUNER, DOWSER, SCRIPTURE, CODEX }

-- A cleanse's rolls at rate values r (see src/core/rates/base.lua).
local function rolls(r)
    return {
        common.OneOf(common.Each(RARES, r.rare)),
        { chance = r.offering, items = { [OFFERING] = 1 } },
    }
end

return {
    key = "elidinis", -- saved data key: never change it
    name = "The Gate of Elidinis",
    assumptions = { common.SOLO_KILLS },

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = VARS.kc, rolls = rolls },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [ATTUNER] = { log = VARS.log .. "SKILLING_OFFHAND_RUNECRAFTING", kind = "unique" },
        [DOWSER] = { log = VARS.log .. "SKILLING_OFFHAND_DIVINATION", kind = "unique" },
        [SCRIPTURE] = { log = VARS.log .. "ELIDINIS_BOOK_UNLOCK_TOKEN", kind = "unique" },
        [CODEX] = { log = VARS.codex, kind = "unique" },
        [OFFERING] = { log = VARS.log .. "OFFERINGS_AMULET_UPGRADE_MATERIAL", kind = "unique" },
        [57533] = { kind = "lore" }, -- After The Flood
        [57548] = { kind = "pet" }, -- Edie
    },
}

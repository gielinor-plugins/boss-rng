-- Croesus, in the Elder God Wars Dungeon.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28: each loot roll
-- has a 1/600 chance of a unique, one of nine evenly (1/5,400 each). Rolls go up
-- with contribution, to 12 at full contribution. Every player gets their own rolls.
-- Jagex's Late-Game Rebalance raises each roll's weapons, spore sack and
-- scripture to 1/2,500 each and Cryptbloom pieces to 1/3,000 each (src/rates/).

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_EGWD_BIK_BOSS",
    log = "ITEMLOG_ITEM_EGWD_BIK_", -- each item's log count (Croesus's internal name is Bik)
}

local HELM, TOP, BOTTOMS, GLOVES, BOOTS = 52250, 52256, 52258, 52252, 52254 -- Cryptbloom
local SPOREHAMMER, FOULTORCH, SPORE_SACK, SCRIPTURE = 52244, 52248, 52213, 52345
local ARMOR = { HELM, TOP, BOTTOMS, GLOVES, BOOTS }
local OTHERS = { SPOREHAMMER, FOULTORCH, SPORE_SACK, SCRIPTURE }

-- A kill's rolls at rate values r: each item's chance per loot roll (see
-- src/rates/base.lua).
local function rolls(r)
    local unique = common.OneOf(common.Each(ARMOR, r.armor, common.Each(OTHERS, r.other)))
    return common.Repeat({}, r.lootRolls, unique)
end

return {
    key = "croesus", -- saved data key: never change it
    name = "Croesus",
    logPage = "COLLECTION_BOSS_EGWD_BIK_BOSS", -- the boss log page's database row
    -- Kill counts don't say how much a player contributed.
    assumptions = { "Full contribution (12 rolls)" },

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = VARS.kc, rolls = rolls },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [HELM] = { log = VARS.log .. "BOSS_MAGIC_HELM", kind = "unique" },
        [TOP] = { log = VARS.log .. "BOSS_MAGIC_BODY", kind = "unique" },
        [BOTTOMS] = { log = VARS.log .. "BOSS_MAGIC_LEGS", kind = "unique" },
        [GLOVES] = { log = VARS.log .. "BOSS_MAGIC_GLOVES", kind = "unique" },
        [BOOTS] = { log = VARS.log .. "BOSS_MAGIC_BOOTS", kind = "unique" },
        [SPOREHAMMER] = { log = VARS.log .. "BOSS_OFFHAND_MINING", kind = "unique" },
        [FOULTORCH] = { log = VARS.log .. "BOSS_OFFHAND_WOODCUTTING", kind = "unique" },
        [SPORE_SACK] = { log = VARS.log .. "BOSS_SEED_STORAGE_UNIQUE", kind = "unique" },
        [SCRIPTURE] = { log = VARS.log .. "BOOK_UNLOCK_TOKEN", kind = "unique" },
        [52459] = { kind = "pet" }, -- Little Sus
    },
}

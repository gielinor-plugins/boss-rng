-- Croesus, in the Elder God Wars Dungeon.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28: each loot roll
-- has a 1/600 chance of a unique, one of nine evenly (1/5,400 each). Rolls go up
-- with contribution (ROLLS), to 12 at full contribution, and below 60 there are
-- no unique rolls. Every player gets their own rolls. Jagex's Late-Game
-- Rebalance raises each roll's weapons, spore sack and scripture to 1/2,500
-- each and Cryptbloom pieces to 1/3,000 each (src/rates/). Each tracked kill
-- counts at the player's contribution, its last value before the kill (the
-- game resets it after), so its rolls are exact.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_EGWD_BIK_BOSS",
    log = "ITEMLOG_ITEM_EGWD_BIK_", -- each item's log count (Croesus's internal name is Bik)
    contribution = "EGWD_BIK_BOSS_PERSONAL_CONTRIBUTION", -- the player's, through the fight
}

-- Unique rolls by contribution, from the wiki: the fewest contribution for each
-- number of rolls (below 60, none).
local ROLLS = {
    { 420, 12 }, { 400, 11 }, { 380, 10 }, { 360, 9 }, { 345, 8 }, { 330, 7 },
    { 310, 6 }, { 280, 5 }, { 230, 4 }, { 180, 3 }, { 100, 2 }, { 60, 1 },
}

local HELM, TOP, BOTTOMS, GLOVES, BOOTS = 52250, 52256, 52258, 52252, 52254 -- Cryptbloom
local SPOREHAMMER, FOULTORCH, SPORE_SACK, SCRIPTURE = 52244, 52248, 52213, 52345
local ARMOR = { HELM, TOP, BOTTOMS, GLOVES, BOOTS }
local OTHERS = { SPOREHAMMER, FOULTORCH, SPORE_SACK, SCRIPTURE }

-- A kill's n unique rolls at rate values r: each item's chance per loot roll
-- (see src/rates/base.lua).
local function rolls(n)
    return function(r)
        return common.Repeat({}, n, common.OneOf(common.Each(ARMOR, r.armor, common.Each(OTHERS, r.other))))
    end
end

-- Each kill's mode by its unique rolls ("12 rolls"). Mode names are saved with
-- the player's data: never change them.
local MODES = {}
local function modeName(n)
    return n .. (n == 1 and " roll" or " rolls")
end
for n = 0, 12 do
    MODES[modeName(n)] = { name = modeName(n), kc = VARS.kc, byEvent = true, rolls = rolls(n) }
end

-- A kill's mode from the player's contribution, or nil if none was seen.
local function contributionMode(values)
    local contribution = values.contribution
    if contribution == nil then
        return nil
    end
    for _, step in ipairs(ROLLS) do
        if contribution >= step[1] then
            return modeName(step[2])
        end
    end
    return modeName(0)
end

return {
    key = "croesus", -- saved data key: never change it
    name = "Croesus",
    logPage = "COLLECTION_BOSS_EGWD_BIK_BOSS", -- the boss log page's database row
    assumptions = {},

    modes = { MODES["12 rolls"] }, -- counted only through its kill event
    killEvents = { { var = VARS.kc, reads = {}, lasts = { contribution = VARS.contribution }, mode = contributionMode } },
    modeFor = function(name) return MODES[name] end,

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

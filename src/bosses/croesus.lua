-- Croesus. Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28. Unique rolls rise
-- with contribution. Each kill counts at the player's last contribution before it (the
-- game resets it after), so its rolls are exact.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_EGWD_BIK_BOSS",
    log = "ITEMLOG_ITEM_EGWD_BIK_", -- each item's log count (Croesus's internal name is Bik)
    contribution = "EGWD_BIK_BOSS_PERSONAL_CONTRIBUTION", -- the player's, through the fight
}

-- The fewest contribution for each number of unique rolls (below 60, none).
local ROLLS = {
    { 420, 12 }, { 400, 11 }, { 380, 10 }, { 360, 9 }, { 345, 8 }, { 330, 7 },
    { 310, 6 }, { 280, 5 }, { 230, 4 }, { 180, 3 }, { 100, 2 }, { 60, 1 },
}

local HELM, TOP, BOTTOMS, GLOVES, BOOTS = 52250, 52256, 52258, 52252, 52254 -- Cryptbloom
local SPOREHAMMER, FOULTORCH, SPORE_SACK, SCRIPTURE = 52244, 52248, 52213, 52345
local ARMOR = { HELM, TOP, BOTTOMS, GLOVES, BOOTS }
local OTHERS = { SPOREHAMMER, FOULTORCH, SPORE_SACK, SCRIPTURE }

local function rolls(n)
    return function(r)
        return common.Repeat({}, n, common.OneOf(common.Each(ARMOR, r.armor, common.Each(OTHERS, r.other))))
    end
end

-- Modes by unique rolls ("12 rolls"). Names are saved: never change them.
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
    assumptions = {},

    modes = { MODES["12 rolls"] }, -- counted only through its kill event
    killEvents = { { var = VARS.kc, reads = {}, lasts = { contribution = VARS.contribution }, mode = contributionMode } },
    modeFor = function(name) return MODES[name] end,

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

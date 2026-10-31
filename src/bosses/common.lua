-- What every boss file can share, whatever group it belongs to. Not a boss file.

local common = {}

-- An assumption: group kills share loot, but kill counts don't say who was in
-- the group, so bosses whose kills can't be told apart assume solo kills.
common.SOLO_KILLS = "Solo kills"

-- The Shard of Genesis Essence, dropped by Amascut and by Nakatra in the
-- Sanctum of Rebirth, with one boss log count for both.
common.SHARD = 57128
common.SHARD_ITEM = {
    log = "ITEMLOG_ITEM_COMBATV2_INNATE_MASTERY_UNLOCK_T95_WEAPON_STAT_UPGRADE_T1",
    kind = "unique",
}

-- Adds n copies of a roll to rolls: one per roll a kill makes on the same table.
function common.Repeat(rolls, n, roll)
    for _ = 1, n do
        table.insert(rolls, roll)
    end
    return rolls
end

-- A boss's normal and hard mode, by vars.kc and vars.kcHard, with their rolls
-- (hard defaults to normal's). Mode names are saved data: never change them.
function common.Modes(vars, normal, hard)
    return {
        { name = "Normal", kc = vars.kc, rolls = normal },
        { name = "Hard mode", kc = vars.kcHard, rolls = hard or normal },
    }
end

-- Each of ids at chance, { [item id] = chance }, added to into if given.
function common.Each(ids, chance, into)
    local chances = into or {}
    for _, itemID in ipairs(ids) do
        chances[itemID] = chance
    end
    return chances
end

-- One roll that gives at most one of its items, from each item's chance:
-- { [item id] = chance } as the weights, and their sum as the roll's chance.
function common.OneOf(chances)
    local chance = 0
    for _, itemChance in pairs(chances) do
        chance = chance + itemChance
    end
    return { chance = chance, items = chances }
end

-- Weights for a roll's items split evenly between ids.
function common.Even(ids)
    local weights = {}
    for _, itemID in ipairs(ids) do
        weights[itemID] = 1
    end
    return weights
end

return common

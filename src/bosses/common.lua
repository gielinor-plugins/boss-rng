-- What every boss file can share, whatever group it belongs to. Not a boss file.

local common = {}

-- Kill counts don't say who was in the group, so solo kills are assumed.
common.SOLO_KILLS = "Solo kills"

-- Shard of Genesis Essence: Amascut and Nakatra share one boss log count.
common.SHARD = 57128
common.SHARD_ITEM = {
    log = "ITEMLOG_ITEM_COMBATV2_INNATE_MASTERY_UNLOCK_T95_WEAPON_STAT_UPGRADE_T1",
}

-- Adds n copies of a roll to rolls: one per roll a kill makes on the same table.
function common.Repeat(rolls, n, roll)
    for _ = 1, n do
        table.insert(rolls, roll)
    end
    return rolls
end

-- Normal and hard mode; hard's rolls default to normal's. Keys are saved: never change.
function common.Modes(vars, normal, hard)
    return {
        { key = "n", kc = vars.kc, rolls = normal },
        { key = "h", kc = vars.kcHard, rolls = hard or normal },
    }
end

-- { [item id] = chance } for each of ids, added to into if given.
function common.Each(ids, chance, into)
    local chances = into or {}
    for _, itemID in ipairs(ids) do
        chances[itemID] = chance
    end
    return chances
end

-- One roll giving at most one item: chances are the weights, their sum the roll's chance.
function common.OneOf(chances)
    local chance = 0
    for _, itemChance in pairs(chances) do
        chance = chance + itemChance
    end
    return { chance = chance, items = chances }
end

function common.Even(ids)
    local weights = {}
    for _, itemID in ipairs(ids) do
        weights[itemID] = 1
    end
    return weights
end

return common

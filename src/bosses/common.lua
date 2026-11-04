-- What every boss file can share, whatever group it belongs to. Not a boss file.

local common = {}

-- Kill counts don't say who was in the group, so solo kills are assumed.
common.SOLO_KILLS = "Solo kills"

-- Shard of Genesis Essence: Amascut and Nakatra share one collection log count.
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

-- The killCounts and modes of a boss with one kill count, saved as mode n.
function common.OneMode(kc, rolls)
    return { { var = kc, mode = "n" } }, { n = { rolls = rolls } }
end

-- The killCounts and modes of a boss with normal (n) and hard (h) kill counts; hard's
-- rolls default to normal's.
function common.NormalAndHard(vars, normal, hard)
    return { { var = vars.kc, mode = "n" }, { var = vars.kcHard, mode = "h" } }, {
        n = { rolls = normal },
        h = { rolls = hard or normal },
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

-- Equal weights for ids: a roll gives one of them at random.
function common.Even(ids)
    local weights = {}
    for _, itemID in ipairs(ids) do
        weights[itemID] = 1
    end
    return weights
end

return common

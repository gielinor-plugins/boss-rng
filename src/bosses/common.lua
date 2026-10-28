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
    plural = "Shards", -- for labels about its pooled count (see src/bosses.lua)
}

-- Options for a choice of percentages, e.g. { 0, 5, 10 } gives 0%, 5% and 10%.
function common.Percentages(values)
    local options = {}
    for i, value in ipairs(values) do
        options[i] = { value = value, label = value .. "%" }
    end
    return options
end

-- Adds n copies of a roll to rolls: one per roll a kill makes on the same table.
function common.Repeat(rolls, n, roll)
    for _ = 1, n do
        table.insert(rolls, roll)
    end
    return rolls
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

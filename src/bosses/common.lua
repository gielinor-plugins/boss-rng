-- What every boss file can share, whatever group it belongs to. Not a boss file.

local common = {}

-- An assumption: group kills share loot, but kill counts don't say who was in
-- the group, so bosses whose kills can't be told apart assume solo kills.
common.SOLO_KILLS = "Solo kills"

-- Weights for a roll's items split evenly between ids.
function common.Even(ids)
    local weights = {}
    for _, itemID in ipairs(ids) do
        weights[itemID] = 1
    end
    return weights
end

return common

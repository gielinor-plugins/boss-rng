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

-- Team options for a choice of who a boss's kills were done with: each option's
-- label, its note if the label is shortened, and its shares of solo, duo and trio
-- kills. Mixes are even splits. Values are saved data: never change them.
local TEAMS = {
    solo = { label = "Solo", shares = { 1, 0, 0 } },
    duo = { label = "Duo", shares = { 0, 1, 0 } },
    trio = { label = "Trio", shares = { 0, 0, 1 } },
    soloDuo = { label = "Solo/duo", note = "Half solo, half duo", shares = { 1 / 2, 1 / 2, 0 } },
    duoTrio = { label = "Duo/trio", note = "Half duo, half trio", shares = { 0, 1 / 2, 1 / 2 } },
    mixed = { label = "Mixed", note = "A third each of solo, duo and trio", shares = { 1 / 3, 1 / 3, 1 / 3 } },
}

-- A choice of team, listing these TEAMS values in order, the first by default.
function common.Team(key, label, values)
    local options = {}
    for i, value in ipairs(values) do
        options[i] = { value = value, label = TEAMS[value].label, note = TEAMS[value].note }
    end
    return { key = key, label = label, default = values[1], options = options }
end

-- A value for a team pick, from its solo, duo and trio values by the pick's shares.
function common.TeamMix(pick, solo, duo, trio)
    local shares = TEAMS[pick].shares
    return shares[1] * solo + shares[2] * duo + shares[3] * trio
end

-- True if a team pick has duo kills.
function common.HasDuo(pick)
    return TEAMS[pick].shares[2] > 0
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

-- Luck math for Boss RNG. Terms:
--   chance    of something on one kill, from 0 to 1
--   expected  drops an average player would have after the same kills
--   received  drops the player actually got while tracked

local luck = {}

-- { [itemID] = chance per kill } for independent rolls. Items in one roll exclude
-- each other and share its chance by weight; an item in several rolls sums them.
function luck.ItemChances(rolls)
    local chances = {}
    for _, roll in ipairs(rolls) do
        local totalWeight = 0
        for _, weight in pairs(roll.items) do
            totalWeight = totalWeight + weight
        end
        for itemID, weight in pairs(roll.items) do
            -- A chance of 0 (not on the table that day) leaves it out.
            if roll.chance > 0 and weight > 0 then
                chances[itemID] = (chances[itemID] or 0) + roll.chance * weight / totalWeight
            end
        end
    end
    return chances
end

-- Chance per kill of any tracked item (a set { [itemID] = true }, or nil for all).
function luck.ChanceOfAny(rolls, tracked)
    local missAll = 1
    for _, roll in ipairs(rolls) do
        local totalWeight, trackedWeight = 0, 0
        for itemID, weight in pairs(roll.items) do
            totalWeight = totalWeight + weight
            if tracked == nil or tracked[itemID] then
                trackedWeight = trackedWeight + weight
            end
        end
        if totalWeight > 0 then
            missAll = missAll * (1 - roll.chance * trackedWeight / totalWeight)
        end
    end
    return 1 - missAll
end

-- Share of players with fewer drops than received (Poisson, mean expected), plus half
-- of those with as many ("mid-p", so average lands near 50%). Nil when expected is 0.
function luck.Percentile(expected, received)
    if expected <= 0 then
        return nil
    end
    -- Each term is the last times expected / i, in logs so large values don't overflow.
    local logExpected = math.log(expected)
    local logTerm = -expected -- log of the chance of 0 drops
    local below = 0
    for i = 1, received do
        below = below + math.exp(logTerm)
        logTerm = logTerm + logExpected - math.log(i)
    end
    return below + 0.5 * math.exp(logTerm)
end

-- Share of players who'd have at least one drop in the given number of kills, at
-- chance per kill.
function luck.DryPercentile(chance, kills)
    return 1 - (1 - chance) ^ kills
end

return luck

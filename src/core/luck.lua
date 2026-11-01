-- Luck math for Boss RNG. Plain Lua with no game API, so it can be tested offline.
--
-- Terms used here:
--   chance    the chance of something on one kill, from 0 to 1
--   expected  how many drops an average player would have after the same kills
--   received  how many the player actually has (their boss log count)

local luck = {}

-- Returns { [itemID] = chance per kill } for a boss's rolls.
-- Each roll is independent. Items in one roll are mutually exclusive and share
-- the roll's chance by weight, e.g. { chance = 1 / 320, items = { [a] = 1, [b] = 1 } }
-- gives a and b 1/640 each. An item in several rolls gets the sum of its chances.
function luck.ItemChances(rolls)
    local chances = {}
    for _, roll in ipairs(rolls) do
        local totalWeight = 0
        for _, weight in pairs(roll.items) do
            totalWeight = totalWeight + weight
        end
        for itemID, weight in pairs(roll.items) do
            -- A chance of 0 (an item not on the table on that day) leaves it out.
            if roll.chance > 0 and weight > 0 then
                chances[itemID] = (chances[itemID] or 0) + roll.chance * weight / totalWeight
            end
        end
    end
    return chances
end

-- Chance per kill of at least one tracked item: 1 minus the chance that every
-- roll misses them all. tracked is a set { [itemID] = true }, or nil for all items.
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

-- Share of players, from 0 to 1, who would have fewer drops than received after
-- the same kills, counting half of those with exactly as many (the "mid-p" rule,
-- so an exactly average result lands near 50%). Drops per player follow a
-- Poisson distribution whose mean is expected. Returns nil when expected is 0.
function luck.Percentile(expected, received)
    if expected <= 0 then
        return nil
    end
    -- Each Poisson term is the previous one times expected / i. Working with
    -- logarithms keeps large values from overflowing.
    local logExpected = math.log(expected)
    local logTerm = -expected -- log of the chance of 0 drops
    local below = 0
    for i = 1, received do
        below = below + math.exp(logTerm)
        logTerm = logTerm + logExpected - math.log(i)
    end
    return below + 0.5 * math.exp(logTerm)
end

-- Share of players, from 0 to 1, who would have had at least one drop within
-- kills kills at chance per kill: 1 - (1 - chance)^kills.
function luck.DryPercentile(chance, kills)
    return 1 - (1 - chance) ^ kills
end

return luck

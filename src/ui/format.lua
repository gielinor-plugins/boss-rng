-- The words and numbers Boss RNG shows, shared by every view.

local format = {}

-- 1234567 gives "1,234,567".
function format.Number(n)
    local text = tostring(math.floor(n))
    local result = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (result:gsub("^,", ""))
end

-- "1 kill" or "5 kills".
local function count(n, word, plural)
    return format.Number(n) .. " " .. (n == 1 and word or plural or word .. "s")
end

-- "kill", or the boss's own unit ("chest").
local function unit(result)
    return result.unit or "kill"
end

-- True if any kill is tracked, in the kill count or outside it.
function format.IsTracked(result)
    return (result.kills or 0) + (result.extraKills or 0) > 0
end

-- A 0 to 1 share as a whole percent, rounded down; below 1% is "under 1%".
function format.Percent(share)
    if share < 0.01 then
        return "under 1%"
    end
    return math.floor(share * 100) .. "%"
end

-- Luck between these shares reads as average.
local AVERAGE_LOW, AVERAGE_HIGH = 0.4, 0.6

-- A group's whole percent, rounded up and at least 1, so the player is never placed
-- in a smaller group. The offset keeps float noise (12.000000000000002) from
-- rounding up a step.
local function groupNumber(share)
    return math.max(1, math.ceil(share * 100 - 1e-9))
end

local function groupPercent(share)
    return groupNumber(share) .. "%"
end

-- The headline names the top and bottom 10%.
local EXTREME_PERCENT = 10

-- Luck for a table row: "top 3%", "average", "bottom 12%", "no kills"; before
-- it's rated, the share still dry, or "no chance yet" when no tracked kill could
-- drop it. Luck is the share of players with fewer uniques.
function format.LuckShort(result)
    if result.luck == nil then
        if result.kills == 0 then
            return "no kills"
        elseif result.dryShare and result.expected > 0 then
            return format.Percent(1 - result.dryShare) .. " still dry"
        end
        return "no chance yet"
    elseif result.luck > AVERAGE_HIGH then
        return "top " .. groupPercent(1 - result.luck)
    elseif result.luck < AVERAGE_LOW then
        return "bottom " .. groupPercent(result.luck)
    end
    return "average"
end

-- Luck as a sentence ("Spooned: top 3% luck" or "Cursed: bottom 2% luck" in the top
-- or bottom 10%), or, before it's rated, when it will be: "Luck: next unique or 40
-- kills".
function format.Luck(result)
    local text
    if not format.IsTracked(result) then
        text = "no tracked " .. unit(result) .. "s yet"
    elseif result.luck == nil then
        local more = result.killsToLuck
        local when = more and count(more, unit(result)) or ("more " .. unit(result) .. "s")
        text = "luck: next unique or " .. when
    else
        local short = format.LuckShort(result)
        text = (short == "average" and "about average" or short) .. " luck"
        if groupNumber(1 - result.luck) <= EXTREME_PERCENT then
            text = "spooned: " .. text
        elseif groupNumber(result.luck) <= EXTREME_PERCENT then
            text = "cursed: " .. text
        end
    end
    return text:sub(1, 1):upper() .. text:sub(2)
end

-- "12", "12+" when it may be longer, or "" when no tracked kill could drop it.
function format.DryCount(result)
    if result.dryKills == 0 and result.dryAtLeast then
        return ""
    end
    return format.Number(result.dryKills) .. (result.dryAtLeast and "+" or "")
end

-- "12 kills dry · 4% go this long", or "Unique on your last kill".
function format.Dry(result)
    if result.kills == 0 or format.DryCount(result) == "" then
        return ""
    end
    if result.dryKills == 0 then
        return "Unique on your last " .. unit(result)
    end
    local plural = (result.dryKills == 1 and not result.dryAtLeast) and "" or "s"
    local kills = format.DryCount(result) .. " " .. unit(result) .. plural
    return kills .. " dry · " .. format.Percent(1 - result.dryShare) .. " go this long"
end

-- "212 kills (+4 partial) · 2 uniques".
-- Kills, then (with details) partial kills and loot piles, then uniques.
local function trackedCounts(result, word, details)
    local text = count(result.kills, word)
    if details and (result.extraKills or 0) > 0 then
        text = text
            .. " (+"
            .. format.Number(result.extraKills)
            .. " "
            .. (result.extraLabel or "other")
            .. ")"
    end
    if details and result.piles then
        text = text .. " (" .. count(result.piles, "pile") .. ")"
    end
    return text .. " · " .. count(result.received, "unique")
end

-- "Tracked: 212 kills (+4 partial) · 2 uniques", with any loot piles ("40 kills (97
-- piles)"), or "" with none.
function format.Tracked(result)
    return format.IsTracked(result) and ("Tracked: " .. trackedCounts(result, unit(result), true))
        or ""
end

-- The same in a few words, for the panel, without partial kills or piles: "212 tracked
-- kills · 2 uniques".
function format.TrackedShort(result)
    return not format.IsTracked(result) and "" or trackedCounts(result, "tracked " .. unit(result))
end

-- The game's own totals, shown as facts but never used for luck. A stacked unique's
-- collection log count counts items, so it gets its own count before "other uniques".
function format.AllTime(result)
    if result.allTime == nil then
        return ""
    end
    local parts = { "All-time: " .. count(result.allTime.kills, "kill") }
    local stacks = result.allTime.stacks or {}
    for _, stack in ipairs(stacks) do
        table.insert(parts, count(stack.count, stack.word, stack.plural))
    end
    table.insert(parts, count(result.allTime.received, #stacks > 0 and "other unique" or "unique"))
    return table.concat(parts, " · ")
end

-- "Average player: 2.3 uniques", or "under 1 unique" below 1.
function format.Average(result)
    if not format.IsTracked(result) then
        return ""
    elseif result.expected < 1 then
        return "Average player: under 1 unique"
    end
    local average = string.format("%.1f", result.expected)
    return "Average player: " .. average .. (average == "1.0" and " unique" or " uniques")
end

-- The average player's drops of a unique: "2.3 drops", "1.0 drop", "0 drops",
-- or "<0.1 drops" when it would round to zero (the game's <lt> tag shows a "<").
function format.AverageShort(result)
    if result.expected == 0 then
        return "0 drops"
    elseif result.expected < 0.05 then
        return "<lt>0.1 drops"
    end
    local average = string.format("%.1f", result.expected)
    return average .. (average == "1.0" and " drop" or " drops")
end

return format

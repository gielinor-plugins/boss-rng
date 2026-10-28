-- The words and numbers Boss RNG shows the player. Plain Lua, so it can be tested
-- offline, and shared by every view so the wording lives in one place.

local format = {}

-- 1234567 gives "1,234,567".
function format.Number(n)
    local text = tostring(math.floor(n))
    local result = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (result:gsub("^,", ""))
end

-- "1 kill" or "5 kills".
local function count(n, word)
    return format.Number(n) .. " " .. word .. (n == 1 and "" or "s")
end

-- "bottom 12% luck" becomes "Bottom 12% luck", for a headline.
function format.Capitalize(text)
    return text:sub(1, 1):upper() .. text:sub(2)
end

-- A share from 0 to 1 as a whole percentage, rounded down ("4% go this long").
-- Below 1% shows as "under 1%".
function format.Percent(share)
    if share < 0.01 then
        return "under 1%"
    end
    return math.floor(share * 100) .. "%"
end

-- Luck between these shares reads as average.
local AVERAGE_LOW, AVERAGE_HIGH = 0.4, 0.6

-- A share as a whole percentage rounded up, at least 1%, so the player is never
-- placed in a smaller group than they're really in. The tiny offset keeps
-- float noise (0.12 * 100 = 12.000000000000002) from rounding up a whole step.
local function groupPercent(share)
    return math.max(1, math.ceil(share * 100 - 1e-9)) .. "%"
end

-- Luck in a few words, for a column headed "luck": "top 3%", "average",
-- "bottom 12%", or "no kills". Luck is the share of players with fewer uniques,
-- so the top group is everyone luckier than that share and the bottom group is
-- that share.
function format.LuckShort(result)
    if result.luck == nil then
        return "no kills"
    elseif result.luck > AVERAGE_HIGH then
        return "top " .. groupPercent(1 - result.luck)
    elseif result.luck < AVERAGE_LOW then
        return "bottom " .. groupPercent(result.luck)
    end
    return "average"
end

-- Luck as a sentence: "top 3% luck", "about average luck", "bottom 12% luck", or
-- "no kills yet".
function format.Luck(result)
    if result.luck == nil then
        return "no kills yet"
    end
    local short = format.LuckShort(result)
    return (short == "average" and "about average" or short) .. " luck"
end

-- A dry streak's kills: "12", "12+" when it may be longer (see stats), or "?"
-- when no kill has been tracked since a drop Boss RNG didn't see.
function format.DryCount(result)
    if result.dryAtLeast and result.dryKills == 0 then
        return "?"
    end
    return format.Number(result.dryKills) .. (result.dryAtLeast and "+" or "")
end

-- The dry streak: "12 kills dry · 4% go this long", "12+ kills dry · ...", or
-- "unique on your last kill". The percentage is the share of players who would
-- still be dry after as many kills.
function format.Dry(result)
    if result.kills == 0 then
        return ""
    end
    if result.dryKills == 0 then
        -- With no unique tracked yet, no kills tracked yet either.
        return result.dryAtLeast and "Dry streak: counted from your next kill" or "unique on your last kill"
    end
    local kills = format.DryCount(result) .. ((result.dryKills == 1 and not result.dryAtLeast) and " kill" or " kills")
    return kills .. " dry · " .. format.Percent(1 - result.dryShare) .. " go this long"
end

-- What the numbers are based on: "All-time: 576 kills · 7 uniques" once the
-- game's totals can be read, else "Tracked: ...", the kills and drops Boss RNG
-- has seen itself.
function format.Totals(result)
    return (result.allTime and "All-time: " or "Tracked: ") .. count(result.kills, "kill") .. " · " .. count(result.received, "unique")
end

-- How many uniques an average player would have after the same kills, to
-- compare with the player's own: "Average player: 2.3 uniques". Shown to one
-- decimal place, and below 1 as "under 1 unique". (Not "<1": the game reads "<"
-- as the start of a formatting tag and hides the rest of the text.)
function format.Average(result)
    if result.expected < 1 then
        return "Average player: under 1 unique"
    end
    local average = string.format("%.1f", result.expected)
    return "Average player: " .. average .. (average == "1.0" and " unique" or " uniques")
end

-- An average player's count in a few words, for table rows: "avg 2.3", or
-- "avg under 0.1" when it would round to zero.
function format.AverageShort(result)
    if result.expected < 0.05 then
        return "avg under 0.1"
    end
    return string.format("avg %.1f", result.expected)
end

-- A row's counts in a few words: "12 · avg 19.4" (see format.AverageShort).
function format.CountShort(result)
    return format.Number(result.received) .. " · " .. format.AverageShort(result)
end

return format

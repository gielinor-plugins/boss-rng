-- The words and numbers Boss RNG shows, shared by every view.

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

function format.Capitalize(text)
    return text:sub(1, 1):upper() .. text:sub(2)
end

-- "kill", or the boss's own unit ("chest").
local function unit(result)
    return result.unit or "kill"
end

local function untracked(result)
    return result.kills == 0 and (result.extraKills or 0) == 0
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

-- Rounded up, at least 1%, so the player is never placed in a smaller group.
-- The offset keeps float noise (12.000000000000002) from rounding up a step.
local function groupPercent(share)
    return math.max(1, math.ceil(share * 100 - 1e-9)) .. "%"
end

-- Luck for the table column: "top 3%", "average", "bottom 12%", "no kills";
-- before it's rated, the share still dry or "too early". Luck is the share
-- of players with fewer uniques.
function format.LuckShort(result)
    if result.luck == nil then
        if result.kills == 0 then
            return "no kills"
        elseif result.dryShare and result.expected > 0 then
            return format.Percent(1 - result.dryShare) .. " are still dry"
        end
        return "too early"
    elseif result.luck > AVERAGE_HIGH then
        return "top " .. groupPercent(1 - result.luck)
    elseif result.luck < AVERAGE_LOW then
        return "bottom " .. groupPercent(result.luck)
    end
    return "average"
end

-- Luck as a sentence, or until it's rated, when it will show:
-- "luck: next unique or 40 kills".
function format.Luck(result)
    if untracked(result) then
        return "no tracked " .. unit(result) .. "s yet"
    elseif result.luck == nil then
        local more = result.killsToLuck
        local when = more and count(more, unit(result)) or ("more " .. unit(result) .. "s")
        return "luck: next unique or " .. when
    end
    local short = format.LuckShort(result)
    return (short == "average" and "about average" or short) .. " luck"
end

-- "12", "12+" when it may be longer, or "?" when nothing is known.
function format.DryCount(result)
    if result.dryKills == 0 and result.dryAtLeast then
        return "?"
    end
    return format.Number(result.dryKills) .. (result.dryAtLeast and "+" or "")
end

-- "12 kills dry · 4% go this long", or "unique on your last kill".
function format.Dry(result)
    if result.kills == 0 then
        return ""
    end
    if result.dryKills == 0 then
        return "unique on your last " .. unit(result)
    end
    local plural = (result.dryKills == 1 and not result.dryAtLeast) and "" or "s"
    local kills = format.DryCount(result) .. " " .. unit(result) .. plural
    return kills .. " dry · " .. format.Percent(1 - result.dryShare) .. " go this long"
end

-- "212 kills (+4 partial) · 2 uniques".
local function trackedCounts(result, word)
    local extra = (result.extraKills or 0) > 0
        and (" (+" .. format.Number(result.extraKills) .. " " .. (result.extraLabel or "other") .. ")") or ""
    return count(result.kills, word) .. extra .. " · " .. count(result.received, "unique")
end

-- "Tracked: 212 kills (+4 partial) · 2 uniques", or "" with none.
function format.Tracked(result)
    return untracked(result) and "" or ("Tracked: " .. trackedCounts(result, unit(result)))
end

-- The same in a few words, for the panel: "212 tracked kills · 2 uniques".
function format.TrackedShort(result)
    return untracked(result) and "" or trackedCounts(result, "tracked " .. unit(result))
end

-- The game's own totals, shown as facts but never used for luck. A stacked
-- unique's log counts items, so it gets its own count before "other uniques".
function format.AllTime(result)
    if result.allTime == nil then
        return ""
    end
    local parts = { "Boss log: " .. count(result.allTime.kills, "kill") }
    local stacks = result.allTime.stacks or {}
    for _, stack in ipairs(stacks) do
        table.insert(parts, count(stack.count, stack.word))
    end
    table.insert(parts, count(result.allTime.received, #stacks > 0 and "other unique" or "unique"))
    return table.concat(parts, " · ")
end

-- "Average player: 2.3 uniques". Below 1 it says "under 1 unique", not "<1":
-- the game reads "<" as a formatting tag and hides the rest of the text.
function format.Average(result)
    if untracked(result) then
        return ""
    elseif result.expected < 1 then
        return "Average player: under 1 unique"
    end
    local average = string.format("%.1f", result.expected)
    return "Average player: " .. average .. (average == "1.0" and " unique" or " uniques")
end

-- "avg 2.3", "avg 0", or "avg under 0.1" when it would round to zero.
function format.AverageShort(result)
    if result.expected == 0 then
        return "avg 0"
    elseif result.expected < 0.05 then
        return "avg under 0.1"
    end
    return string.format("avg %.1f", result.expected)
end

-- "12 · avg 19.4".
function format.CountShort(result)
    return format.Number(result.received) .. " · " .. format.AverageShort(result)
end

return format

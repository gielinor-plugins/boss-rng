-- The words and numbers Boss RNG shows the player. Plain Lua, so it can be tested
-- offline, and shared by every view so the wording lives in one place.

local days = require("src/days")

local format = {}

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

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

-- What a boss's luck counts: "kill", or its own unit ("chest", see src/bosses.lua).
local function unit(result)
    return result.unit or "kill"
end

-- True if result has no tracked kills, in the kill counts or outside them.
local function untracked(result)
    return result.kills == 0 and (result.extraKills or 0) == 0
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

-- A day (see src/days.lua) as a date: "29 Oct 2026".
function format.Date(day)
    local year, month, date = days.ToDate(day)
    return date .. " " .. MONTHS[month] .. " " .. year
end

-- Luck in a few words, for a column headed "luck": "top 3%", "average",
-- "bottom 12%", "no kills", or "too early" until there are enough to rate it
-- (see stats.MIN_EXPECTED). Luck is the share of players with fewer uniques,
-- so the top group is everyone luckier than that share and the bottom group is
-- that share.
function format.LuckShort(result)
    if result.luck == nil then
        return result.kills == 0 and "no kills" or "too early"
    elseif result.luck > AVERAGE_HIGH then
        return "top " .. groupPercent(1 - result.luck)
    elseif result.luck < AVERAGE_LOW then
        return "bottom " .. groupPercent(result.luck)
    end
    return "average"
end

-- Luck as a sentence: "top 3% luck", "about average luck", "bottom 12% luck",
-- "no tracked kills yet", or until there are enough, when it will show: "luck
-- rating in about 40 kills". Bosses with their own unit use it ("chests").
function format.Luck(result)
    if untracked(result) then
        return "no tracked " .. unit(result) .. "s yet"
    elseif result.luck == nil then
        local more = result.killsToLuck
        return more and ("luck rating in about " .. count(more, unit(result)))
            or ("luck rating after more " .. unit(result) .. "s")
    end
    local short = format.LuckShort(result)
    return (short == "average" and "about average" or short) .. " luck"
end

-- A dry streak's tracked kills: "12", "12+" when it may be longer (see stats),
-- or "?" when nothing is tracked yet and kills before tracking aren't known.
function format.DryCount(result)
    if result.dryKills == 0 and result.dryAtLeast then
        return "?"
    end
    return format.Number(result.dryKills) .. (result.dryAtLeast and "+" or "")
end

-- The dry streak: "12 kills dry · 4% go this long", "12+ kills dry · ...", or
-- "unique on your last kill", in the boss's unit. The percentage is the share
-- of players who would still be dry after as many kills.
function format.Dry(result)
    if result.kills == 0 then
        return ""
    end
    if result.dryKills == 0 then
        return "unique on your last " .. unit(result)
    end
    local plural = (result.dryKills == 1 and not result.dryAtLeast) and "" or "s"
    return format.DryCount(result) .. " " .. unit(result) .. plural .. " dry · " .. format.Percent(1 - result.dryShare) .. " go this long"
end

-- Tracked kills, as count(n, word), with any kills outside the kill count
-- after them ("(+4 partial)"), then tracked uniques.
local function trackedCounts(result, word)
    local extra = (result.extraKills or 0) > 0
        and (" (+" .. format.Number(result.extraKills) .. " " .. (result.extraLabel or "other") .. ")") or ""
    return count(result.kills, word) .. extra .. " · " .. count(result.received, "unique")
end

-- What luck is based on, the kills and drops Boss RNG tracked: "Tracked: 212
-- kills (+4 partial) · 2 uniques", or "" with none (the headline says so).
function format.Tracked(result)
    return untracked(result) and "" or ("Tracked: " .. trackedCounts(result, unit(result)))
end

-- The same in a few words, for the panel: "212 tracked kills · 2 uniques".
function format.TrackedShort(result)
    return untracked(result) and "" or trackedCounts(result, "tracked " .. unit(result))
end

-- The game's own totals (kill counts and boss log counts), shown as facts and
-- never used for luck: "Boss log: 924 kills · 9 uniques", with stacked uniques
-- as their own counts ("· 184 spikes"), or "" until they can be read.
function format.AllTime(result)
    if result.allTime == nil then
        return ""
    end
    local parts = { "Boss log: " .. count(result.allTime.kills, "kill"), count(result.allTime.received, "unique") }
    for _, stack in ipairs(result.allTime.stacks or {}) do
        table.insert(parts, count(stack.count, stack.word))
    end
    return table.concat(parts, " · ")
end

-- How many uniques an average player would have after the same kills, to
-- compare with the player's own: "Average player: 2.3 uniques". Shown to one
-- decimal place, and below 1 as "under 1 unique". (Not "<1": the game reads "<"
-- as the start of a formatting tag and hides the rest of the text.)
function format.Average(result)
    if untracked(result) then
        return ""
    elseif result.expected < 1 then
        return "Average player: under 1 unique"
    end
    local average = string.format("%.1f", result.expected)
    return "Average player: " .. average .. (average == "1.0" and " unique" or " uniques")
end

-- An average player's count in a few words, for table rows: "avg 2.3", "avg 0"
-- with none expected, or "avg under 0.1" when it would round to zero.
function format.AverageShort(result)
    if result.expected == 0 then
        return "avg 0"
    elseif result.expected < 0.05 then
        return "avg under 0.1"
    end
    return string.format("avg %.1f", result.expected)
end

-- A row's counts in a few words: "12 · avg 19.4" (see format.AverageShort).
function format.CountShort(result)
    return format.Number(result.received) .. " · " .. format.AverageShort(result)
end

return format

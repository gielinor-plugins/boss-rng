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

-- The dry streak: "12 kills dry · 4% go this long", or "unique on your last kill".
-- The percentage is the share of players who would still be dry after as many kills.
function format.Dry(bossStats)
    if bossStats.kills == 0 then
        return ""
    end
    if bossStats.dryKills == 0 then
        return "unique on your last kill"
    end
    return count(bossStats.dryKills, "kill") .. " dry · " .. format.Percent(1 - bossStats.dryShare) .. " go this long"
end

-- A dry streak in a few words, for lists: "12 dry", or "unique last kill".
function format.DryShort(dryKills)
    if dryKills == 0 then
        return "unique last kill"
    end
    return format.Number(dryKills) .. " dry"
end

-- What the numbers are based on: "Tracked: 576 kills · 7 uniques", the kills
-- and drops Boss RNG has seen itself.
function format.Totals(result)
    return "Tracked: " .. count(result.kills, "kill") .. " · " .. count(result.received, "unique")
end

return format

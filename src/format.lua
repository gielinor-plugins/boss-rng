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

-- A share from 0 to 1 as a whole percentage, rounded down so the sentence it's in
-- stays true ("luckier than 48%"). Below 1% shows as "under 1%".
function format.Percent(share)
    if share < 0.01 then
        return "under 1%"
    end
    return math.floor(share * 100) .. "%"
end

-- The headline: "luckier than 48%", or "no kills yet".
function format.Luck(bossStats)
    if bossStats.luck == nil then
        return "no kills yet"
    end
    return "luckier than " .. format.Percent(bossStats.luck)
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

-- "576 kills · 7 uniques since install".
function format.Totals(bossStats)
    return count(bossStats.kills, "kill") .. " · " .. count(bossStats.received, "unique") .. " since install"
end

return format

-- A boss's tallies as data, and how they're saved. Plain Lua, so it can be
-- tested offline. src/tracker.lua keeps them up to date.
--
-- Tallies: { kills, dryFrom, items }. Keys are text, the only kind Jagex's saved
-- data examples use.
--   kills    { [mode name] = { [day] = kills } }, by day (see src/days.lua; 0 when
--            the day couldn't be read)
--   dryFrom  { [streak key] = start }: where each dry streak (the boss's, and each
--            unique's) starts, if not at the first tracked kill. A streak is the
--            kills since its start (tallies.Dry), so only its start is kept, not a
--            copy of its kills:
--              (no entry)        from the first tracked kill
--              { day, at }       from a drop: day, the latest day with kills
--                                then (0 if none), and at, the kills then on
--                                that day and on day 0, which later kills can
--                                still add to, { [mode] = { [day] = kills } }
--              { dry = kills }   counted kills, kept as they were (a version 4
--                                streak that couldn't be turned into a start)
--   items    { [item id] = drops }
-- Days only go forward, so kills after a start are on its day or later (or 0).

local tallies = {}

function tallies.Empty()
    return { kills = {}, dryFrom = {}, items = {} }
end

-- Adds n kills of a mode on a day to byMode, { [mode name] = { [day] = kills } }.
function tallies.AddKills(byMode, modeName, day, n)
    local byDay = byMode[modeName] or {}
    local key = tostring(day)
    byDay[key] = (byDay[key] or 0) + n
    byMode[modeName] = byDay
end

-- The total of { [mode name] = { [day] = kills } }.
function tallies.Total(byMode)
    local total = 0
    for _, byDay in pairs(byMode) do
        for _, n in pairs(byDay) do
            total = total + n
        end
    end
    return total
end

-- The latest day in byMode, ignoring day 0, or 0 if there's none.
local function latestDay(byMode)
    local latest = 0
    for _, byDay in pairs(byMode) do
        for key in pairs(byDay) do
            latest = math.max(latest, tonumber(key))
        end
    end
    return latest
end

-- The kills in byMode on day and on day 0, as { [mode] = { [day] = kills } },
-- less what's in minus (the same shape), keeping only counts above 0.
local function onStartDays(byMode, day, minus)
    local result = {}
    for mode, byDay in pairs(byMode) do
        for _, key in ipairs({ tostring(day), "0" }) do
            local n = (byDay[key] or 0) - ((minus[mode] or {})[key] or 0)
            if n > 0 then
                result[mode] = result[mode] or {}
                result[mode][key] = n
            end
        end
    end
    return result
end

-- A streak starting now, after the kills so far.
function tallies.StartNow(kills)
    local day = latestDay(kills)
    return { day = day, at = onStartDays(kills, day, {}) }
end

-- A streak's kills since its start, { [mode] = { [day] = kills } }: every kill
-- after its day, and on its day and day 0, the kills beyond those at its start.
-- No start means every kill.
function tallies.Since(kills, start)
    if start == nil then
        return kills
    elseif start.dry then
        return start.dry
    end
    local since = {}
    for mode, byDay in pairs(kills) do
        for key, n in pairs(byDay) do
            local day = tonumber(key)
            if day == start.day or day == 0 then
                n = n - ((start.at[mode] or {})[key] or 0)
            elseif day < start.day then
                n = 0
            end
            if n > 0 then
                since[mode] = since[mode] or {}
                since[mode][key] = n
            end
        end
    end
    return since
end

-- A dry streak's kills (see dryFrom).
function tallies.Dry(t, key)
    return tallies.Since(t.kills, t.dryFrom[key])
end

-- True if a and b, both { [mode] = { [day] = kills } }, have the same counts
-- (missing and 0 alike).
local function sameKills(a, b)
    for _, pair in ipairs({ { a, b }, { b, a } }) do
        for mode, byDay in pairs(pair[1]) do
            for key, n in pairs(byDay) do
                if n ~= ((pair[2][mode] or {})[key] or 0) then
                    return false
                end
            end
        end
    end
    return true
end

-- The start of a version 4 streak, dry, its counted kills since its start:
-- nil (from the first kill) if it's every kill, else from its earliest day
-- with kills (or after every kill, if it has none on a known day). Kept as
-- counted if no start gives exactly the same kills.
function tallies.StartOf(kills, dry)
    if sameKills(dry, kills) then
        return nil
    end
    local day = nil
    for _, byDay in pairs(dry) do
        for key in pairs(byDay) do
            local d = tonumber(key)
            if d > 0 and (day == nil or d < day) then
                day = d
            end
        end
    end
    day = day or latestDay(kills)
    local start = { day = day, at = onStartDays(kills, day, dry) }
    return sameKills(tallies.Since(kills, start), dry) and start or { dry = dry }
end

-- Kills by day as saved: "20756:13,20757:2", days in order. A string per mode
-- is far smaller saved than a table entry per day.
local function encodeDays(byDay)
    local keys = {}
    for key in pairs(byDay) do
        table.insert(keys, key)
    end
    table.sort(keys, function(a, b) return tonumber(a) < tonumber(b) end)
    local parts = {}
    for i, key in ipairs(keys) do
        parts[i] = key .. ":" .. string.format("%d", byDay[key])
    end
    return table.concat(parts, ",")
end

local function decodeDays(text)
    local byDay = {}
    for key, n in text:gmatch("(%d+):(%d+)") do
        byDay[key] = tonumber(n)
    end
    return byDay
end

-- Applies code to each mode's days in byMode, returning a new table.
local function eachMode(byMode, code)
    local result = {}
    for mode, days in pairs(byMode) do
        result[mode] = code(days)
    end
    return result
end

-- Tallies as saved: kills (and counted streaks) as text per mode.
function tallies.Encode(t)
    local dryFrom = {}
    for key, start in pairs(t.dryFrom) do
        dryFrom[key] = start.dry and { dry = eachMode(start.dry, encodeDays) } or start
    end
    return { kills = eachMode(t.kills, encodeDays), dryFrom = dryFrom, items = t.items }
end

-- Tallies from what Encode saved. (An early version 5 also listed the streaks
-- from the first kill, as dryFromFirst: no entry means the same now.)
function tallies.Decode(saved)
    local dryFrom = {}
    for key, start in pairs(saved.dryFrom or {}) do
        dryFrom[key] = start.dry and { dry = eachMode(start.dry, decodeDays) } or start
    end
    return { kills = eachMode(saved.kills or {}, decodeDays), dryFrom = dryFrom, items = saved.items or {} }
end

-- Tallies from version 4's, which kept each dry streak's kills.
function tallies.FromVersion4(old)
    local t = { kills = old.kills or {}, dryFrom = {}, items = old.items or {} }
    for key, dry in pairs(old.dry or {}) do
        t.dryFrom[key] = tallies.StartOf(t.kills, dry)
    end
    return t
end

return tallies

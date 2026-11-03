-- A boss's tallies, { kills, sums, dryFrom, items }, and how they're saved; tracker keeps
-- them up to date. Keys are text, the only kind Jagex's saved data examples use.
--   kills    { [mode key] = { [day] = kills } } (day 0 when it couldn't be read)
--   sums     { [name] = { [mode key] = { [day] = total } } }: values a kill event adds
--            up over each day's kills (sums in src/bosses.lua), for their averages
--   dryFrom  { [streak key] = start } for each dry streak (the boss's, and each
--            unique's), read as the kills since its start (tallies.Dry):
--              (no entry)        from the first tracked kill
--              { day, at }       from a drop: day, the latest day with kills then
--                                (0 if none), and at, the kills then on that day and 0
--   items    { [item id] = drops }
-- Days only go forward, so kills after a start are on its day or later (or 0).

local tallies = {}

function tallies.Empty()
    return { kills = {}, sums = {}, dryFrom = {}, items = {} }
end

local function add(byMode, modeKey, day, n)
    local byDay = byMode[modeKey] or {}
    local key = tostring(day)
    byDay[key] = (byDay[key] or 0) + n
    byMode[modeKey] = byDay
end

-- Adds n kills of a mode on day, and their sums (or nil).
function tallies.AddKills(t, modeKey, day, n, sums)
    add(t.kills, modeKey, day, n)
    for name, total in pairs(sums or {}) do
        t.sums[name] = t.sums[name] or {}
        add(t.sums[name], modeKey, day, total)
    end
end

-- The averages of a mode's sums over its kills on day, or nil without any.
function tallies.Means(t, modeKey, day)
    local key = tostring(day)
    local kills = (t.kills[modeKey] or {})[key]
    local means = nil
    for name, byMode in pairs(t.sums or {}) do
        local total = (byMode[modeKey] or {})[key]
        if total and kills then
            means = means or {}
            means[name] = total / kills
        end
    end
    return means
end

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

-- byMode's kills on day and day 0, keeping counts above 0.
local function onStartDays(byMode, day)
    local result = {}
    for mode, byDay in pairs(byMode) do
        for _, key in ipairs({ tostring(day), "0" }) do
            local n = byDay[key] or 0
            if n > 0 then
                result[mode] = result[mode] or {}
                result[mode][key] = n
            end
        end
    end
    return result
end

function tallies.StartNow(kills)
    local day = latestDay(kills)
    return { day = day, at = onStartDays(kills, day) }
end

-- A streak's kills since its start (nil: every kill).
local function since(kills, start)
    if start == nil then
        return kills
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

function tallies.Dry(t, key)
    return since(t.kills, t.dryFrom[key])
end

-- Kills by day as saved: "20756:13,20757:2", days in order. A string per mode is
-- far smaller than a table entry per day.
local function encodeDays(byDay)
    local keys = {}
    for key in pairs(byDay) do
        table.insert(keys, key)
    end
    table.sort(keys, function(a, b)
        return tonumber(a) < tonumber(b)
    end)
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

local function eachMode(byMode, code)
    local result = {}
    for mode, days in pairs(byMode) do
        result[mode] = code(days)
    end
    return result
end

-- Each sum's modes coded with code.
local function eachSum(sums, code)
    local result = {}
    for name, byMode in pairs(sums) do
        result[name] = eachMode(byMode, code)
    end
    return result
end

function tallies.Encode(t)
    return {
        kills = eachMode(t.kills, encodeDays),
        sums = next(t.sums) and eachSum(t.sums, encodeDays) or nil,
        dryFrom = t.dryFrom,
        items = t.items,
    }
end

function tallies.Decode(saved)
    return {
        kills = eachMode(saved.kills or {}, decodeDays),
        sums = eachSum(saved.sums or {}, decodeDays),
        dryFrom = saved.dryFrom or {},
        items = saved.items or {},
    }
end

return tallies

-- Days as whole numbers: days since 1 January 1970 (UTC), the game clock's
-- epoch. Tracked kills are saved by day, and boss rates change on a day. Plain
-- Lua, so it can be tested offline.

local days = {}

-- The day for minutes since 1 January 1970, as the game clock gives them.
function days.FromMinutes(minutes)
    return minutes // (24 * 60)
end

-- The day for a date, e.g. days.FromDate(2026, 11, 24). Uses the usual civil
-- calendar algorithm: years start in March, so leap days fall at the end.
function days.FromDate(year, month, day)
    year = month <= 2 and year - 1 or year
    local era = year // 400
    local yearOfEra = year - era * 400
    local dayOfYear = (153 * (month + (month > 2 and -3 or 9)) + 2) // 5 + day - 1
    local dayOfEra = yearOfEra * 365 + yearOfEra // 4 - yearOfEra // 100 + dayOfYear
    return era * 146097 + dayOfEra - 719468
end

return days

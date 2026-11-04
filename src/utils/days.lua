-- Days as whole numbers since 1 January 1970 (UTC), the game clock's epoch.

local days = {}

function days.FromMinutes(minutes)
    return minutes // (24 * 60)
end

function days.FromDate(year, month, day)
    year = month <= 2 and year - 1 or year
    local era = year // 400
    local yearOfEra = year - era * 400
    local dayOfYear = (153 * (month + (month > 2 and -3 or 9)) + 2) // 5 + day - 1
    local dayOfEra = yearOfEra * 365 + yearOfEra // 4 - yearOfEra // 100 + dayOfYear
    return era * 146097 + dayOfEra - 719468
end

return days

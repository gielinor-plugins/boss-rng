-- Table helpers.

local tables = {}

-- A new table with every key of each table given, later tables winning (nil ones skipped).
function tables.Merge(...)
    local merged = {}
    for i = 1, select("#", ...) do
        for key, value in pairs(select(i, ...) or {}) do
            merged[key] = value
        end
    end
    return merged
end

return tables

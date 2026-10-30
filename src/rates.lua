-- A boss's drop rates over time, as named values (rates.History). Its rolls are
-- built from the values (see src/bosses.lua), and each tracked kill uses the
-- version of its day. Plain Lua, so it can be tested offline.

local rates = {}

local History = {}
History.__index = History

-- A history from versions, oldest first: the first lists every value; each
-- later one has since, the day its update went live (see src/updates.lua), and
-- only the values that changed, which it writes over the version before. A
-- version whose update isn't live yet (since = false) is left out.
function rates.History(versions)
    local history, current = setmetatable({ versions = {} }, History), {}
    for i, version in ipairs(versions) do
        if i == 1 or version.since then
            local values = {}
            for key, value in pairs(current) do
                values[key] = value
            end
            for key, value in pairs(version) do
                if key ~= "since" then
                    values[key] = value
                end
            end
            current = values
            table.insert(history.versions, { since = version.since or 0, values = values })
        end
    end
    return history
end

-- The values on a day: the newest version live by then. A day of 0 or nil (not
-- known) gets the newest. The same table is returned for every day of a
-- version, so rolls built from it can be reused.
function History:On(day)
    for i = #self.versions, 1, -1 do
        local version = self.versions[i]
        if not day or day == 0 or day >= version.since then
            return version.values
        end
    end
    return self.versions[1].values
end

return rates

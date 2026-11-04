-- Drop rates over time, as named values in src/core/rates/, one file per game
-- update, oldest first (UPDATES). base.lua has each boss's published rates when it
-- was added; each later file has the day its update went live and only the values
-- it changed, by boss key. Each tracked kill uses the values in effect on its day,
-- looked up when stats are shown, so a plugin update released after a game update still
-- rates every kill since at the new values.

local rates = {}

rates.UPDATES = { "base", "late_game_rebalance" }

local History = {}
History.__index = History

-- Errors on an unknown name, so a misspelled rate fails loudly instead of reading nil.
local STRICT = setmetatable({}, {
    __index = function(_, name)
        error("No rate named " .. tostring(name), 2)
    end,
})

-- A history from versions, oldest first, each { since, values }: since is the day it
-- went live (nil for the first; false if its date isn't known yet). Missing values come
-- from the version before.
function rates.History(versions)
    local history, previous = setmetatable({ versions = {} }, History), STRICT
    for _, version in ipairs(versions) do
        if version.since ~= false then
            local values = setmetatable({}, { __index = previous })
            for name, value in pairs(version.values) do
                values[name] = value
            end
            table.insert(history.versions, { since = version.since or 0, values = values })
            previous = values
        end
    end
    return history
end

-- The values in effect on day: the newest version live by then (0 or nil: the newest of
-- all). A version returns the same table every day, so rolls built from it can be
-- reused.
function History:On(day)
    for i = #self.versions, 1, -1 do
        local version = self.versions[i]
        if not day or day == 0 or day >= version.since then
            return version.values
        end
    end
    return self.versions[1].values
end

local histories = {} -- by boss key, built once

-- A boss's history from every update file, or nil if none has its key.
function rates.For(key)
    if key == nil then
        return nil
    elseif histories[key] == nil then
        local versions = {}
        for _, name in ipairs(rates.UPDATES) do
            local update = require("src/core/rates/" .. name)
            if update.rates[key] then
                table.insert(versions, { since = update.day, values = update.rates[key] })
            end
        end
        histories[key] = #versions > 0 and rates.History(versions) or false
    end
    return histories[key] or nil
end

return rates

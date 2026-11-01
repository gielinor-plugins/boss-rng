-- Drop rates over time, as named values in the files of src/rates/, one per
-- game update, oldest first (UPDATES): base.lua has each boss's published rates
-- when it was added, and each later file the day its update went live and only
-- the values it changed, by boss key. A boss's rolls are built from its values
-- (see src/bosses.lua), and each tracked kill uses the values of its day.
--
-- Rates are worked out from each kill's saved day whenever they're shown, so a
-- plugin update that ships after a game update re-rates every kill since.
-- Plain Lua, so it can be tested offline.

local rates = {}

-- The update files in src/rates/, oldest first.
rates.UPDATES = { "base", "late_game_rebalance" }

local History = {}
History.__index = History

-- Values that error on a name they don't have, so a misspelled rate fails
-- loudly instead of reading as nil.
local STRICT = setmetatable({}, { __index = function(_, name) error("No rate named " .. tostring(name), 2) end })

-- A history from versions, oldest first, each { since, values }: since is the
-- day its update went live (nil for the first, false for an update not live
-- yet, which is left out). Each version holds only its own values and looks up
-- the rest in the version before it.
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

local histories = {} -- by boss key, built once

-- A boss's history, from every update file's values for its key, or nil if no
-- file has any (or there's no key).
function rates.For(key)
    if key == nil then
        return nil
    elseif histories[key] == nil then
        local versions = {}
        for _, name in ipairs(rates.UPDATES) do
            local update = require("src/rates/" .. name)
            if update.rates[key] then
                table.insert(versions, { since = update.day, values = update.rates[key] })
            end
        end
        histories[key] = #versions > 0 and rates.History(versions) or false
    end
    return histories[key] or nil
end

return rates

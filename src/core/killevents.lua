-- Kills told apart by what the game shows around them (killEvents in src/bosses.lua):
-- values read at the kill, a value's last before the game resets it (lasts), whether
-- a count rose in the kill's tick (rises), the player's loot piles (piles) and values
-- added up by day (sums). Vars come through gamevars, the only module that reads them.

local piles = require("src/core/piles")

local killevents = {}

local risen = {} -- each kill event's rises seen this tick

-- The mode a kill event or claim says the kill was, and the values it read, given
-- value(name) and a claim var's old value; nil if a value can't be read or it gives none.
function killevents.Mode(boss, event, value, old, kept, rose)
    local values = {}
    for key, name in pairs(event.reads or {}) do
        values[key] = value(name)
        if values[key] == nil then
            return nil
        end
    end
    for key in pairs(event.lasts or {}) do
        values[key] = kept[key] -- nil if none was seen
    end
    for key in pairs(event.rises or {}) do
        values[key] = rose[key] == true
    end
    if event.piles then
        values.piles = piles.Count()
    end
    local key = event.mode(values, old)
    return key and boss.modeFor(key), values
end

-- The values a kill event adds up by day, or nil.
local function sumsOf(event, values)
    if event.sums == nil then
        return nil
    end
    local sums = {}
    for _, key in ipairs(event.sums) do
        sums[key] = values[key]
    end
    return sums
end

-- Watches a boss's kill event through gamevars' reader { watch, follow, value };
-- report(mode, sums) gets each kill it gives a mode.
function killevents.Add(boss, event, reader, report)
    piles.Watch(event.piles or {})
    local kept = {} -- each of event.lasts' last value above 0 since the last kill
    for key, name in pairs(event.lasts or {}) do
        reader.follow(name, function(now)
            if now > 0 then
                kept[key] = now
            end
        end)
    end
    local rose = {} -- each of event.rises that rose this tick
    table.insert(risen, rose)
    for key, name in pairs(event.rises or {}) do
        reader.watch(name, "rises", function()
            rose[key] = true
        end)
    end
    reader.watch(event.var, "kills", function()
        local mode, values = killevents.Mode(boss, event, reader.value, nil, kept, rose)
        for key in pairs(kept) do
            kept[key] = nil
        end
        if mode then
            report(mode, sumsOf(event, values))
        end
    end, event.mask)
end

-- Forgets this tick's rises, after its kills are reported.
function killevents.EndTick()
    for _, rose in ipairs(risen) do
        for key in pairs(rose) do
            rose[key] = nil
        end
    end
end

function killevents.Clear()
    risen = {}
end

return killevents

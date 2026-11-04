-- Kill events (killEvents in src/bosses.lua): kills told apart by what the game shows
-- around them. A kill event can read values at the kill (reads), a value's last before
-- the game resets it (lasts), whether a count rose in the kill's tick (rises), the
-- player's loot piles (pileItems), and values to add up by day (sums). game_vars wires
-- each boss's kill events in.

local piles = require("src/core/piles")
local varWatch = require("src/core/var_watch")

local killEvents = {}

local risen = {} -- each kill event's rises seen this tick

-- The mode a kill event or claim gives the kill, and the values it read. old is a claim
-- var's old value. Nil if a value can't be read, or the event gives no mode.
function killEvents.Mode(boss, event, old, kept, rose)
    local values = {}
    for key, name in pairs(event.reads or {}) do
        values[key] = varWatch.Value(name)
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
    if event.pileItems then
        values.piles = piles.Count()
    end
    local key = event.mode(values, old)
    return key and boss.modes[key], values
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

-- Watches a boss's kill event; report(mode, sums) gets each kill it gives a mode.
function killEvents.Add(boss, event, report)
    piles.Watch(event.pileItems or {})
    local kept = {} -- each of event.lasts' last value above 0 since the last kill
    for key, name in pairs(event.lasts or {}) do
        varWatch.Follow(name, function(now)
            if now > 0 then
                kept[key] = now
            end
        end)
    end
    local rose = {} -- each of event.rises that rose this tick
    table.insert(risen, rose)
    for key, name in pairs(event.rises or {}) do
        varWatch.Watch(name, "rises", function()
            rose[key] = true
        end)
    end
    varWatch.Watch(event.var, "kills", function()
        local mode, values = killEvents.Mode(boss, event, nil, kept, rose)
        for key in pairs(kept) do
            kept[key] = nil
        end
        if mode then
            report(mode, sumsOf(event, values))
        end
    end, event.mask)
end

-- Forgets this tick's rises, after its kills are reported.
function killEvents.EndTick()
    for _, rose in ipairs(risen) do
        for key in pairs(rose) do
            rose[key] = nil
        end
    end
end

function killEvents.Clear()
    risen = {}
end

return killEvents

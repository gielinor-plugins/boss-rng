-- What the views show: the bosses with kills, and the picked one with its
-- all-time totals, readings, stats, table rows and notes.

local bosses = require("src/bosses")
local gamevars = require("src/core/gamevars")
local stats = require("src/core/stats")
local tracker = require("src/core/tracker")
local common = require("src/ui/common")

local state = {}

-- A boss's uniques as table rows, { id, item, name } each: unluckiest first,
-- then by name. A group uses its name and first item's icon.
function state.Rows(result)
    local rows = {}
    for itemID, item in pairs(result.items) do
        local name = item.group and item.group.name or common.ItemName(itemID)
        table.insert(rows, { id = itemID, item = item, name = name })
    end
    table.sort(rows, function(a, b)
        local luckA, luckB = a.item.luck or 1, b.item.luck or 1
        if luckA ~= luckB then
            return luckA < luckB
        end
        return a.name < b.name
    end)
    return rows
end

-- A boss's assumptions: its list, or what its function gives for the readings.
local function assumptions(entry)
    local own = entry.boss.assumptions
    return type(own) == "function" and own(entry.readings) or own
end

-- The Info tab's sections, { title, lines } each, when they have lines: the
-- boss's assumptions, then its tip.
function state.Notes(entry)
    local sections = {}
    local all = {
        { "Luck Assumptions", assumptions(entry) },
        { "Tips", { entry.boss.tip } }, -- empty without one
    }
    for _, section in ipairs(all) do
        if #section[2] > 0 then
            table.insert(sections, { title = section[1], lines = section[2] })
        end
    end
    return sections
end

local selectedKey = nil -- the boss picked in a dropdown
local lastKillKey = nil -- the last boss killed when the views were last drawn


-- Bosses with tracked or all-time kills, by name, each { boss, tallies }.
local function bossesWithKills()
    local list = {}
    for _, boss in ipairs(bosses) do
        local tallies = tracker.Tallies(boss)
        if tallies and (tracker.Total(tallies.kills) > 0
            or (gamevars.AllTimeKills(boss) or 0) > 0) then
            table.insert(list, { boss = boss, tallies = tallies })
        end
    end
    table.sort(list, function(a, b)
        return a.boss.name < b.boss.name
    end)
    return list
end

-- A table's values as text in key order, for telling whether inputs changed.
local function asText(values)
    local keys = {}
    for key in pairs(values or {}) do
        table.insert(keys, tostring(key))
    end
    table.sort(keys)
    local parts = {}
    for i, key in ipairs(keys) do
        local value = values[key] or values[tonumber(key)]
        parts[i] = key .. "=" .. tostring(value)
    end
    return table.concat(parts, ",")
end

local cached = { inputs = nil, stats = nil }

-- Fills in an entry's all-time totals, readings (the values its boss reads from the
-- game, see reads in src/bosses.lua) and stats, reusing the last stats while their
-- inputs are unchanged.
local function withStats(entry)
    entry.allTime = gamevars.AllTime(entry.boss)
    local allTime = entry.allTime or {}
    entry.readings = allTime.values or {}
    local inputs = table.concat({
        entry.boss.key, tracker.Changes(),
        asText(allTime.kills), asText(allTime.items), asText(entry.readings),
    }, "|")
    if cached.inputs ~= inputs then
        cached.inputs, cached.stats = inputs, stats.ForBoss(entry)
    end
    entry.stats = cached.stats
    entry.rows, entry.notes = state.Rows(entry.stats), state.Notes(entry)
    return entry
end

-- The boss picked in a dropdown, else the last killed, else the first.
-- A kill at another boss clears the dropdown pick (a reset clearing the last
-- boss killed doesn't).
local function selectedIndex(list)
    local last = tracker.LastBossKey()
    if last ~= nil and last ~= lastKillKey then
        lastKillKey = last
        selectedKey = nil
    end
    return common.IndexOf(list, selectedKey) or common.IndexOf(list, last) or 1
end

function state.Pick(key)
    selectedKey = key
end

-- The bosses with kills, and the picked one's index (nil without kills). Only
-- that entry has allTime, readings, stats, rows and notes.
function state.Current()
    local list = bossesWithKills()
    local selected = #list > 0 and selectedIndex(list) or nil
    if selected then
        withStats(list[selected])
    end
    return list, selected
end

return state

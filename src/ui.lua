-- Boss RNG's UI: the ribbon panel (src/ui/panel.lua) and the details window
-- (src/ui/window.lua). This module decides which boss the views show and
-- redraws them when that, the player's picks or tallies change.
-- All UI code lives in src/ui.lua and src/ui/, using Jagex's native components.

local bosses = require("src/bosses")
local choices = require("src/choices")
local gamevars = require("src/gamevars")
local safe = require("src/safe")
local stats = require("src/stats")
local tracker = require("src/tracker")
local panel = require("src/ui/panel")
local window = require("src/ui/window")

local bossUi = {}

local REF = "bossrng_ui"
local REDRAW_REF = "bossrng_ui_redraw"

local selectedKey = nil -- the boss picked in a dropdown
local lastKillKey = nil -- the last boss killed when we last drew
local currentState -- defined below, after the actions it refers to

-- A boss's picks for its choices, with, once the game is read, the values it
-- reads (see src/bosses.lua).
local function picksFor(boss, allTime)
    local picks = choices.For(boss)
    for key, value in pairs(allTime and allTime.values or {}) do
        picks[key] = value
    end
    return picks
end

-- Bosses with tracked kills or all-time kills from the game, in alphabetical
-- order, each { boss, tallies }. Only the picked boss's stats are worked out
-- (see withStats), so listing reads only kill counts.
local function bossesWithKills()
    local list = {}
    for _, boss in ipairs(bosses) do
        local tallies = tracker.Tallies(boss)
        if tallies and (tracker.Total(tallies.kills) > 0 or (gamevars.AllTimeKills(boss) or 0) > 0) then
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

-- The last stats worked out, and what they were worked out from.
local cached = { inputs = nil, stats = nil }

-- Fills in an entry's all-time totals, picks and stats. Stats are worked out
-- again only when something they're worked out from changed: the boss, its
-- tallies (tracker.Changes), the game's totals or the picks. Nothing is kept
-- but the last result, and nothing from it is saved.
local function withStats(entry)
    entry.allTime = gamevars.AllTime(entry.boss)
    entry.picks = picksFor(entry.boss, entry.allTime)
    local allTime = entry.allTime or {}
    local inputs = table.concat({
        entry.boss.key, tracker.Changes(), asText(allTime.kills), asText(allTime.items), asText(entry.picks),
    }, "|")
    if cached.inputs ~= inputs then
        cached.inputs, cached.stats = inputs, stats.ForBoss(entry)
    end
    entry.stats = cached.stats
    return entry
end

-- The index in list of the boss with this key, or nil.
local function indexOf(list, key)
    for i, entry in ipairs(list) do
        if entry.boss.key == key then
            return i
        end
    end
    return nil
end

-- The picked boss's index in list: the boss picked in a dropdown, else the boss
-- killed most recently, else the first. A kill at another boss picks that boss.
local function selectedIndex(list)
    local last = tracker.LastBossKey()
    if last ~= lastKillKey then
        lastKillKey = last
        selectedKey = nil
    end
    return indexOf(list, selectedKey) or indexOf(list, last) or 1
end

-- Redraws the panel if it's open. If drawing fails, it shows one plain line.
local function redrawPanel()
    if panel.IsOpen() and not safe.Call("drawing the panel", panel.Draw, currentState()) then
        safe.Call("drawing the panel error", panel.ShowError)
    end
end

-- Opens or redraws the window. If drawing fails, it closes rather than staying
-- half drawn.
local function showWindow()
    if not safe.Call("drawing the window", window.Draw, currentState()) then
        window.Close()
    end
end

local function redrawAll()
    redrawPanel()
    if window.IsOpen() then
        showWindow()
    end
end

-- Redraws the views on the next tick, so a component isn't destroyed while its
-- own event is still running.
local function redrawSoon()
    Event.Logic.Subscribe(REDRAW_REF, function()
        Event.Logic.Unsubscribe(REDRAW_REF)
        redrawAll()
    end)
end

-- Shows the picked boss in both views.
local function pick(key)
    selectedKey = key
    redrawSoon()
end

-- Saves the player's pick for one of a boss's choices, and redraws with it.
local function choose(boss, choice, value)
    choices.Set(boss, choice, value)
    redrawSoon()
end

-- What the views draw: the bosses with kills (list; only the picked one has
-- allTime, picks and stats), the index of the picked boss (selected, nil without kills),
-- what to do when the player picks a boss (onPick), picks for one of its
-- choices (onChoose) or asks for details (onDetails), and how to redraw after a
-- change made in a view (onRedraw).
function currentState()
    local list = bossesWithKills()
    local selected = #list > 0 and selectedIndex(list) or nil
    if selected then
        withStats(list[selected])
    end
    return {
        list = list,
        selected = selected,
        onPick = pick,
        onChoose = choose,
        onDetails = showWindow,
        onRedraw = redrawSoon,
    }
end

-- The game clears the panel and fires this each time it opens or is resized.
local function onContentLayerReady(event)
    panel.Attach(event.component)
    redrawPanel()
end

-- Redraws the views, e.g. once all-time totals can be read after login.
bossUi.Refresh = redrawAll

function bossUi.Start()
    tracker.OnChange(redrawAll)
    Event.ContentLayerReady.Subscribe(REF, onContentLayerReady)
end

function bossUi.Stop()
    Event.ContentLayerReady.Unsubscribe(REF)
    Event.Logic.Unsubscribe(REDRAW_REF)
    panel.Detach()
    window.Close()
end

return bossUi

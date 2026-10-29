-- Boss RNG's UI: the ribbon panel (src/ui/panel.lua), the Details window
-- (src/ui/window.lua) and the settings page (src/ui/settings.lua). This module
-- decides which boss the views show and redraws them when that, the player's
-- picks or tallies change.
-- All UI code lives in src/ui.lua and src/ui/, using Jagex's native components.

local bosses = require("src/bosses")
local choices = require("src/choices")
local gamevars = require("src/gamevars")
local safe = require("src/safe")
local stats = require("src/stats")
local tracker = require("src/tracker")
local panel = require("src/ui/panel")
local settings = require("src/ui/settings")
local window = require("src/ui/window")

local bossUi = {}

local REF = "bossrng_ui"
local REDRAW_REF = "bossrng_ui_redraw"

local selectedKey = nil -- the boss picked in a dropdown
local lastKillKey = nil -- the last boss killed when we last drew
local currentState -- defined below, after the actions it refers to

-- A boss's picks for its choices, with, once the game is read, the values it
-- reads and its kills without Boss RNG (see src/bosses.lua).
local function picksFor(boss, tallies, allTime)
    local picks = choices.For(boss)
    if allTime then
        for key, value in pairs(allTime.values) do
            picks[key] = value
        end
        picks.untrackedKills, picks.untracked = stats.Untracked(boss, tallies, allTime)
    end
    return picks
end

-- Bosses with kills, in alphabetical order, each with the player's picks for
-- its choices and its stats; luck over all of them; and the pooled uniques (see
-- stats.Pools).
local function bossesWithKills()
    local entries = {}
    for _, boss in ipairs(bosses) do
        local tallies = tracker.Tallies(boss)
        if tallies then
            local allTime = gamevars.AllTime(boss)
            table.insert(entries, { boss = boss, tallies = tallies, picks = picksFor(boss, tallies, allTime),
                allTime = allTime })
        end
    end
    local pools = stats.Pools(entries, choices.Splits())
    for _, entry in ipairs(entries) do
        entry.stats = stats.ForBoss(entry, pools)
    end

    local list, allStats = {}, {}
    for _, entry in ipairs(entries) do
        if entry.stats.kills > 0 then
            table.insert(list, entry)
            table.insert(allStats, entry.stats)
        end
    end
    table.sort(list, function(a, b)
        return a.boss.name < b.boss.name
    end)
    return list, stats.Overall(allStats), pools
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

-- Redraws the settings page if it's open, or one plain line if drawing fails.
local function redrawSettings()
    if settings.IsOpen() and not safe.Call("drawing the settings", settings.Draw, currentState()) then
        safe.Call("drawing the settings error", settings.ShowError)
    end
end

local function redrawAll()
    redrawPanel()
    redrawSettings()
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

-- Saves how many of a pooled unique's untracked drops (pool, see stats.Pools)
-- came from boss, the rest from the other boss listing it, or clears the split
-- with nil. Then redraws with it.
local function split(pool, itemID, boss, count)
    local counts = nil
    if count then
        counts = {}
        for _, sharer in ipairs(pool.sharers) do
            counts[sharer.key] = sharer == boss and count or pool.untracked - count
        end
    end
    choices.SetSplit(itemID, counts)
    redrawSoon()
end

-- What the views draw: the bosses with kills (list), luck over all of them
-- (overall), the pooled uniques (pools, see stats.Pools), the index of the
-- picked boss (selected, nil without kills), what to do when the player picks a
-- boss (onPick), picks for one of its choices (onChoose), splits a pooled
-- unique (onSplit) or asks for details (onDetails), and how to redraw after a
-- change made in a view (onRedraw).
function currentState()
    local list, overall, pools = bossesWithKills()
    return {
        list = list,
        overall = overall,
        pools = pools,
        selected = #list > 0 and selectedIndex(list) or nil,
        onPick = pick,
        onChoose = choose,
        onSplit = split,
        onDetails = showWindow,
        onRedraw = redrawSoon,
    }
end

-- The game clears the panel and fires this each time it opens or is resized.
local function onContentLayerReady(event)
    panel.Attach(event.component)
    redrawPanel()
end

-- The game clears the settings page and fires this each time it opens.
local function onSettingsLayerReady(event)
    settings.Attach(event.component)
    redrawSettings()
end

-- Redraws the views, e.g. once all-time totals can be read after login.
bossUi.Refresh = redrawAll

function bossUi.Start()
    tracker.OnChange(redrawAll)
    Event.ContentLayerReady.Subscribe(REF, onContentLayerReady)
    Event.SettingsLayerReady.Subscribe(REF, onSettingsLayerReady)
end

function bossUi.Stop()
    Event.ContentLayerReady.Unsubscribe(REF)
    Event.SettingsLayerReady.Unsubscribe(REF)
    Event.Logic.Unsubscribe(REDRAW_REF)
    panel.Detach()
    settings.Detach()
    window.Close()
end

return bossUi

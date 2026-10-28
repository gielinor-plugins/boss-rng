-- Boss RNG's UI: the ribbon panel (src/ui/panel.lua) and the Details window
-- (src/ui/window.lua). This module decides which boss both views show and
-- redraws them when that or the player's tallies change.
-- All UI code lives in src/ui.lua and src/ui/, using Jagex's native components.

local bosses = require("src/bosses")
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

-- Bosses with kills, each with its stats, in alphabetical order. The game's
-- dropdown lists its entries alphabetically and reports picks by position, so
-- the list must be in the same order.
local function bossesWithKills()
    local list = {}
    for _, boss in ipairs(bosses) do
        local result = stats.ForBoss(boss, tracker.Tallies(boss))
        if result and result.kills > 0 then
            table.insert(list, { boss = boss, stats = result })
        end
    end
    table.sort(list, function(a, b)
        return a.boss.name < b.boss.name
    end)
    return list
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

-- Redraws both views on the next tick, so a component isn't destroyed while its
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

-- What both views draw: the bosses with kills (list), the index of the picked
-- one (selected, nil without kills), and what to do when the player picks a
-- boss (onPick) or asks for details (onDetails), and how to redraw after a
-- change made in a view (onRedraw).
function currentState()
    local list = bossesWithKills()
    return {
        list = list,
        selected = #list > 0 and selectedIndex(list) or nil,
        onPick = pick,
        onDetails = showWindow,
        onRedraw = redrawSoon,
    }
end

-- The game clears the panel and fires this each time it opens or is resized.
local function onContentLayerReady(event)
    panel.Attach(event.component)
    redrawPanel()
end

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

-- Boss RNG's UI: picks the boss the panel, details window and settings page
-- show, and redraws them when that, the picks or tallies change.

local bosses = require("src/bosses")
local choices = require("src/core/choices")
local gamevars = require("src/core/gamevars")
local safe = require("src/utils/safe")
local stats = require("src/core/stats")
local tracker = require("src/core/tracker")
local panel = require("src/ui/panel")
local settings = require("src/ui/settings")
local window = require("src/ui/window")

local bossUi = {}

local REF = "bossrng_ui"
local REDRAW_REF = "bossrng_ui_redraw"

local selectedKey = nil -- the boss picked in a dropdown
local lastKillKey = nil -- the last boss killed when we last drew
local currentState

-- A boss's picks, overridden by any values read from the game.
local function picksFor(boss, allTime)
    local picks = choices.For(boss)
    for key, value in pairs(allTime and allTime.values or {}) do
        picks[key] = value
    end
    return picks
end

-- Bosses with tracked or all-time kills, by name, each { boss, tallies }.
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

local cached = { inputs = nil, stats = nil }

-- Fills in an entry's all-time totals, picks and stats, reusing the last
-- stats while their inputs are unchanged.
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

local function indexOf(list, key)
    for i, entry in ipairs(list) do
        if entry.boss.key == key then
            return i
        end
    end
    return nil
end

-- The boss picked in a dropdown, else the last killed, else the first.
-- A kill at another boss clears the dropdown pick.
local function selectedIndex(list)
    local last = tracker.LastBossKey()
    if last ~= lastKillKey then
        lastKillKey = last
        selectedKey = nil
    end
    return indexOf(list, selectedKey) or indexOf(list, last) or 1
end

local function redrawPanel()
    if panel.IsOpen() and not safe.Call("drawing the panel", panel.Draw, currentState()) then
        safe.Call("drawing the panel error", panel.ShowError)
    end
end

-- Closes the window if drawing fails, rather than leave it half drawn.
local function showWindow()
    if not safe.Call("drawing the window", window.Draw, currentState()) then
        window.Close()
    end
end

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

-- Redraws after ticks logic ticks (default 1), so a component isn't destroyed
-- during its own event. Calling again restarts the wait.
local function redrawSoon(ticks)
    local left = ticks or 1
    Event.Logic.Subscribe(REDRAW_REF, function()
        left = left - 1
        if left <= 0 then
            Event.Logic.Unsubscribe(REDRAW_REF)
            redrawAll()
        end
    end)
end

local SLIDER_SETTLE_TICKS = 25 -- half a second without moving

local function pick(key)
    selectedKey = key
    redrawSoon()
end

-- Redraws once the slider settles, so it isn't rebuilt while being dragged.
local function choose(boss, choice, value)
    choices.Set(boss, choice, value)
    redrawSoon(SLIDER_SETTLE_TICKS)
end

-- What the views draw. Only list[selected] has allTime, picks and stats;
-- selected is nil without kills.
function currentState()
    local list = bossesWithKills()
    local selected = #list > 0 and selectedIndex(list) or nil
    if selected then
        withStats(list[selected])
    end
    return {
        list = list,
        bosses = bosses,
        selected = selected,
        onPick = pick,
        onChoose = choose,
        onDetails = showWindow,
        onRedraw = redrawSoon,
    }
end

-- The game clears the settings page and fires this each time it opens.
local function onSettingsLayerReady(event)
    settings.Attach(event.component)
    redrawSettings()
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

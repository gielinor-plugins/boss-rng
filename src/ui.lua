-- Boss RNG's UI: draws the panel, details window and settings page, and redraws
-- them when the picked boss or the tallies change.

local panel = require("src/ui/panel")
local safe = require("src/utils/safe")
local settings = require("src/ui/settings")
local tracker = require("src/core/tracker")
local viewState = require("src/ui/state")
local window = require("src/ui/window")

local bossUi = {}

local REF = "bossrng_ui"
local REDRAW_REF = "bossrng_ui_redraw"

local currentState -- defined below
local drawn = {} -- [view] = what it last drew (see shownKey)

-- What the panel and window show: the boss list, and the shown boss's inputs.
local function shownKey(state)
    local parts = {}
    for i, entry in ipairs(state.list) do
        parts[i] = entry.boss.key
    end
    local shown = state.list[state.selected]
    table.insert(parts, shown and shown.inputs or "")
    return table.concat(parts, ",")
end

local function drawPanel(state)
    if safe.Call("drawing the panel", panel.Draw, state) then
        drawn.panel = shownKey(state)
    else
        safe.Call("drawing the panel error", panel.ShowError)
    end
end

-- Closes the window if drawing fails, rather than leave it half drawn.
local function drawWindow(state)
    if safe.Call("drawing the window", window.Draw, state) then
        drawn.window = shownKey(state)
    else
        window.Close()
    end
end

local function showWindow()
    drawWindow(currentState())
end

-- The settings page is small and rarely open, so it's always redrawn.
local function drawSettings(state)
    if not safe.Call("drawing the settings", settings.Draw, state) then
        safe.Call("drawing the settings error", settings.ShowError)
    end
end

-- Redraws the open views, skipping the panel and window when what they show is unchanged.
local function redrawAll()
    local state = currentState()
    local key = shownKey(state)
    if panel.IsOpen() and drawn.panel ~= key then
        drawPanel(state)
    end
    if settings.IsOpen() then
        drawSettings(state)
    end
    if window.IsOpen() and drawn.window ~= key then
        drawWindow(state)
    end
end

-- Redraws on the next logic tick once, no matter how many times it's asked for in a tick,
-- and never inside a component's own event, which would destroy it mid-event.
local function redrawSoon()
    Event.Logic.Subscribe(REDRAW_REF, function()
        Event.Logic.Unsubscribe(REDRAW_REF)
        redrawAll()
    end)
end

local function pick(boss)
    viewState.Pick(boss.key)
    redrawSoon()
end

-- Shows the boss whose data was reset; the reset asks for a redraw.
local function reset(boss)
    viewState.Pick(boss.key)
    tracker.Reset(boss)
end

-- What the views draw (see src/ui/state.lua), and what they can do.
function currentState()
    local list, selected = viewState.Current()
    return {
        list = list,
        selected = selected,
        onPick = pick,
        onReset = reset,
        onResetAll = tracker.ResetAll,
        onDetails = showWindow,
    }
end

-- The game clears the settings page and fires this each time it opens.
local function onSettingsLayerReady(event)
    settings.Attach(event.component)
    drawSettings(currentState())
end

-- The game clears the panel and fires this each time it opens or is resized.
local function onContentLayerReady(event)
    panel.Attach(event.component)
    drawPanel(currentState())
end

-- Redraws the views now, for example once all-time totals can be read after login.
bossUi.Refresh = redrawAll

function bossUi.Start()
    tracker.OnChange(redrawSoon)
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

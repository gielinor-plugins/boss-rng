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
    if settings.IsOpen()
        and not safe.Call("drawing the settings", settings.Draw, currentState()) then
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

-- Redraws on the next logic tick, so a component isn't destroyed during its own event.
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

-- Shows the boss whose data was reset; the reset redraws the views.
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

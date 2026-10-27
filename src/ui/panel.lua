-- The ribbon panel. It can be very small, so it shows only the essentials for
-- one boss: its luck, its dry streak and how many kills that's based on, plus a
-- button that opens the Details window.

local format = require("src/format")
local safe = require("src/safe")
local widgets = require("src/ui/widgets")

local panel = {}

local PAD = 5
local LINE_HEIGHT = 22

local layer = nil -- the game's panel layer, once the player has opened it
local content = nil -- one layer holding everything we drew, so one Destroy clears it

-- Uses the layer the game just gave us. The game clears it each time it opens or
-- resizes the panel, taking our content with it.
function panel.Attach(newLayer)
    layer = newLayer
    content = nil
end

function panel.IsOpen()
    return layer ~= nil
end

-- Swaps the content for a new, empty layer to draw into.
local function newContent()
    if content then
        pcall(function() content:Destroy() end)
    end
    content = ui.Layer.new(layer)
    content:SetSize(0, 0, 1.0, 1.0) -- the whole panel
    return content
end

-- Draws state (see src/ui.lua) into the panel.
function panel.Draw(state)
    local parent = newContent()
    if not state.selected then
        widgets.AddText(parent, "No boss kills yet.", PAD, PAD)
        widgets.AddText(parent, "Kill a supported boss to start.", PAD, PAD + LINE_HEIGHT)
        return
    end
    local result = state.list[state.selected].stats

    widgets.AddBossPicker(parent, state, PAD, PAD)
    local y = PAD + 32
    widgets.AddLuckLine(parent, PAD, y, nil, result)
    widgets.AddText(parent, format.Dry(result), PAD, y + LINE_HEIGHT, nil, widgets.SMALL_FONT)
    local totals = widgets.AddText(parent, format.Totals(result), PAD, y + 2 * LINE_HEIGHT, nil, widgets.SMALL_FONT)
    totals.colour = widgets.GREY

    local details = ui.Button.new(parent)
    details.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
    details.label = "Details"
    widgets.Place(details, PAD, y + 3 * LINE_HEIGHT + 6, 100, 30)
    details:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
        safe.Call("opening the window", state.onDetails)
    end)
end

-- One plain line, shown instead of half a panel when drawing fails.
function panel.ShowError()
    widgets.AddText(newContent(), "Boss RNG couldn't draw this panel.", PAD, PAD)
end

function panel.Detach()
    if content then
        pcall(function() content:Destroy() end)
    end
    content = nil
    layer = nil
end

return panel

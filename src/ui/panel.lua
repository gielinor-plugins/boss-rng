-- The ribbon panel. It can be very small, so it shows only the essentials for
-- one boss, as plain lines rather than bars: its luck, its tracked kills and
-- uniques next to what an average player would have, its dry streak, and a
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
    widgets.Destroy(content)
    content = ui.Layer.new(layer)
    content:SetSize(0, 0, 1.0, 1.0) -- the whole panel
    -- Let clicks pass through the layer itself to what's drawn in it, so it
    -- doesn't catch clicks meant for the dropdown.
    content.clickthrough = true
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

    local y = PAD + 32
    widgets.AddLuckHeadline(parent, PAD, y, nil, result)
    y = y + LINE_HEIGHT + 2
    -- A rectangle doesn't stretch to its parent like text does, so it gets the
    -- panel's width.
    widgets.AddSeparator(parent, PAD, y, layer.width - 2 * PAD)
    y = y + 6
    local lines = { format.Totals(result), format.Extra(result), format.Average(result), format.Dry(result) }
    for _, line in ipairs(lines) do
        if line ~= "" then
            widgets.AddText(parent, line, PAD, y, nil, widgets.SMALL_FONT)
            y = y + LINE_HEIGHT
        end
    end

    local details = ui.Button.new(parent)
    details.stylesheetID = id.StyleSheet.BUTTON_ACTION_POSITIVE -- the game's yellow block button
    details.label = "Details"
    widgets.Place(details, PAD, y + 6, 100, 30)
    details:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
        safe.Call("opening the window", state.onDetails)
    end)

    -- The dropdown is added last: components added later are drawn on top and
    -- take clicks first, so its open list must come after everything it covers.
    widgets.AddBossPicker(parent, state, PAD, PAD)
end

-- One plain line, shown instead of half a panel when drawing fails.
function panel.ShowError()
    widgets.AddText(newContent(), "Boss RNG couldn't draw this panel.", PAD, PAD)
end

function panel.Detach()
    widgets.Destroy(content)
    content = nil
    layer = nil
end

return panel

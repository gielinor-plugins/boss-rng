-- The ribbon panel. It can be very small, so it shows only the essentials for
-- one boss: the boss, its luck, its tracked kills and uniques, and its dry
-- streak (with nothing tracked yet, the game's totals instead), and a button at
-- the bottom that opens the details window. The button stays in view however
-- small the panel is; lines that don't fit above it are left out.

local format = require("src/format")
local safe = require("src/safe")
local widgets = require("src/ui/widgets")

local panel = {}

local PAD = 5
local LINE_HEIGHT = 22
local BUTTON_LABEL, BUTTON_HEIGHT = "View details", 30

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
    local width = layer.width - 2 * PAD

    -- The panel can be narrow, so text wraps to its width.
    local y = widgets.AddLuckHeadline(parent, PAD, PAD + 32, width, result) + 2
    widgets.AddSeparator(parent, PAD, y, width)
    y = y + 6
    -- At the bottom, but never over the dropdown.
    local buttonY = math.max(layer.height - PAD - BUTTON_HEIGHT, PAD + 32)
    local tracked = result.kills + result.extraKills > 0
    local lines = tracked and { format.TrackedShort(result), format.Dry(result) } or { format.AllTime(result) }
    for _, line in ipairs(lines) do
        if line ~= "" and y + LINE_HEIGHT <= buttonY - 6 then
            y = widgets.AddWrapped(parent, line, PAD, y, width, widgets.SMALL_FONT, LINE_HEIGHT)
        end
    end

    local open = ui.Button.new(parent)
    open.stylesheetID = id.StyleSheet.BUTTON_DEFAULT -- the docs' default for plugins
    open.label = BUTTON_LABEL
    widgets.Place(open, PAD, buttonY, width, BUTTON_HEIGHT)
    open:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
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

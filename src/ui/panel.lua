-- The ribbon panel: one boss's essentials and a "View details" button that stays
-- in view however small the panel is. Lines that don't fit are left out.

local format = require("src/ui/format")
local safe = require("src/utils/safe")
local widgets = require("src/ui/widgets")

local panel = {}

local PAD = 5
local LINE_HEIGHT = 22
local BUTTON_LABEL, BUTTON_HEIGHT = "View details", 30

local layer = nil -- the game's panel layer, once the player has opened it
local content = nil -- holds everything drawn, so one Destroy clears it

-- The game clears this layer each time it opens or resizes the panel.
function panel.Attach(newLayer)
    layer = newLayer
    content = nil
end

function panel.IsOpen()
    return layer ~= nil
end

local function newContent()
    widgets.Destroy(content)
    content = ui.Layer.new(layer)
    content:SetSize(0, 0, 1.0, 1.0) -- the whole panel
    -- Clickthrough, so the layer doesn't catch clicks meant for the dropdown.
    content.clickthrough = true
    return content
end

function panel.Draw(state)
    local parent = newContent()
    if not state.selected then
        widgets.AddText(parent, "No boss kills yet.", PAD, PAD)
        widgets.AddText(parent, "Kill a supported boss to start.", PAD, PAD + LINE_HEIGHT)
        return
    end
    local entry = state.list[state.selected]
    local result = entry.stats
    local width = layer.width - 2 * PAD

    local y = widgets.AddLuckHeadline(parent, PAD, PAD + 32, width, result) + 2
    widgets.AddSeparator(parent, PAD, y, width)
    y = y + 6
    -- At the bottom, but never over the dropdown.
    local buttonY = math.max(layer.height - PAD - BUTTON_HEIGHT, PAD + 32)
    local tracked = result.kills + result.extraKills > 0
    local lines = tracked and { format.TrackedShort(result), format.Dry(result) } or { format.AllTime(result) }
    local function fits(height)
        return y + height <= buttonY - 6
    end
    for _, line in ipairs(lines) do
        if line ~= "" and fits(LINE_HEIGHT) then
            y = widgets.AddWrapped(parent, line, PAD, y, width, widgets.SMALL_FONT, LINE_HEIGHT)
        end
    end
    local tip = entry.boss.tip
    if tip and fits(8 + LINE_HEIGHT) then
        widgets.AddSeparator(parent, PAD, y + 2, width)
        y = widgets.AddWrapped(parent, tip, PAD, y + 8, width, widgets.SMALL_FONT, LINE_HEIGHT, widgets.MUTED)
    end

    local open = ui.Button.new(parent)
    open.stylesheetID = id.StyleSheet.BUTTON_DEFAULT -- the docs' default for plugins
    open.label = BUTTON_LABEL
    widgets.Place(open, PAD, buttonY, width, BUTTON_HEIGHT)
    open:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
        safe.Call("opening the window", state.onDetails)
    end)

    -- Added last: components added later are drawn on top and take clicks first.
    widgets.AddBossPicker(parent, state, PAD, PAD)
end

function panel.ShowError()
    widgets.AddText(newContent(), "Boss RNG couldn't draw this panel.", PAD, PAD)
end

function panel.Detach()
    widgets.Destroy(content)
    content = nil
    layer = nil
end

return panel

-- The settings page (Plugin Hub > Manage > Boss RNG's gear): a section per boss
-- with choices (see src/choices.lua), each a slider. The game gives an empty
-- layer (572 x 300 when measured), cleared each time the page opens.

local choices = require("src/choices")
local pickers = require("src/pickers")
local widgets = require("src/ui/widgets")

local settings = {}

local PAD = 10
local SLIDER_WIDTH = 200 -- as in the docs' examples
local LINE_HEIGHT = 18

local layer = nil -- the game's settings layer, while the page is open
local content = nil -- one layer holding everything drawn, so one Destroy clears it

function settings.Attach(newLayer)
    layer, content = newLayer, nil
end

function settings.IsOpen()
    return layer ~= nil
end

function settings.Detach()
    widgets.Destroy(content)
    content, layer = nil, nil
end

-- Clears the page into a fresh layer.
local function fresh()
    widgets.Destroy(content)
    content = ui.Layer.new(layer)
    content:SetSize(0, 0, 1.0, 1.0)
    content.clickthrough = true
    return content
end

-- A boss's section at y: its name, why and how to set its sliders, then a row
-- per slider (label, slider). Returns the y below it.
local function addSection(parent, boss, onChoose, y, width)
    widgets.AddText(parent, boss.name, PAD, y, width, widgets.CARD_FONT).colour = widgets.GOLD
    y = y + 24
    for _, paragraph in ipairs(boss.choicesHelp) do
        y = widgets.AddWrapped(parent, paragraph, PAD, y, width, widgets.SMALL_FONT, LINE_HEIGHT, widgets.GREY) + 4
    end
    local sliderX = PAD + width - SLIDER_WIDTH
    for _, picker in ipairs(pickers.For(boss, choices.For(boss), onChoose)) do
        local label = widgets.AddText(parent, picker.label, PAD + 10, y, sliderX - PAD - 20)
        label:SetSize(sliderX - PAD - 20, widgets.SLIDER_HEIGHT)
        label.alignVertical = ui.AlignMode.CENTRE
        widgets.AddSlider(parent, sliderX, y, SLIDER_WIDTH, picker.min, picker.max, picker.step, picker.current,
            picker.onPick)
        y = y + widgets.SLIDER_HEIGHT + 2
    end
    return y + 8
end

-- Draws a section for each boss in state.bosses with choices.
function settings.Draw(state)
    local parent = fresh()
    local y = PAD
    for _, boss in ipairs(state.bosses) do
        if boss.choices then
            y = addSection(parent, boss, state.onChoose, y, layer.width - 2 * PAD)
        end
    end
end

-- One plain line, shown instead of half a page when drawing fails.
function settings.ShowError()
    widgets.AddText(fresh(), "Boss RNG couldn't draw its settings.", PAD, PAD)
end

return settings

-- The settings page: a slider per choice for each boss with choices. The game
-- clears its layer (572 x 300 when measured) each time the page opens.

local choices = require("src/core/choices")
local sliders = require("src/ui/sliders")
local widgets = require("src/ui/widgets")

local settings = {}

local PAD = 10
local SLIDER_WIDTH = 200 -- as in the docs' examples
local LINE_HEIGHT = 18

local layer = nil -- the game's settings layer, while the page is open
local content = nil -- holds everything drawn, so one Destroy clears it

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

local function fresh()
    widgets.Destroy(content)
    content = ui.Layer.new(layer)
    content:SetSize(0, 0, 1.0, 1.0)
    content.clickthrough = true
    return content
end

-- A boss's section at y: name, help, then a row per slider. Returns the y below.
local function addSection(parent, boss, onChoose, y, width)
    widgets.AddText(parent, boss.name, PAD, y, width, widgets.CARD_FONT).colour = widgets.GOLD
    y = y + 24
    for _, paragraph in ipairs(boss.choicesHelp) do
        y = widgets.AddWrapped(parent, paragraph, PAD, y, width, widgets.SMALL_FONT, LINE_HEIGHT, widgets.GREY) + 4
    end
    local sliderX = PAD + width - SLIDER_WIDTH
    for _, slider in ipairs(sliders.For(boss, choices.For(boss), onChoose)) do
        local label = widgets.AddText(parent, slider.label, PAD + 10, y, sliderX - PAD - 20)
        label:SetSize(sliderX - PAD - 20, widgets.SLIDER_HEIGHT)
        label.alignVertical = ui.AlignMode.CENTRE
        widgets.AddSlider(parent, sliderX, y, SLIDER_WIDTH, slider.min, slider.max, slider.step, slider.current,
            slider.onPick)
        y = y + widgets.SLIDER_HEIGHT + 2
    end
    return y + 8
end

function settings.Draw(state)
    local parent = fresh()
    local y = PAD
    for _, boss in ipairs(state.bosses) do
        if boss.choices then
            y = addSection(parent, boss, state.onChoose, y, layer.width - 2 * PAD)
        end
    end
end

function settings.ShowError()
    widgets.AddText(fresh(), "Boss RNG couldn't draw its settings.", PAD, PAD)
end

return settings

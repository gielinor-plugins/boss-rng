-- The settings page: for each boss with choices, its name, why and how to set
-- them, and a slider per choice.

local choices = require("src/core/choices")
local layerView = require("src/ui/layer_view")

local page = layerView.New()

local settings = { Attach = page.Attach, IsOpen = page.IsOpen, Detach = page.Detach }

-- A choice's label with its value: "Normal Mode: 2.5".
local function labelFor(choice, value)
    local shown = value % 1 == 0 and string.format("%d", value) or tostring(value)
    return choice.label .. ": " .. shown
end

function settings.Draw(state)
    local host = page.Fresh()
    for _, boss in ipairs(state.bosses) do
        if boss.choices then
            host:AddTitle({ text = boss.name })
            for _, paragraph in ipairs(boss.choicesHelp) do
                host:AddText({ text = paragraph })
            end
            local picks = choices.For(boss)
            for _, choice in ipairs(boss.choices) do
                local label = host:AddText({ text = labelFor(choice, picks[choice.key]) })
                host:AddSlider({
                    min = choice.min, max = choice.max, step = choice.step,
                    value = picks[choice.key],
                    onChange = function(_, value)
                        label.content = labelFor(choice, value)
                        state.onChoose(boss, choice, value)
                    end,
                })
            end
        end
    end
end

function settings.ShowError()
    page.Fresh():AddText({ text = "Boss RNG couldn't draw its settings." })
end

return settings

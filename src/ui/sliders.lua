-- A boss's sliders as plain data: { label, min, max, step, current, onPick } each.

local sliders = {}

-- onChoose(boss, choice, value) saves a pick.
function sliders.For(boss, picks, onChoose)
    local list = {}
    for _, choice in ipairs(boss.choices or {}) do
        table.insert(list, {
            label = choice.label,
            min = choice.min,
            max = choice.max,
            step = choice.step,
            current = picks[choice.key],
            onPick = function(value) onChoose(boss, choice, value) end,
        })
    end
    return list
end

-- The assumptions' footer: where to change them, or nil without choices.
function sliders.WhereToChange(boss)
    return boss.choices and "Change these in Plugin Hub > Manage > Boss RNG settings" or nil
end

return sliders

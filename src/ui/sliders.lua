-- The sliders for a boss's picks (see src/core/choices.lua), as plain data, for the
-- views to draw: { label, min, max, step, current, onPick } each. Plain Lua, so it
-- can be tested offline.

local sliders = {}

-- A boss's sliders, one per choice, at its picks (see choices.For).
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

-- The assumptions' footer for a boss with choices: where to change them. Nil
-- for a boss without.
function sliders.WhereToChange(boss)
    return boss.choices and "Change these in Plugin Hub > Manage > Boss RNG settings" or nil
end

return sliders

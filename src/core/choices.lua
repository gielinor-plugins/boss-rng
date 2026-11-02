-- Each character's picks for a boss's choices, what the game can't tell Boss RNG
-- (such as Kerapac's team), saved apart from the tallies. A boss file declares
-- choices (see src/bosses/kerapac.lua), each a slider:
--   key                     saved data key: never change it
--   label, unit             shown by the slider and with the pick in the assumptions
--   default, min, max, step the slider's start value and range

local saved = require("src/utils/saved")

local choices = {}

-- Saved as { bosses = { [boss key] = { [choice key] = value } } }. Any other version
-- starts again. TODO: set to 1 before release.
local store = saved.ForCharacter("choices:", 4, function() return { bosses = {} } end)

local function valid(choice, value)
    if type(value) ~= "number" or value < choice.min or value > choice.max then
        return false
    end
    local steps = (value - choice.min) / choice.step
    return math.abs(steps - math.floor(steps + 0.5)) < 1e-9
end

-- The character's picks for a boss, with defaults for missing or invalid picks.
function choices.For(boss)
    local record = store.Load()
    local picks = record and record.bosses[boss.key] or {}
    local values = {}
    for _, choice in ipairs(boss.choices or {}) do
        local picked = picks[choice.key]
        values[choice.key] = valid(choice, picked) and picked or choice.default
    end
    return values
end

-- A boss's own assumptions (a list, or a function of picks), then each pick.
function choices.Assumptions(boss, picks)
    local notes = {}
    local own = boss.assumptions
    for _, note in ipairs(type(own) == "function" and own(picks) or own) do
        table.insert(notes, note)
    end
    for _, choice in ipairs(boss.choices or {}) do
        table.insert(notes, string.format("%s%s: %g", choice.label, choice.unit or "", picks[choice.key]))
    end
    return notes
end

function choices.Set(boss, choice, value)
    local record = store.Load()
    if record == nil then
        return
    end
    local picks = record.bosses[boss.key] or {}
    picks[choice.key] = value
    record.bosses[boss.key] = picks
    store.Save()
end

return choices

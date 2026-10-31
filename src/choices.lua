-- What each character picks for a boss's choices: what the game can't tell Boss
-- RNG about their tracked kills, such as Kerapac's team. Picks are the player's
-- own, so they're saved apart from the tallies.
--
-- A boss file can declare choices (see src/bosses/kerapac.lua), each a number
-- set on a slider:
--   key            saved data key: never change it
--   label          shown by its slider, and with the pick in the assumptions
--   unit           follows the label in the assumptions (" loot piles per kill")
--   default        the value until the player picks one
--   min, max, step the slider's range and step

local saved = require("src/saved")

local choices = {}

-- Saved as { bosses = { [boss key] = { [choice key] = value } } }.
local store = saved.ForCharacter("choices:", 4, function() return { bosses = {} } end)

-- True if value is a number the choice's slider can show.
function choices.Valid(choice, value)
    if type(value) ~= "number" or value < choice.min or value > choice.max then
        return false
    end
    local steps = (value - choice.min) / choice.step
    return math.abs(steps - math.floor(steps + 0.5)) < 1e-9
end

-- The logged in character's picks for a boss, { [choice key] = value }, with
-- each choice's default where nothing (or an option that no longer exists) is picked.
function choices.For(boss)
    local record = store.Load()
    local picks = record and record.bosses[boss.key] or {}
    local values = {}
    for _, choice in ipairs(boss.choices or {}) do
        local picked = picks[choice.key]
        values[choice.key] = choices.Valid(choice, picked) and picked or choice.default
    end
    return values
end

-- A boss's assumptions for these picks: its own (a list, or a function of the
-- picks), then each choice's pick ("Normal Mode loot piles per kill: 2.5").
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

-- Saves the logged in character's pick for one of a boss's choices.
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

-- What each character picks for a boss's choices: what the game can't tell Boss
-- RNG about their tracked kills, such as Kerapac's team. Picks are the player's
-- own, so they're saved apart from the tallies.
--
-- A boss file can declare choices (see src/bosses/kerapac.lua), each with:
--   key      saved data key: never change it
--   label    shown before its dropdown, and with the pick in the assumptions
--   default  the value until the player picks one
--   options  { { value = "solo", label = "Solo" }, ... }, in the order to list
--            them; an option can add a note, saying it in full in the
--            assumptions when its label is shortened to fit its dropdown

local saved = require("src/saved")

local choices = {}

-- Saved as { bosses = { [boss key] = { [choice key] = value } } }.
local store = saved.ForCharacter("choices:", 3, function() return { bosses = {} } end)

-- The option of a choice with this value, or nil.
function choices.Option(choice, value)
    for _, option in ipairs(choice.options) do
        if option.value == value then
            return option
        end
    end
    return nil
end

-- The logged in character's picks for a boss, { [choice key] = value }, with
-- each choice's default where nothing (or an option that no longer exists) is picked.
function choices.For(boss)
    local record = store.Load()
    local picks = record and record.bosses[boss.key] or {}
    local values = {}
    for _, choice in ipairs(boss.choices or {}) do
        local picked = picks[choice.key]
        values[choice.key] = choices.Option(choice, picked) and picked or choice.default
    end
    return values
end

-- A boss's assumptions for these picks: its own (a list, or a function of the
-- picks), then each choice's pick ("Normal mode kills done: Solo").
function choices.Assumptions(boss, picks)
    local notes = {}
    local own = boss.assumptions
    for _, note in ipairs(type(own) == "function" and own(picks) or own) do
        table.insert(notes, note)
    end
    for _, choice in ipairs(boss.choices or {}) do
        local option = choices.Option(choice, picks[choice.key])
        table.insert(notes, choice.label .. ": " .. (option.note or option.label))
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

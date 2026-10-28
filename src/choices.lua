-- What each character picks: a boss's choices, such as the enrage of their kills
-- from before Boss RNG, and how a pooled unique's untracked drops split between
-- the bosses that list it (see src/bosses.lua). Picks are the player's own, so
-- they're saved apart from the tallies, which are read from the game.
--
-- A boss file can declare choices (see src/bosses/amascut.lua), each with:
--   key      saved data key: never change it
--   label    shown before its dropdown, and with the pick in the assumptions
--   default  the value until the player picks one
--   options  { { value = 100, label = "100%" }, ... }, in the order to list them
--   var      optional: the game var holding the value at each tracked kill, for
--            a choice whose options are numbers, lowest first

local saved = require("src/saved")

local choices = {}

-- Saved as { bosses = { [boss key] = { [choice key] = value } },
--            splits = { [item id] = { [boss key] = untracked drops } } }.
local store = saved.ForCharacter("choices:", 2, function() return { bosses = {}, splits = {} } end)

-- A boss's choice with this key, or nil.
function choices.Find(boss, key)
    for _, choice in ipairs(boss.choices or {}) do
        if choice.key == key then
            return choice
        end
    end
    return nil
end

-- The value of the option a game value falls in: the highest option at or
-- below it, or the lowest option if it's below them all.
function choices.Snap(choice, value)
    local snapped = choice.options[1].value
    for _, option in ipairs(choice.options) do
        if value >= option.value then
            snapped = option.value
        end
    end
    return snapped
end

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

-- The logged in character's splits of pooled uniques' untracked drops:
-- { [item id] = { [boss key] = count } }.
function choices.Splits()
    local record = store.Load()
    return record and record.splits or {}
end

-- Saves how a pooled unique's untracked drops split, { [boss key] = count }, or
-- clears it with nil.
function choices.SetSplit(itemID, counts)
    local record = store.Load()
    if record == nil then
        return
    end
    record.splits[tostring(itemID)] = counts
    store.Save()
end

return choices

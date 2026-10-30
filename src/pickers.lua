-- The dropdowns for a boss's picks (see src/choices.lua), as plain data, for
-- the views to draw: { label, options, current, onPick } each. Plain Lua, so it
-- can be tested offline.

local pickers = {}

-- The game's name for an item, or its id if that can't be read.
function pickers.ItemName(itemID)
    local ok, name = pcall(function() return config.Obj.FromID(math.tointeger(itemID)).name end)
    return ok and name or ("Item " .. tostring(itemID))
end

-- A boss's dropdowns (entry, see src/ui.lua), one per choice. onChoose(boss,
-- choice, value) saves a pick.
function pickers.For(entry, onChoose)
    local list = {}
    for _, choice in ipairs(entry.boss.choices or {}) do
        table.insert(list, {
            label = choice.label,
            options = choice.options,
            current = entry.picks[choice.key],
            onPick = function(value) onChoose(entry.boss, choice, value) end,
        })
    end
    return list
end

return pickers

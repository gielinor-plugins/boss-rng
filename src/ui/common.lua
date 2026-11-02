-- What the views share: the boss dropdown, item names and fitting text.

local common = {}

function common.ItemName(itemID)
    local ok, name = pcall(function() return config.Obj.FromID(math.tointeger(itemID)).name end)
    return ok and name or ("Item " .. tostring(itemID))
end

-- Pixels wide, or nil if the font can't be measured.
local function textWidth(content, font)
    local ok, width = pcall(function() return config.Font.FromID(font):GetStringWidth(content) end)
    return ok and width or nil
end

-- Shortened with "..." to fit width, or whole if the font can't be measured.
function common.Fit(content, font, width)
    if (textWidth(content, font) or 0) <= width then
        return content
    end
    local cut = content
    while #cut > 0 and textWidth(cut .. "...", font) > width do
        cut = cut:sub(1, -2)
    end
    return (cut:gsub("%s+$", "")) .. "..."
end

-- The boss dropdown on host at y. Add it last, so its open list draws over
-- everything else.
function common.AddBossPicker(host, state, y)
    local entries = {}
    for i, entry in ipairs(state.list) do
        entries[i] = { label = entry.boss.name, id = i }
    end
    return host:AddComboBox({
        y = y,
        entries = entries,
        selectedID = state.selected,
        -- A change reports the old entry (0), then the new one (1).
        onChange = function(_, index, _, selected)
            if selected ~= 0 and index ~= state.selected and state.list[index] then
                state.onPick(state.list[index].boss.key)
            end
        end,
    })
end

return common

-- What the views share: the boss dropdown, item names and fitting text.

local common = {}

-- A divider's options, inset each side by inset (in line with the text), with 8 px
-- above and below the line.
function common.Divider(inset)
    return { x = inset, width = -2 * inset, widthAnchor = 1.0, marginTop = -35, height = 41, marginBottom = 8 }
end

-- The game's top layer for plugin windows and dialogs.
function common.TopLayer()
    return ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP)
end

-- The index of the { boss } entry for a boss key in list, or nil.
function common.IndexOf(list, key)
    for i, entry in ipairs(list) do
        if entry.boss.key == key then
            return i
        end
    end
    return nil
end

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

-- A dropdown of bosses on host: list holds { boss } entries, the one at shown is
-- selected, and onPick(boss) runs when another is picked. placement holds its
-- position and size. Add it last, so its open list draws over everything else.
function common.AddBossPicker(host, list, shown, onPick, placement)
    local names = {}
    for i, entry in ipairs(list) do
        names[i] = { label = entry.boss.name, id = i }
    end
    local options = {
        entries = names,
        selectedID = shown,
        -- A change reports the old entry (0), then the new one (1).
        onChange = function(_, index, _, event)
            if event ~= 0 and index ~= shown and list[index] then
                shown = index
                onPick(list[index].boss)
            end
        end,
    }
    for key, value in pairs(placement) do
        options[key] = value
    end
    return host:AddComboBox(options)
end

return common

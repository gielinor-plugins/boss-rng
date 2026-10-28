-- Building blocks shared by the ribbon panel and the Details window: fonts,
-- colors, and small helpers that create the game's own components.

local format = require("src/format")
local safe = require("src/safe")

local widgets = {}

-- Fonts and colors match the game's collection log: Cinzel headings, Noto Sans
-- text and yellow highlights.
widgets.FONT = id.Font.NOTOSANS_14
widgets.SMALL_FONT = id.Font.NOTOSANS_12
widgets.TITLE_FONT = id.Font.CINZEL_13PT_BOLD
widgets.CARD_FONT = id.Font.NOTOSANS_SEMIBOLD_14 -- labels and headlines
widgets.ROW_FONT = id.Font.NOTOSANS_SEMIBOLD_12 -- names in table rows
widgets.YELLOW = Vector4.new(1.0, 0.85, 0.2, 1.0)
widgets.GOLD = Vector4.new(0.94, 0.75, 0.47, 1.0) -- the log's title and headings
widgets.GREY = Vector4.new(0.75, 0.75, 0.75, 1.0) -- secondary text
widgets.TEXT_HEIGHT = 20
widgets.BAR_WIDTH = 110
widgets.BAR_HEIGHT = 10
widgets.DROPDOWN_HEIGHT = 25

local SEPARATOR = Vector4.new(1.0, 1.0, 1.0, 0.12)
local BAR_BACK = Vector4.new(0.0, 0.0, 0.0, 0.6)
local TICK = Vector4.new(1.0, 1.0, 1.0, 0.9) -- marks average luck on a bar
-- A solid gold timer bar fill. It stretches to any width without marks that
-- could be mistaken for values (the adrenaline bar's segment notches could).
local BAR_FILL = "TIMERBAR_120_S_1"

-- Destroys a component and everything in it, if there is one. It may already be
-- gone (the game clears a panel layer when it's resized), so failures are ignored.
function widgets.Destroy(component)
    if component then
        pcall(function() component:Destroy() end)
    end
end

-- Positions and sizes a component, then returns it. Without a width it spans
-- its parent.
function widgets.Place(component, x, y, width, height)
    component:SetPos(x, y)
    if width then
        component:SetSize(width, height)
    else
        component:SetSize(0, height, 1.0, 0.0)
    end
    return component
end

-- A line of text. The font defaults to FONT.
function widgets.AddText(parent, content, x, y, width, font)
    local text = widgets.Place(ui.Text.new(parent), x, y, width, widgets.TEXT_HEIGHT)
    text.font = font or widgets.FONT
    text.content = content
    return text
end

-- How many pixels wide content is in font (an id.Font value), or nil if the
-- font can't be measured. Text draws past the end of its box, so text that may
-- be long is measured to fit it.
local function textWidth(content, font)
    local ok, width = pcall(function()
        return config.Font.FromID(font):GetStringWidth(content)
    end)
    return ok and width or nil
end

-- content shortened with "..." so it fits in width pixels in font. If the font
-- can't be measured, content comes back whole.
function widgets.Fit(content, font, width)
    if (textWidth(content, font) or 0) <= width then
        return content
    end
    local cut = content
    while #cut > 0 and textWidth(cut .. "...", font) > width do
        cut = cut:sub(1, -2)
    end
    return (cut:gsub("%s+$", "")) .. "..."
end

-- content split between words into lines that fit in width pixels in font. If
-- the font can't be measured, content comes back as one line.
function widgets.Wrap(content, font, width)
    if textWidth(content, font) == nil then
        return { content }
    end
    local lines, line = {}, nil
    for word in content:gmatch("%S+") do
        local longer = line and (line .. " " .. word) or word
        if line and textWidth(longer, font) > width then
            table.insert(lines, line)
            line = word
        else
            line = longer
        end
    end
    table.insert(lines, line or "")
    return lines
end

-- Centers text in its box, across and down.
function widgets.Center(text)
    text:AlignTo(ui.AlignMode.CENTRE)
end

function widgets.AddRect(parent, x, y, width, height, colour)
    local rect = widgets.Place(ui.Rectangle.new(parent), x, y, width, height)
    rect.colour = colour
    rect.fill = true
    return rect
end

-- A faint horizontal line between sections.
function widgets.AddSeparator(parent, x, y, width)
    return widgets.AddRect(parent, x, y, width, 1, SEPARATOR)
end

-- A boss's luck as a headline: "Bottom 12% luck", in the log's gold.
function widgets.AddLuckHeadline(parent, x, y, width, result)
    local headline = widgets.AddText(parent, format.Capitalize(format.Luck(result)), x, y, width, widgets.CARD_FONT)
    headline.colour = widgets.GOLD
    return headline
end

-- One of the game's sprites, by its name in id.Sprite.
function widgets.AddSprite(parent, name, x, y, width, height)
    local sprite = widgets.Place(ui.Sprite.new(parent), x, y, width, height)
    sprite.sprite = id.Sprite[name]
    return sprite
end

-- A luck bar: a gold timer bar fill on a dark back, filled to the luck share,
-- with a tick at the middle, where an average player would be. The width
-- defaults to BAR_WIDTH.
function widgets.AddLuckBar(parent, x, y, share, width)
    width = width or widgets.BAR_WIDTH
    local height = widgets.BAR_HEIGHT
    widgets.AddRect(parent, x, y, width, height, BAR_BACK)
    local filled = math.floor(width * share)
    if filled > 0 then
        widgets.AddSprite(parent, BAR_FILL, x, y, filled, height)
    end
    widgets.AddRect(parent, x + width // 2, y, 2, height, TICK)
end

-- A luck bar with its group beside it ("bottom 12%"). Without luck, only the
-- text shows.
function widgets.AddLuckLine(parent, x, y, width, result)
    if result.luck then
        widgets.AddLuckBar(parent, x, y + 5, result.luck)
        x = x + widgets.BAR_WIDTH + 8
        width = width and width - widgets.BAR_WIDTH - 8
    end
    return widgets.AddText(parent, format.LuckShort(result), x, y, width, widgets.SMALL_FONT)
end

-- The game's dropdown, listing labels and showing labels[selected]. Picking
-- another calls onPick with its index. labels must be in alphabetical order: the
-- game lists them that way and reports picks by position. Add a dropdown after
-- anything its open list covers, so it's drawn on top and takes clicks first.
function widgets.AddDropdown(parent, x, y, width, labels, selected, onPick)
    local combo = ui.ComboField.new(parent)
    combo.stylesheetID = id.StyleSheet.COMBO_DEFAULT
    widgets.Place(combo, x, y, width, widgets.DROPDOWN_HEIGHT)
    for i, label in ipairs(labels) do
        combo:Add(label, i)
    end
    combo:Select(selected)
    -- A change fires twice: the old entry with 0, then the new one with 1.
    combo:Subscribe(ui.Hook.ONSELECTIONCHANGED, function(_, index, status)
        if status == 1 and labels[index] then
            safe.Call("picking from a dropdown", onPick, index)
        end
    end)
    return combo
end

-- A dropdown of the bosses in state.list (alphabetical, see src/ui.lua), showing
-- state.selected. Picking one calls state.onPick with that boss's key.
function widgets.AddBossPicker(parent, state, x, y, width)
    local names = {}
    for i, entry in ipairs(state.list) do
        names[i] = entry.boss.name
    end
    return widgets.AddDropdown(parent, x, y, width, names, state.selected, function(index)
        state.onPick(state.list[index].boss.key)
    end)
end

return widgets

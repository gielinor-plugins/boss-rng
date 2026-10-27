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

local SEPARATOR = Vector4.new(1.0, 1.0, 1.0, 0.12)
local BAR_BACK = Vector4.new(0.0, 0.0, 0.0, 0.6)
local TICK = Vector4.new(1.0, 1.0, 1.0, 0.9) -- marks average luck on a bar
local PICKER_HEIGHT = 25

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

-- Centers text in its box. AlignTo is only shown in Jagex's tutorial, so if it
-- isn't available the text simply stays left aligned.
function widgets.Center(text)
    pcall(function() text:AlignTo(ui.AlignMode.CENTRE) end)
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

-- A luck bar: the HUD's adrenaline fill on a dark back, filled to the luck share,
-- with a tick at the middle, where an average player would be. The width
-- defaults to BAR_WIDTH.
function widgets.AddLuckBar(parent, x, y, share, width)
    width = width or widgets.BAR_WIDTH
    local height = widgets.BAR_HEIGHT
    widgets.AddRect(parent, x, y, width, height, BAR_BACK)
    local filled = math.floor(width * share)
    if filled > 0 then
        widgets.AddSprite(parent, "FILLBAR_HUD_ADRENALINE", x, y, filled, height)
    end
    widgets.AddRect(parent, x + width // 2, y, 2, height, TICK)
end

-- A luck bar with its sentence beside it. Without luck, only the sentence shows.
function widgets.AddLuckLine(parent, x, y, width, result)
    if result.luck then
        widgets.AddLuckBar(parent, x, y + 5, result.luck)
        x = x + widgets.BAR_WIDTH + 8
        width = width and width - widgets.BAR_WIDTH - 8
    end
    return widgets.AddText(parent, format.Luck(result), x, y, width, widgets.SMALL_FONT)
end

-- A dropdown of the bosses in state.list, showing state.selected. Picking one
-- calls state.onPick with that boss's key.
function widgets.AddBossPicker(parent, state, x, y, width)
    local combo = ui.ComboField.new(parent)
    combo.stylesheetID = id.StyleSheet.COMBO_DEFAULT
    widgets.Place(combo, x, y, width, PICKER_HEIGHT)
    for i, entry in ipairs(state.list) do
        combo:Add(entry.boss.name, i)
    end
    combo:Select(state.selected)
    -- A change fires twice: the old entry with 0, then the new one with 1.
    combo:Subscribe(ui.Hook.ONSELECTIONCHANGED, function(_, entryID, status)
        local entry = state.list[entryID]
        if status == 1 and entry then
            safe.Call("picking a boss", state.onPick, entry.boss.key)
        end
    end)
    return combo
end

return widgets

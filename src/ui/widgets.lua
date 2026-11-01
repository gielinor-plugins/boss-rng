-- Fonts, colors and helpers for the game's own components, shared by the views.

local format = require("src/ui/format")
local safe = require("src/utils/safe")

local widgets = {}

-- Fonts and colors match the game's collection log.
local FONT = id.Font.NOTOSANS_14
widgets.SMALL_FONT = id.Font.NOTOSANS_12
widgets.TITLE_FONT = id.Font.CINZEL_13PT_BOLD
widgets.CARD_FONT = id.Font.NOTOSANS_SEMIBOLD_14 -- labels and headlines
widgets.ROW_FONT = id.Font.NOTOSANS_SEMIBOLD_12 -- names in table rows
widgets.GOLD = Vector4.new(0.94, 0.75, 0.47, 1.0) -- the log's title and headings
widgets.GREY = Vector4.new(0.75, 0.75, 0.75, 1.0) -- secondary text
widgets.MUTED = Vector4.new(0.6, 0.6, 0.6, 1.0) -- all-time totals, tips
widgets.TEXT_HEIGHT = 20
widgets.BAR_HEIGHT = 10
widgets.DROPDOWN_HEIGHT = 25

local SEPARATOR = Vector4.new(1.0, 1.0, 1.0, 0.12)
local BAR_BACK = Vector4.new(0.0, 0.0, 0.0, 0.6)
local TICK = Vector4.new(1.0, 1.0, 1.0, 0.9) -- marks average luck on a bar
-- A plain gold fill, with no notches that could be mistaken for values.
local BAR_FILL = "TIMERBAR_120_S_1"

function widgets.ItemName(itemID)
    local ok, name = pcall(function() return config.Obj.FromID(math.tointeger(itemID)).name end)
    return ok and name or ("Item " .. tostring(itemID))
end

-- Ignores failures: the game may already have cleared it (a resized panel).
function widgets.Destroy(component)
    if component then
        pcall(function() component:Destroy() end)
    end
end

-- Without a width it spans its parent.
function widgets.Place(component, x, y, width, height)
    component:SetPos(x, y)
    if width then
        component:SetSize(width, height)
    else
        component:SetSize(0, height, 1.0, 0.0)
    end
    return component
end

function widgets.AddText(parent, content, x, y, width, font)
    local text = widgets.Place(ui.Text.new(parent), x, y, width, widgets.TEXT_HEIGHT)
    text.font = font or FONT
    text.content = content
    return text
end

-- Pixels wide, or nil if the font can't be measured. Text draws past the end
-- of its box, so long text is measured to fit.
local function textWidth(content, font)
    local ok, width = pcall(function()
        return config.Font.FromID(font):GetStringWidth(content)
    end)
    return ok and width or nil
end

-- Shortened with "..." to fit width, or whole if the font can't be measured.
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

-- Lines that fit width, or one line if the font can't be measured.
local function wrap(content, font, width)
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

-- Returns the y below the wrapped text.
function widgets.AddWrapped(parent, content, x, y, width, font, lineHeight, colour)
    for _, line in ipairs(wrap(content, font, width)) do
        local text = widgets.AddText(parent, line, x, y, width, font)
        if colour then
            text.colour = colour
        end
        y = y + lineHeight
    end
    return y
end

function widgets.Center(text)
    text:AlignTo(ui.AlignMode.CENTRE)
end

function widgets.AddRect(parent, x, y, width, height, colour)
    local rect = widgets.Place(ui.Rectangle.new(parent), x, y, width, height)
    rect.colour = colour
    rect.fill = true
    return rect
end

function widgets.AddSeparator(parent, x, y, width)
    return widgets.AddRect(parent, x, y, width, 1, SEPARATOR)
end

local HEADLINE_LINE_HEIGHT = 22

-- "Bottom 12% luck" in gold, wrapped. Returns the y below it.
function widgets.AddLuckHeadline(parent, x, y, width, result)
    local headline = format.Capitalize(format.Luck(result))
    return widgets.AddWrapped(parent, headline, x, y, width, widgets.CARD_FONT, HEADLINE_LINE_HEIGHT, widgets.GOLD)
end

function widgets.AddSprite(parent, name, x, y, width, height)
    local sprite = widgets.Place(ui.Sprite.new(parent), x, y, width, height)
    sprite.sprite = id.Sprite[name]
    return sprite
end

-- Filled to the luck share, with a tick at the middle for an average player.
function widgets.AddLuckBar(parent, x, y, share, width)
    local height = widgets.BAR_HEIGHT
    widgets.AddRect(parent, x, y, width, height, BAR_BACK)
    local filled = math.floor(width * share)
    if filled > 0 then
        widgets.AddSprite(parent, BAR_FILL, x, y, filled, height)
    end
    widgets.AddRect(parent, x + width // 2, y, 2, height, TICK)
end

local DROPDOWN_MAX_VISIBLE = 6

-- The combo box reports a change twice by id (here the index in options):
-- the old entry with 0, then the new one with 1.
local function onChange(dropdown, options, current, onPick)
    dropdown:Subscribe(ui.Hook.ONSELECTIONCHANGED, function(_, index, selected)
        local option = options[index]
        if selected == 1 and option and option.value ~= current then
            safe.Call("picking from a dropdown", onPick, option.value)
        end
    end)
end

-- The combo box lists options alphabetically, whatever their order. Add it after
-- anything its open list covers, so it's drawn on top and takes clicks first.
function widgets.AddDropdown(parent, x, y, width, options, current, onPick)
    local combo = ui.ComboField.new(parent)
    combo.stylesheetID = id.StyleSheet.COMBO_DEFAULT
    combo.dropdownMaxVisibleEntries = math.min(#options, DROPDOWN_MAX_VISIBLE)
    widgets.Place(combo, x, y, width, widgets.DROPDOWN_HEIGHT)
    -- Picks are reported by place in the list, so ids follow the sorted order.
    local sorted = {}
    for i, option in ipairs(options) do
        sorted[i] = option
    end
    table.sort(sorted, function(a, b) return a.label < b.label end)
    local selected = 1
    for i, option in ipairs(sorted) do
        combo:Add(option.label, i)
        if option.value == current then
            selected = i
        end
    end
    combo:Select(selected)
    onChange(combo, sorted, current, onPick)
    return combo
end

widgets.SLIDER_HEIGHT = 50 -- as in the docs' examples

-- The slider takes whole steps, so values are scaled by 1 / step (at most 1).
function widgets.AddSlider(parent, x, y, width, min, max, step, current, onPick)
    local slider = ui.Slider.new(parent)
    slider.stylesheetID = id.StyleSheet.SLIDER_DEFAULT
    widgets.Place(slider, x, y, width, widgets.SLIDER_HEIGHT)
    local scale = math.floor(1 / step + 0.5)
    local function steps(value) return math.floor(value * scale + 0.5) end
    slider:Setup(steps(min), steps(max), steps(current), scale, 1)
    slider:Subscribe(ui.Hook.ONSELECTIONCHANGED, function(component)
        if component.value ~= steps(current) then
            current = component.value / scale
            safe.Call("moving a slider", onPick, current)
        end
    end)
    return slider
end

function widgets.AddBossPicker(parent, state, x, y, width)
    local options = {}
    for i, entry in ipairs(state.list) do
        options[i] = { value = entry.boss.key, label = entry.boss.name }
    end
    return widgets.AddDropdown(parent, x, y, width, options, state.list[state.selected].boss.key, state.onPick)
end

return widgets

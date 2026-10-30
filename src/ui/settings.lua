-- The settings page (Plugin Hub > Manage > Boss RNG's gear): picks for kills
-- Boss RNG didn't see, for every boss with kills that has some (see
-- src/pickers.lua). The game gives an empty layer (572 x 300 when measured)
-- each time the page opens, and clips it without scrolling, so the list is in a
-- scrolling view of our own.

local frame = require("src/ui/frame")
local pickers = require("src/pickers")
local widgets = require("src/ui/widgets")

local settings = {}

local PAD = 10
local PICKER_WIDTH = 140
local LINE_HEIGHT = 18 -- between lines of small text
local INTRO = "Used to calculate luck for untracked kills: those the plugin didn't record (before install, while disabled, or on another device)."
local NOTHING = "Nothing to pick yet: bosses you've killed that need a pick show here."

local layer = nil -- the game's settings layer, while the page is open
local content = nil -- one layer holding everything we drew, so one Destroy clears it
-- The list's scroll position, kept while the page is open, so redrawing after
-- a pick doesn't jump back to the top.
local scroll = { y = 0 }

-- Uses the layer the game just gave us, cleared by the game.
function settings.Attach(newLayer)
    layer = newLayer
    content = nil
    scroll = { y = 0 }
end

function settings.IsOpen()
    return layer ~= nil
end

function settings.Detach()
    widgets.Destroy(content)
    content, layer = nil, nil
end

-- Grey text in SMALL_FONT.
local function addGreyText(parent, text, x, y, width)
    local line = widgets.AddText(parent, text, x, y, width, widgets.SMALL_FONT)
    line.colour = widgets.GREY
    return line
end

-- The bosses to list: those in state.list (with kills, alphabetical) with
-- picks for the settings page, each { entry, pickers }.
local function sections(state)
    local list = {}
    for _, entry in ipairs(state.list) do
        local found = pickers.ForSettings(entry, state.pools, state.onChoose, state.onSplit)
        if #found > 0 then
            table.insert(list, { entry = entry, pickers = found })
        end
    end
    return list
end

-- A boss's section at y: its name, its untracked kills, then a line per pick
-- (its label and dropdown, queued in dropdowns). Returns the y below it.
local function addSection(view, section, y, width, dropdowns)
    widgets.AddText(view, section.entry.boss.name, 0, y, width, widgets.CARD_FONT).colour = widgets.GOLD
    addGreyText(view, pickers.UntrackedKills(section.entry), 0, y + 20, width)
    y = y + 20 + LINE_HEIGHT + 4
    local dropdownX = width - PICKER_WIDTH
    for _, picker in ipairs(section.pickers) do
        local labelWidth = dropdownX - 20
        local label = widgets.AddText(view, picker.label, 10, y, labelWidth)
        label:SetSize(labelWidth, widgets.DROPDOWN_HEIGHT)
        label.alignVertical = ui.AlignMode.CENTRE
        local dropdownY = y
        table.insert(dropdowns, function()
            widgets.AddOrderedDropdown(view, dropdownX, dropdownY, PICKER_WIDTH, picker.options, picker.current,
                picker.onPick)
        end)
        y = y + widgets.DROPDOWN_HEIGHT + 6
    end
    return y + 6
end

-- The height of a section, to size the scrolling view before drawing into it.
local function sectionHeight(section)
    return 20 + LINE_HEIGHT + 4 + #section.pickers * (widgets.DROPDOWN_HEIGHT + 6) + 6
end

-- Draws state (see src/ui.lua) into the page.
function settings.Draw(state)
    widgets.Destroy(content)
    content = ui.Layer.new(layer)
    content:SetSize(0, 0, 1.0, 1.0)
    content.clickthrough = true
    local width, height = layer.width, layer.height

    local introBottom = widgets.AddWrapped(content, INTRO, PAD, PAD, width - 2 * PAD, widgets.SMALL_FONT,
        LINE_HEIGHT, widgets.GREY)
    local top = introBottom + 8
    widgets.AddSeparator(content, PAD, top - 4, width - 2 * PAD)

    local list = sections(state)
    if #list == 0 then
        widgets.AddText(content, NOTHING, PAD, top + 4, width - 2 * PAD)
        return
    end
    local contentHeight = 4 -- the gap above the first section (y below)
    for _, section in ipairs(list) do
        contentHeight = contentHeight + sectionHeight(section)
    end
    local viewWidth = width - 2 * PAD
    local view = frame.AddScrollView(content, PAD, top, viewWidth, height - top - 4, contentHeight, scroll)
    local rowWidth = viewWidth - frame.SCROLLBAR_SPACE

    -- Dropdowns are added last, bottom one first, so each open list is drawn
    -- over what it covers (see the Details window).
    local dropdowns = {}
    local y = 4
    for _, section in ipairs(list) do
        y = addSection(view, section, y, rowWidth, dropdowns)
    end
    for i = #dropdowns, 1, -1 do
        dropdowns[i]()
    end
end

-- One plain line, shown instead of half a page when drawing fails.
function settings.ShowError()
    widgets.Destroy(content)
    content = ui.Layer.new(layer)
    content:SetSize(0, 0, 1.0, 1.0)
    widgets.AddText(content, "Boss RNG couldn't draw its settings.", PAD, PAD)
end

return settings

-- The details window: the boss dropdown, a headline for the picked boss, then a
-- table with one row per unique, showing at most MAX_ROWS before it scrolls.

local choices = require("src/core/choices")
local format = require("src/ui/format")
local frame = require("src/ui/frame")
local info = require("src/ui/info")
local sliders = require("src/ui/sliders")
local widgets = require("src/ui/widgets")

local window = {}

local WIDTH = 400
local INNER_WIDTH = WIDTH - 2 * frame.INSET -- see frame.INSET
local PAD = 8
local TABLE_WIDTH = INNER_WIDTH - 2 * PAD
local TITLE_HEIGHT = frame.TITLE_HEIGHT
local LINE_HEIGHT = 18 -- between lines of small text

-- Table rows. Column x values are from the table's left edge.
local MAX_ROWS = 6
local ROW_HEIGHT = 34
local ROW_GAP = 2
local ROW_STEP = ROW_HEIGHT + ROW_GAP
local SLOT_X = 4
local SLOT_SIZE = 30
local ICON_SIZE = 26
local ROW_WIDTH = TABLE_WIDTH - frame.SCROLLBAR_SPACE
local ROW_BAR_WIDTH = 50
local NAME_X = SLOT_SIZE + 10
local LUCK_X = 180
-- Dry counts are right aligned, wide enough for "12,345+".
local DRY_X = 300
local DRY_WIDTH = ROW_WIDTH - 8 - DRY_X

local ROW = Vector4.new(1.0, 1.0, 1.0, 0.06)
local HEADER = Vector4.new(0.0, 0.0, 0.0, 0.35) -- the band behind the column names
local ACCENT = Vector4.new(0.85, 0.7, 0.35, 0.8) -- the line beside the headline

local box = nil -- the window while open
local position = { x = 200, y = 120 } -- kept while the plugin runs, so it reopens in place
local luckColumn = "luck" -- "luck" or "totals", also kept

local COLUMNS = { { value = "luck", label = "Luck" }, { value = "totals", label = "Totals" } }
local COLUMN_PICKER_WIDTH = 100

function window.IsOpen()
    return box ~= nil
end

function window.Close()
    info.Hide()
    widgets.Destroy(box)
    box = nil
end

local itemName = widgets.ItemName

-- Unluckiest first, then by name. A group uses its name and first item's icon.
local function sortedItems(result)
    local rows = {}
    for itemID, item in pairs(result.items) do
        local name = item.group and item.group.name or itemName(itemID)
        table.insert(rows, { id = itemID, item = item, name = name })
    end
    table.sort(rows, function(a, b)
        local luckA, luckB = a.item.luck or 1, b.item.luck or 1
        if luckA ~= luckB then
            return luckA < luckB
        end
        return a.name < b.name
    end)
    return rows
end

local function addGreyText(parent, content, x, y, width, colour)
    local text = widgets.AddText(parent, content, x, y, width, widgets.SMALL_FONT)
    text.colour = colour or widgets.GREY
    return text
end

-- The align modes have no plain "right"; horizontal BOTTOMRIGHT is right.
local function addDryText(parent, content, x, y)
    local text = widgets.AddText(parent, content, x, y, DRY_WIDTH, widgets.SMALL_FONT)
    text.alignHorizontal = ui.AlignMode.BOTTOMRIGHT
    return text
end

-- Centers text down a dropdown-height row, in line with the dropdown's text.
local function centerInDropdownRow(text, width)
    text:SetSize(width, widgets.DROPDOWN_HEIGHT)
    text.alignVertical = ui.AlignMode.CENTRE
end

-- Lines are { text, colour? }; empty ones are skipped. Returns the y below.
local function addLines(parent, lines, x, y, width)
    for _, line in ipairs(lines) do
        if line[1] ~= "" then
            addGreyText(parent, line[1], x, y, width, line[2])
            y = y + LINE_HEIGHT
        end
    end
    return y
end

-- Luck with an "i" for its assumptions and a bar, then the dry streak, tracked
-- totals, average, tip and the game's totals. Returns the y below.
local function addHeadline(parent, state, y)
    local entry = state.list[state.selected]
    local result = entry.stats
    y = y + 34

    local headlineY = y
    local notes = choices.Assumptions(entry.boss, entry.picks)
    if #notes > 0 then
        info.Add(parent, PAD + TABLE_WIDTH - 16, y + 2, "Assumptions", notes, sliders.WhereToChange(entry.boss))
    end
    y = widgets.AddLuckHeadline(parent, PAD + 8, y, TABLE_WIDTH - 30, result) + 2
    if result.luck then
        widgets.AddLuckBar(parent, PAD + 8, y, result.luck, TABLE_WIDTH - 8)
        y = y + widgets.BAR_HEIGHT + 6
    end
    y = addLines(parent, {
        { format.Dry(result) },
        { format.Tracked(result) },
        { format.Average(result) },
        { entry.boss.tip or "", widgets.MUTED },
    }, PAD + 8, y, TABLE_WIDTH - 8)
    -- The game's totals aren't tracked, so a divider sets them apart.
    local allTime = format.AllTime(result)
    if allTime ~= "" then
        widgets.AddSeparator(parent, PAD + 8, y + 3, TABLE_WIDTH - 8)
        y = addLines(parent, { { allTime, widgets.MUTED } }, PAD + 8, y + 8, TABLE_WIDTH - 8)
    end
    widgets.AddRect(parent, PAD, headlineY, 2, y - headlineY, ACCENT)
    return y + 8
end

-- A unique's row: slot and icon, name, luck or totals column, and dry streak.
-- Until the boss has tracked kills, the luck column says so and dry is empty.
local function addItemRow(view, row, y, width, tracked)
    widgets.AddRect(view, 0, y, width, ROW_HEIGHT, ROW)
    local slotY = y + (ROW_HEIGHT - SLOT_SIZE) // 2
    widgets.AddSprite(view, "RS3_INV_ICON_SLOT", SLOT_X, slotY, SLOT_SIZE, SLOT_SIZE)
    local icon = ui.Sprite.new(view)
    -- Tracked drops only, to match the luck beside it.
    local received = row.item.received
    -- The game takes only integers, and saved ids can load as 1.0. Setting the
    -- quantity draws the game's yellow count on the icon. SetAssociatedObject's
    -- quantity argument is rejected in game, so it's set separately.
    icon:SetAssociatedObject(math.tointeger(row.id))
    icon.associatedObjectQuantity = math.tointeger(received)
    icon.associatedObjectQuantityMode = received > 0 and ui.ObjectQuantityDisplayMode.ALWAYS
        or ui.ObjectQuantityDisplayMode.NEVER
    icon.alpha = received > 0 and 1.0 or 0.35
    local inset = (SLOT_SIZE - ICON_SIZE) // 2
    widgets.Place(icon, SLOT_X + inset, slotY + inset, ICON_SIZE, ICON_SIZE)

    local textY = y + (ROW_HEIGHT - widgets.TEXT_HEIGHT) // 2
    local nameWidth = LUCK_X - NAME_X - 6
    local name = widgets.Fit(row.name, widgets.ROW_FONT, nameWidth)
    widgets.AddText(view, name, NAME_X, textY, nameWidth, widgets.ROW_FONT)
    if not tracked then
        addGreyText(view, "not tracked yet", LUCK_X, textY, DRY_X - LUCK_X)
        return
    elseif luckColumn == "totals" then
        widgets.AddText(view, format.CountShort(row.item), LUCK_X, textY, DRY_X - LUCK_X, widgets.SMALL_FONT)
    else
        local labelX = LUCK_X -- the whole column, until there's a bar
        if row.item.luck then
            local barY = y + (ROW_HEIGHT - widgets.BAR_HEIGHT) // 2
            widgets.AddLuckBar(view, LUCK_X, barY, row.item.luck, ROW_BAR_WIDTH)
            labelX = LUCK_X + ROW_BAR_WIDTH + 6
        end
        widgets.AddText(view, format.LuckShort(row.item), labelX, textY, DRY_X - labelX, widgets.SMALL_FONT)
    end
    addDryText(view, format.DryCount(row.item), DRY_X, textY)
end

-- Column names on a band as tall as a dropdown. The luck heading is a dropdown
-- (queued in dropdowns) that switches between luck and totals and calls onSwitch.
local function addColumnNames(parent, y, onSwitch, dropdowns)
    widgets.AddRect(parent, PAD, y, TABLE_WIDTH, widgets.DROPDOWN_HEIGHT, HEADER)
    widgets.AddSeparator(parent, PAD, y + widgets.DROPDOWN_HEIGHT - 1, TABLE_WIDTH)
    centerInDropdownRow(widgets.AddText(parent, "Item", PAD + SLOT_X, y, 60, widgets.SMALL_FONT), 60)
    centerInDropdownRow(addDryText(parent, "Dry", PAD + DRY_X, y), DRY_WIDTH)

    table.insert(dropdowns, function()
        widgets.AddDropdown(parent, PAD + LUCK_X, y, COLUMN_PICKER_WIDTH, COLUMNS, luckColumn, function(value)
            luckColumn = value
            onSwitch()
        end)
    end)
end

-- The height of count rows, without a gap after the last.
local function rowsHeight(count)
    return math.max(0, count * ROW_STEP - ROW_GAP)
end

function window.Draw(state)
    window.Close()
    box = frame.New("BOSS RNG", WIDTH, position, window.Close)
    if not state.selected then
        widgets.AddText(box, "No boss kills yet.", PAD, TITLE_HEIGHT + 6)
        box:SetSize(WIDTH, TITLE_HEIGHT + 34)
        return
    end

    -- Dropdowns are added last, bottom one first: components added later are drawn
    -- on top and take clicks first, so each open list covers what's below it.
    local dropdowns = {}

    local pickerY = TITLE_HEIGHT + 8
    table.insert(dropdowns, function() widgets.AddBossPicker(box, state, PAD, pickerY, TABLE_WIDTH) end)
    local y = addHeadline(box, state, pickerY)
    widgets.AddSeparator(box, PAD, y, TABLE_WIDTH)
    local headerY = y + 4
    addColumnNames(box, headerY, state.onRedraw, dropdowns)
    y = headerY + widgets.DROPDOWN_HEIGHT + 3

    local result = state.list[state.selected].stats
    local tracked = result.kills + result.extraKills > 0
    local rows = sortedItems(result)
    local viewHeight = rowsHeight(math.min(#rows, MAX_ROWS))
    local view = frame.AddScrollView(box, PAD, y, TABLE_WIDTH, viewHeight, rowsHeight(#rows))
    for i, row in ipairs(rows) do
        addItemRow(view, row, (i - 1) * ROW_STEP, ROW_WIDTH, tracked)
    end
    y = y + viewHeight

    -- The box's insets plus a small gap.
    box:SetSize(WIDTH, y + 4 + 2 * frame.INSET)

    for i = #dropdowns, 1, -1 do
        dropdowns[i]()
    end
end

return window

-- The Details window, from widest to narrowest: luck over all bosses, then the
-- boss dropdown and a headline for the picked boss (its luck as a sentence and a
-- wide bar, its dry streak and totals), then a table with one row per unique
-- (item, luck, dry). It fits its contents, showing at most MAX_ROWS rows; the
-- rest scroll with the mouse wheel.

local format = require("src/format")
local stats = require("src/stats")
local frame = require("src/ui/frame")
local widgets = require("src/ui/widgets")

local window = {}

local WIDTH = 400
local INNER_WIDTH = WIDTH - 2 * frame.INSET -- keeps the margins even (see frame.INSET)
local PAD = 8
local TABLE_WIDTH = INNER_WIDTH - 2 * PAD
local TITLE_HEIGHT = frame.TITLE_HEIGHT
local LINE_HEIGHT = 18 -- between lines of small text

-- Table rows, and the x of each column from the table's left edge.
local MAX_ROWS = 6
local ROW_HEIGHT = 34
local ROW_GAP = 2
local ROW_STEP = ROW_HEIGHT + ROW_GAP
local SLOT_SIZE = 30
local ICON_SIZE = 26
local ROW_WIDTH = TABLE_WIDTH - frame.THUMB_SPACE
local ROW_BAR_WIDTH = 50
local NAME_X = SLOT_SIZE + 10
local LUCK_X = 180
-- Dry counts are right aligned in a box ending just inside the row, wide enough
-- for "12,345+".
local DRY_X = 300
local DRY_WIDTH = ROW_WIDTH - 8 - DRY_X

local ROW = Vector4.new(1.0, 1.0, 1.0, 0.06)
local ACCENT = Vector4.new(0.85, 0.7, 0.35, 0.8) -- the line beside the headline

local box = nil -- the window while it's open; destroying it removes its contents
local position = { x = 200, y = 120 } -- kept while the plugin runs, so it reopens in place

function window.IsOpen()
    return box ~= nil
end

function window.Close()
    widgets.Destroy(box)
    box = nil
end

-- The game's name for an item, or its id if that can't be read.
local function itemName(itemID)
    local ok, name = pcall(function() return config.Obj.FromID(math.tointeger(itemID)).name end)
    return ok and name or ("Item " .. tostring(itemID))
end

-- The uniques in card order: unluckiest first, then by name.
local function sortedItems(result)
    local rows = {}
    for itemID, item in pairs(result.items) do
        table.insert(rows, { id = itemID, item = item, name = itemName(itemID) })
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

local function addGreyText(parent, content, x, y, width)
    local text = widgets.AddText(parent, content, x, y, width, widgets.SMALL_FONT)
    text.colour = widgets.GREY
    return text
end

-- A dry count or the DRY heading, right aligned in the dry column. The API's
-- align modes have no plain "right": BOTTOMRIGHT on the horizontal axis is right.
local function addDryText(parent, content, x, y)
    addGreyText(parent, content, x, y, DRY_WIDTH).alignHorizontal = ui.AlignMode.BOTTOMRIGHT
end

-- One line of luck over every boss with kills. It sits above the dropdown since
-- the dropdown doesn't change it. Returns the y below it.
local function addOverall(parent, state, y)
    local allStats = {}
    for _, entry in ipairs(state.list) do
        table.insert(allStats, entry.stats)
    end
    widgets.AddText(parent, "All bosses", PAD, y, NAME_X + 40, widgets.ROW_FONT).colour = widgets.YELLOW
    local luckX = PAD + NAME_X + 44
    widgets.AddLuckLine(parent, luckX, y, TABLE_WIDTH - luckX, stats.Overall(allStats))
    return y + LINE_HEIGHT + 8
end

-- The headline for the picked boss, below room left for the dropdown: its luck
-- as a sentence and a full width bar, then its dry streak and totals. Returns
-- the y below it.
local function addHeadline(parent, state, y)
    local result = state.list[state.selected].stats
    y = y + 34

    local headlineY = y
    widgets.AddLuckHeadline(parent, PAD + 8, y, TABLE_WIDTH - 8, result)
    y = y + 24
    if result.luck then
        widgets.AddLuckBar(parent, PAD + 8, y, result.luck, TABLE_WIDTH - 8)
        y = y + widgets.BAR_HEIGHT + 6
    end
    addGreyText(parent, format.Dry(result), PAD + 8, y, TABLE_WIDTH - 8)
    y = y + LINE_HEIGHT
    addGreyText(parent, format.Totals(result), PAD + 8, y, TABLE_WIDTH - 8)
    y = y + LINE_HEIGHT
    widgets.AddRect(parent, PAD, headlineY, 2, y - headlineY, ACCENT)
    return y + 8
end

-- A row for a unique: a faint background, its slot (dimmed if not received
-- yet), then its name, a short luck bar with its group ("top 3%") and its dry
-- streak, each in its column.
local function addItemRow(view, row, y, width)
    widgets.AddRect(view, 0, y, width, ROW_HEIGHT, ROW)
    local slotY = y + (ROW_HEIGHT - SLOT_SIZE) // 2
    widgets.AddSprite(view, "RS3_INV_ICON_SLOT", 4, slotY, SLOT_SIZE, SLOT_SIZE)
    local icon = ui.Sprite.new(view)
    local received = row.item.received
    -- The game only accepts whole numbers here, and saved ids can load back as
    -- decimals (1.0), so convert. With the count as the quantity, the game draws
    -- its own yellow number on the icon, like the boss log, once one is received.
    -- (The optional quantity argument of SetAssociatedObject is rejected in game,
    -- so the quantity is set on its own.)
    icon:SetAssociatedObject(math.tointeger(row.id))
    icon.associatedObjectQuantity = math.tointeger(received)
    icon.associatedObjectQuantityMode = received > 0 and ui.ObjectQuantityDisplayMode.ALWAYS
        or ui.ObjectQuantityDisplayMode.NEVER
    icon.alpha = received > 0 and 1.0 or 0.35
    local inset = (SLOT_SIZE - ICON_SIZE) // 2
    widgets.Place(icon, 4 + inset, slotY + inset, ICON_SIZE, ICON_SIZE)

    local textY = y + (ROW_HEIGHT - widgets.TEXT_HEIGHT) // 2
    widgets.AddText(view, row.name, NAME_X, textY, LUCK_X - NAME_X - 6, widgets.ROW_FONT)
    if row.item.luck then
        local barY = y + (ROW_HEIGHT - widgets.BAR_HEIGHT) // 2
        widgets.AddLuckBar(view, LUCK_X, barY, row.item.luck, ROW_BAR_WIDTH)
    end
    local labelX = LUCK_X + ROW_BAR_WIDTH + 6
    widgets.AddText(view, format.LuckShort(row.item), labelX, textY, DRY_X - labelX, widgets.SMALL_FONT)
    addDryText(view, format.DryCount(row.item), DRY_X, textY)
end

-- The table's column names, lined up with its columns.
local function addColumnNames(parent, y)
    addGreyText(parent, "ITEM", PAD + NAME_X, y, 60)
    addGreyText(parent, "LUCK", PAD + LUCK_X, y, 60)
    addDryText(parent, "DRY", PAD + DRY_X, y)
end

-- The height of count rows, without a gap after the last.
local function rowsHeight(count)
    return math.max(0, count * ROW_STEP - ROW_GAP)
end

-- Opens the window showing state (see src/ui.lua), or redraws it in place.
function window.Draw(state)
    window.Close()
    box = frame.New("BOSS RNG", WIDTH, position, window.Close)
    if not state.selected then
        widgets.AddText(box, "No boss kills yet.", PAD, TITLE_HEIGHT + 6)
        box:SetSize(WIDTH, TITLE_HEIGHT + 34)
        return
    end

    local y = addOverall(box, state, TITLE_HEIGHT + 8)
    widgets.AddSeparator(box, PAD, y - 4, TABLE_WIDTH)
    local pickerY = y + 4
    y = addHeadline(box, state, pickerY)
    widgets.AddSeparator(box, PAD, y, TABLE_WIDTH)
    addColumnNames(box, y + 6)
    y = y + 6 + LINE_HEIGHT

    -- The uniques, in a scrolling view.
    local rows = sortedItems(state.list[state.selected].stats)
    local viewHeight = rowsHeight(math.min(#rows, MAX_ROWS))
    local view = frame.AddScrollView(box, PAD, y, TABLE_WIDTH, viewHeight, rowsHeight(#rows))
    for i, row in ipairs(rows) do
        addItemRow(view, row, (i - 1) * ROW_STEP, ROW_WIDTH)
    end
    y = y + viewHeight

    -- Below the rows: the box's insets, plus a small gap.
    box:SetSize(WIDTH, y + 4 + 2 * frame.INSET)

    -- The dropdown is added last: components added later are drawn on top and
    -- take clicks first, so its open list must come after everything it covers.
    widgets.AddBossPicker(box, state, PAD, pickerY, TABLE_WIDTH)
end

return window

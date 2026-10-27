-- The Details window, from widest to narrowest: luck over all bosses, then the
-- boss dropdown and a headline for the picked boss (its luck as a sentence and a
-- wide bar, its dry streak and totals), then a table with one row per unique
-- (item, luck, dry). It fits its contents, showing at most MAX_ROWS rows; the
-- rest scroll with the mouse wheel.

local format = require("src/format")
local safe = require("src/safe")
local stats = require("src/stats")
local widgets = require("src/ui/widgets")

local window = {}

local WIDTH = 400
-- The DEFAULT_CONTAINER box draws its children about 5 px in from its edges, so
-- content is laid out in this narrower width to keep the margins even.
local INSET = 5
local INNER_WIDTH = WIDTH - 2 * INSET
local PAD = 8
local TABLE_WIDTH = INNER_WIDTH - 2 * PAD
local TITLE_HEIGHT = 26 -- the title strip and the line under it
local LINE_HEIGHT = 18 -- between lines of small text
local THUMB_WIDTH = 3 -- the scroll position marker
local SCROLL_STEP = 30 -- pixels per mouse wheel notch

-- Table rows, and the x of each column from the table's left edge.
local MAX_ROWS = 6
local ROW_HEIGHT = 34
local ROW_GAP = 2
local ROW_STEP = ROW_HEIGHT + ROW_GAP
local SLOT_SIZE = 30
local ICON_SIZE = 26
local ROW_WIDTH = TABLE_WIDTH - THUMB_WIDTH - 4 -- leaves room for the scroll marker
local ROW_BAR_WIDTH = 50
local NAME_X = SLOT_SIZE + 10
local LUCK_X = 180
-- Dry counts are right aligned in a box ending just inside the row, wide enough
-- for "12,345+".
local DRY_X = 300
local DRY_WIDTH = ROW_WIDTH - 8 - DRY_X

-- The title strip copies the collection log's: gold Cinzel on a dark gradient
-- that lightens toward the bottom, with a gold line under it.
local TITLE_TOP = { 0.11, 0.10, 0.09 } -- red, green, blue
local TITLE_BOTTOM = { 0.20, 0.18, 0.15 }
local TITLE_LINE = Vector4.new(0.30, 0.24, 0.15, 1.0)
local GRADIENT_BAND = 3 -- pixels per band of the gradient
local ROW = Vector4.new(1.0, 1.0, 1.0, 0.06)
local ACCENT = Vector4.new(0.85, 0.7, 0.35, 0.8) -- the line beside the headline
local THUMB = Vector4.new(1.0, 1.0, 1.0, 0.35)

local frame = nil -- the window's box while it's open; destroying it removes its contents
local frameX, frameY = 200, 120 -- kept while the plugin runs, so it reopens in place
local grab = nil -- where the title bar was grabbed, while dragging

local function clamp(value, low, high)
    return math.max(low, math.min(value, high))
end

function window.IsOpen()
    return frame ~= nil
end

function window.Close()
    if frame then
        pcall(function() frame:Destroy() end)
        frame = nil
        grab = nil
    end
end

-- Lets the player move the window by its title bar. The mouse hooks give x and y
-- relative to the window, so each hold moves it by how far the mouse has moved
-- from where the title bar was grabbed.
local function makeDraggable(box, layer)
    box.clickthrough = false
    box:Subscribe(ui.Hook.ONCLICK, function(_, x, y)
        grab = y <= TITLE_HEIGHT and { x = x, y = y } or nil
    end)
    box:Subscribe(ui.Hook.ONHOLD, function(_, x, y)
        if grab then
            safe.Call("moving the window", function()
                frameX = clamp(frameX + x - grab.x, 0, layer.width - box.width)
                frameY = clamp(frameY + y - grab.y, 0, layer.height - box.height)
                box:SetPos(frameX, frameY)
            end)
        end
    end)
    box:Subscribe(ui.Hook.ONRELEASE, function()
        grab = nil
    end)
end

-- A vertical gradient from top to bottom ({ red, green, blue } each), drawn as
-- thin bands, since rectangles only take one color.
local function addGradient(box, x, y, width, height, top, bottom)
    for offset = 0, height - 1, GRADIENT_BAND do
        local t = offset / height
        local mix = {}
        for i = 1, 3 do
            mix[i] = top[i] + (bottom[i] - top[i]) * t
        end
        local band = math.min(GRADIENT_BAND, height - offset)
        widgets.AddRect(box, x, y + offset, width, band, Vector4.new(mix[1], mix[2], mix[3], 1.0))
    end
end

-- The title strip, with the game's own close sprite like the X on Jagex
-- interfaces.
local function addTitleBar(box)
    local stripHeight = TITLE_HEIGHT - 2
    addGradient(box, 0, 0, INNER_WIDTH, stripHeight, TITLE_TOP, TITLE_BOTTOM)
    widgets.AddRect(box, 0, stripHeight, INNER_WIDTH, 2, TITLE_LINE)
    local title = widgets.AddText(box, "BOSS RNG", 0, 3, INNER_WIDTH, widgets.TITLE_FONT)
    title.colour = widgets.GOLD
    widgets.Center(title)
    local close = widgets.AddSprite(box, "AIF_CLOSE_1_0", INNER_WIDTH - 24, 2, 20, 20)
    close.clickthrough = false
    close:Subscribe(ui.Hook.ONCLICK, window.Close)
end

-- An empty window at its last position, with its title bar. It's sized once its
-- contents are known.
local function newFrame()
    local layer = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP)
    local box = ui.GroupBox.new(layer)
    box.stylesheetID = id.StyleSheet.DEFAULT_CONTAINER
    box:SetPos(frameX, frameY)
    makeDraggable(box, layer)
    addTitleBar(box)
    return box
end

-- A clipped area whose contents scroll with the mouse wheel, with a thin marker
-- at its right edge showing the position when there is more than fits.
local function addScrollView(box, x, y, width, height, contentHeight)
    local view = widgets.Place(ui.Layer.new(box), x, y, width, height)
    view.clickthrough = false
    view:SetScrollSize(width, contentHeight)

    local maxScroll = contentHeight - height
    if maxScroll > 0 then
        local thumbX = x + width - THUMB_WIDTH
        local thumbHeight = math.max(20, height * height // contentHeight)
        local thumb = widgets.AddRect(box, thumbX, y, THUMB_WIDTH, thumbHeight, THUMB)
        local position = 0
        view:Subscribe(ui.Hook.ONSCROLLWHEEL, function(_, notches)
            safe.Call("scrolling", function()
                position = clamp(position + notches * SCROLL_STEP, 0, maxScroll)
                view:SetScrollPos(0, position)
                thumb:SetPos(thumbX, y + (height - thumbHeight) * position // maxScroll)
            end)
        end)
    end
    return view
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

local function addSeparator(box, y)
    widgets.AddSeparator(box, PAD, y, TABLE_WIDTH)
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
local function addOverall(box, state, y)
    local allStats = {}
    for _, entry in ipairs(state.list) do
        table.insert(allStats, entry.stats)
    end
    widgets.AddText(box, "All bosses", PAD, y, NAME_X + 40, widgets.ROW_FONT).colour = widgets.YELLOW
    local luckX = PAD + NAME_X + 44
    widgets.AddLuckLine(box, luckX, y, TABLE_WIDTH - luckX, stats.Overall(allStats))
    return y + LINE_HEIGHT + 8
end

-- The headline for the picked boss, below room left for the dropdown: its luck
-- as a sentence and a full width bar, then its dry streak and totals. Returns
-- the y below it.
local function addHeadline(box, state, y)
    local result = state.list[state.selected].stats
    y = y + 34

    local headlineY = y
    widgets.AddLuckHeadline(box, PAD + 8, y, TABLE_WIDTH - 8, result)
    y = y + 24
    if result.luck then
        widgets.AddLuckBar(box, PAD + 8, y, result.luck, TABLE_WIDTH - 8)
        y = y + widgets.BAR_HEIGHT + 6
    end
    addGreyText(box, format.Dry(result), PAD + 8, y, TABLE_WIDTH - 8)
    y = y + LINE_HEIGHT
    addGreyText(box, format.Totals(result), PAD + 8, y, TABLE_WIDTH - 8)
    y = y + LINE_HEIGHT
    widgets.AddRect(box, PAD, headlineY, 2, y - headlineY, ACCENT)
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
local function addColumnNames(box, y)
    addGreyText(box, "ITEM", PAD + NAME_X, y, 60)
    addGreyText(box, "LUCK", PAD + LUCK_X, y, 60)
    addDryText(box, "DRY", PAD + DRY_X, y)
end

-- The height of count rows, without a gap after the last.
local function rowsHeight(count)
    return math.max(0, count * ROW_STEP - ROW_GAP)
end

-- Opens the window showing state (see src/ui.lua), or redraws it in place.
function window.Draw(state)
    window.Close()
    frame = newFrame()
    if not state.selected then
        widgets.AddText(frame, "No boss kills yet.", PAD, TITLE_HEIGHT + 6)
        frame:SetSize(WIDTH, TITLE_HEIGHT + 34)
        return
    end

    local y = addOverall(frame, state, TITLE_HEIGHT + 8)
    addSeparator(frame, y - 4)
    local pickerY = y + 4
    y = addHeadline(frame, state, pickerY)
    addSeparator(frame, y)
    addColumnNames(frame, y + 6)
    y = y + 6 + LINE_HEIGHT

    -- The uniques, in a scrolling view.
    local rows = sortedItems(state.list[state.selected].stats)
    local viewHeight = rowsHeight(math.min(#rows, MAX_ROWS))
    local view = addScrollView(frame, PAD, y, TABLE_WIDTH, viewHeight, rowsHeight(#rows))
    for i, row in ipairs(rows) do
        addItemRow(view, row, (i - 1) * ROW_STEP, ROW_WIDTH)
    end
    y = y + viewHeight

    -- Below the rows: the box's insets, plus a small gap.
    frame:SetSize(WIDTH, y + 4 + 2 * INSET)

    -- The dropdown is added last: components added later are drawn on top and
    -- take clicks first, so its open list must come after everything it covers.
    widgets.AddBossPicker(frame, state, PAD, pickerY, TABLE_WIDTH)
end

return window

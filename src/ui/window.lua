-- The Details window, from widest to narrowest: luck over all bosses, then the
-- boss dropdown and a headline for the picked boss (its luck as a sentence and a
-- wide bar, its dry streak, its totals, an average player's and a dropdown for
-- each of its choices), then a table
-- with one row per unique (item, luck, dry). It fits its contents, showing at
-- most MAX_ROWS rows; the rest scroll with the mouse wheel.

local choices = require("src/choices")
local format = require("src/format")
local frame = require("src/ui/frame")
local info = require("src/ui/info")
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
local SLOT_X = 4
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
local HEADER = Vector4.new(0.0, 0.0, 0.0, 0.35) -- the band behind the column names
local ACCENT = Vector4.new(0.85, 0.7, 0.35, 0.8) -- the line beside the headline

local box = nil -- the window while it's open; destroying it removes its contents
local position = { x = 200, y = 120 } -- kept while the plugin runs, so it reopens in place
local luckColumn = "luck" -- what the luck column shows: "luck" or "totals"; kept too

-- The luck column's two views, picked in its heading.
local COLUMNS = { { value = "luck", label = "Luck" }, { value = "totals", label = "Totals" } }
local COLUMN_PICKER_WIDTH = 100
local PICKER_WIDTH = 110

function window.IsOpen()
    return box ~= nil
end

function window.Close()
    info.Hide()
    widgets.Destroy(box)
    box = nil
end

-- The game's name for an item, or its id if that can't be read.
local function itemName(itemID)
    local ok, name = pcall(function() return config.Obj.FromID(math.tointeger(itemID)).name end)
    return ok and name or ("Item " .. tostring(itemID))
end

-- The uniques in card order: unluckiest first, then by name. A group of uniques
-- (see src/bosses.lua) shows its own name, and its first item's icon.
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

-- Grey text in SMALL_FONT.
local function addGreyText(parent, content, x, y, width)
    local text = widgets.AddText(parent, content, x, y, width, widgets.SMALL_FONT)
    text.colour = widgets.GREY
    return text
end

-- A dry count or the Dry heading, right aligned in the dry column. The API's
-- align modes have no plain "right": BOTTOMRIGHT on the horizontal axis is right.
local function addDryText(parent, content, x, y)
    local text = widgets.AddText(parent, content, x, y, DRY_WIDTH, widgets.SMALL_FONT)
    text.alignHorizontal = ui.AlignMode.BOTTOMRIGHT
    return text
end

-- Makes text, at the top of a row as tall as a dropdown, as tall as the row and
-- centered down it, in line with the dropdown's own text.
local function centerInDropdownRow(text, width)
    text:SetSize(width, widgets.DROPDOWN_HEIGHT)
    text.alignVertical = ui.AlignMode.CENTRE
end

-- One line of luck over every boss with kills. It sits above the dropdown since
-- the dropdown doesn't change it. Returns the y below it.
local function addOverall(parent, state, y)
    -- Uniques and an average player's are added up over every boss, so bosses
    -- with more kills count for more.
    widgets.AddText(parent, "All bosses combined", PAD, y, 132, widgets.ROW_FONT).colour = widgets.YELLOW
    local luckX = PAD + 136
    widgets.AddLuckLine(parent, luckX, y, TABLE_WIDTH - luckX, state.overall)
    return y + LINE_HEIGHT + 8
end

-- A pooled unique's label: "Untracked Shards from this boss".
local function splitLabel(itemID, item)
    return "Untracked " .. (item.plural or itemName(itemID)) .. " from this boss"
end

-- The picked boss's assumptions: its own and its picks (see choices.Assumptions),
-- and for each pooled unique (see stats.Pools) the player's split of untracked
-- drops, or, if not split, that it's left out until it is.
local function assumptions(state, entry)
    local notes = choices.Assumptions(entry.boss, entry.picks)
    for itemID, item in pairs(entry.boss.items) do
        local pool = state.pools[itemID]
        if pool and pool.split then
            local share = pool.split[entry.boss.key]
            table.insert(notes, splitLabel(itemID, item) .. ": " .. share .. " of " .. pool.untracked)
        elseif pool and pool.untracked and not pool.received then
            table.insert(notes, (item.plural or itemName(itemID)) .. " left out until untracked ones are split")
        end
    end
    return notes
end

-- The picked boss's dropdowns, each { label, options, current, onPick }: one per
-- choice, then one per pooled unique whose untracked drops the player can split
-- (see stats.Pools), listing "Not set" and each count from 0.
local function pickers(state, entry)
    local list = {}
    for _, choice in ipairs(entry.boss.choices or {}) do
        table.insert(list, { label = choice.label, options = choice.options, current = entry.picks[choice.key],
            onPick = function(value) state.onChoose(entry.boss, choice, value) end })
    end
    for itemID, item in pairs(entry.boss.items) do
        local pool = state.pools[itemID]
        if pool and pool.ask then
            local options = {}
            for count = 0, pool.untracked do
                table.insert(options, { value = count, label = tostring(count) })
            end
            table.insert(options, { value = false, label = "Not set" })
            local label = splitLabel(itemID, item) .. " (of " .. pool.untracked .. ")"
            table.insert(list, { label = label, options = options,
                current = pool.split and pool.split[entry.boss.key] or false,
                onPick = function(value) state.onSplit(pool, itemID, entry.boss, value or nil) end })
        end
    end
    return list
end

-- A line per dropdown of the picked boss (see pickers): its label, and the
-- dropdown, queued in dropdowns (see window.Draw). A divider sets them apart from
-- the lines of text above. Returns the y below them.
local function addPickers(parent, state, y, dropdowns)
    local list = pickers(state, state.list[state.selected])
    if #list == 0 then
        return y
    end
    widgets.AddSeparator(parent, PAD + 8, y + 3, TABLE_WIDTH - 8)
    y = y + 8
    local dropdownX = PAD + TABLE_WIDTH - PICKER_WIDTH
    for _, picker in ipairs(list) do
        local labelWidth = dropdownX - PAD - 12
        centerInDropdownRow(addGreyText(parent, picker.label, PAD + 8, y, labelWidth), labelWidth)
        local dropdownY = y
        table.insert(dropdowns, function()
            widgets.AddOrderedDropdown(parent, dropdownX, dropdownY, PICKER_WIDTH, picker.options, picker.current,
                picker.onPick)
        end)
        y = y + widgets.DROPDOWN_HEIGHT + 2
    end
    return y
end

-- The headline for the picked boss, below room left for the boss dropdown: its
-- luck as a sentence with an "i" for its assumptions, a full width bar, then its
-- dry streak, its totals, what an average player would have and its dropdowns.
-- Returns the y below it.
local function addHeadline(parent, state, y, dropdowns)
    local entry = state.list[state.selected]
    local result = entry.stats
    y = y + 34

    local headlineY = y
    widgets.AddLuckHeadline(parent, PAD + 8, y, TABLE_WIDTH - 30, result)
    local notes = assumptions(state, entry)
    if #notes > 0 then
        info.Add(parent, PAD + TABLE_WIDTH - 16, y + 2, "Assumptions", notes)
    end
    y = y + 24
    if result.luck then
        widgets.AddLuckBar(parent, PAD + 8, y, result.luck, TABLE_WIDTH - 8)
        y = y + widgets.BAR_HEIGHT + 6
    end
    addGreyText(parent, format.Dry(result), PAD + 8, y, TABLE_WIDTH - 8)
    y = y + LINE_HEIGHT
    addGreyText(parent, format.Totals(result), PAD + 8, y, TABLE_WIDTH - 8)
    y = y + LINE_HEIGHT
    addGreyText(parent, format.Average(result), PAD + 8, y, TABLE_WIDTH - 8)
    y = addPickers(parent, state, y + LINE_HEIGHT, dropdowns)
    widgets.AddRect(parent, PAD, headlineY, 2, y - headlineY, ACCENT)
    return y + 8
end

-- A row for a unique: a faint background, its slot (dimmed if not received
-- yet), then its name, its luck column (a short luck bar with its group, "top
-- 3%", or its counts, "12 · avg 19.4") and its dry streak, each in its column.
local function addItemRow(view, row, y, width)
    widgets.AddRect(view, 0, y, width, ROW_HEIGHT, ROW)
    local slotY = y + (ROW_HEIGHT - SLOT_SIZE) // 2
    widgets.AddSprite(view, "RS3_INV_ICON_SLOT", SLOT_X, slotY, SLOT_SIZE, SLOT_SIZE)
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
    widgets.Place(icon, SLOT_X + inset, slotY + inset, ICON_SIZE, ICON_SIZE)

    local textY = y + (ROW_HEIGHT - widgets.TEXT_HEIGHT) // 2
    local nameWidth = LUCK_X - NAME_X - 6
    local name = widgets.Fit(row.name, widgets.ROW_FONT, nameWidth)
    widgets.AddText(view, name, NAME_X, textY, nameWidth, widgets.ROW_FONT)
    if luckColumn == "totals" then
        widgets.AddText(view, format.CountShort(row.item), LUCK_X, textY, DRY_X - LUCK_X, widgets.SMALL_FONT)
    else
        if row.item.luck then
            local barY = y + (ROW_HEIGHT - widgets.BAR_HEIGHT) // 2
            widgets.AddLuckBar(view, LUCK_X, barY, row.item.luck, ROW_BAR_WIDTH)
        end
        local labelX = LUCK_X + ROW_BAR_WIDTH + 6
        widgets.AddText(view, format.LuckShort(row.item), labelX, textY, DRY_X - labelX, widgets.SMALL_FONT)
    end
    addDryText(view, format.DryCount(row.item), DRY_X, textY)
end

-- The table's column names on a dark band as tall as a dropdown, with a line
-- under it, each at its column's edge. The luck column's heading is a dropdown,
-- queued in dropdowns, switching it between luck and totals; picking calls
-- onSwitch. The other names match the dropdown's text, so the row reads as one.
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

-- Opens the window showing state (see src/ui.lua), or redraws it in place.
function window.Draw(state)
    window.Close()
    box = frame.New("BOSS RNG", WIDTH, position, window.Close)
    if not state.selected then
        widgets.AddText(box, "No boss kills yet.", PAD, TITLE_HEIGHT + 6)
        box:SetSize(WIDTH, TITLE_HEIGHT + 34)
        return
    end

    -- Dropdowns are queued from the top down and added last, bottom one first:
    -- components added later are drawn on top and take clicks first, so each
    -- open list comes after everything it covers.
    local dropdowns = {}

    local y = addOverall(box, state, TITLE_HEIGHT + 8)
    widgets.AddSeparator(box, PAD, y - 4, TABLE_WIDTH)
    local pickerY = y + 4
    table.insert(dropdowns, function() widgets.AddBossPicker(box, state, PAD, pickerY, TABLE_WIDTH) end)
    y = addHeadline(box, state, pickerY, dropdowns)
    widgets.AddSeparator(box, PAD, y, TABLE_WIDTH)
    local headerY = y + 4
    addColumnNames(box, headerY, state.onRedraw, dropdowns)
    y = headerY + widgets.DROPDOWN_HEIGHT + 3

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

    for i = #dropdowns, 1, -1 do
        dropdowns[i]()
    end
end

return window

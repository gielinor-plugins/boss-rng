-- The details window: the boss dropdown, a summary of the boss's luck, then Luck
-- and Info tabs. Its size is fixed: only the tab pages scroll.

local common = require("src/ui/common")
local format = require("src/ui/format")
local luckBar = require("src/ui/luck_bar")

local window = {}

local WIDTH = 440
local PAD = 12
local INNER = WIDTH - 2 * 8 - 2 * PAD -- the window's borders are 8 px
local SUMMARY_Y = 46 -- below the dropdown
local TABS_Y = 220 -- fixed, so the summary's length never moves the tabs

local DIVIDER = common.Divider(PAD)

-- The Luck tab: a fixed header, then a framed panel whose rows scroll. A row is a
-- 40 px item slot, then inline columns at these x positions in the panel.
local ROWS, ROW_GAP = 4, 4 -- rows shown before the panel scrolls
-- The panel: 2 px padding around the rows, inside its 4 px frame.
local PANEL_HEIGHT = ROWS * 40 + (ROWS - 1) * ROW_GAP + 2 * 2 + 2 * 4
local PAGE_HEIGHT = 28 + PANEL_HEIGHT + 6 -- the header's 28 px above, 6 px below
-- The window's height: the title bar (32 px), the content down to the tabs, the tab
-- strip (42 px), the page and the bottom frame (8 px).
local HEIGHT = 32 + TABS_Y + 42 + PAGE_HEIGHT + 8
-- Luck and Dry are as wide as their widest text in the rows' font, measured in game:
-- the bar, a 6 px gap and "bottom 40%" (86 px) for Luck, then an 8 px gap; "99,999+"
-- (53 px) for Dry. Names get the rest, and are shortened to fit.
local NAME_X, NAME_WIDTH, VALUE_X, DRY_X, DRY_WIDTH = 50, 135, 193, 333, 53
local BAR_WIDTH = 40
local INSET = 10 -- the panel's x on the page (6 px padding and a 4 px frame), for the header
local STRIPES = { 0xFFFFFF0D, 0xFFFFFF05 }
-- The align modes have no plain "right"; horizontal BOTTOMRIGHT is right.
local RIGHT = ui.AlignMode.BOTTOMRIGHT

local win = nil -- the window while open
local position = { x = 200, y = 120 } -- kept while the plugin runs, so it reopens in place
local activeTab = 1 -- the open tab, also kept

function window.IsOpen()
    return win ~= nil
end

local function remember()
    if win and win.root then
        position.x, position.y = win.root.x, win.root.y
    end
end

function window.Close()
    remember()
    local closing = win
    win = nil
    if closing then
        closing:Destroy()
    end
end

-- Each section's title, then its lines. Titles after the first sit 6 px below
-- the text above.
local function addNotes(page, sections)
    for i, section in ipairs(sections) do
        page:AddTitle({ text = section.title, marginTop = i > 1 and 6 or nil })
        for _, line in ipairs(section.lines) do
            page:AddText({ text = line })
        end
    end
end

-- Luck as a title, its bar, the dry streak, tracked totals and average, then
-- the game's totals, which a divider sets apart when anything is tracked.
local function addSummary(result)
    local title = win:AddTitle({ text = format.Luck(result) })
    local barSpace = 0
    if result.luck then
        luckBar.Add(win, PAD, title.y + title.height + 2, result.luck, INNER)
        barSpace = luckBar.HEIGHT + 6
    end
    for _, line in ipairs({ format.Dry(result), format.Tracked(result), format.Average(result) }) do
        if line ~= "" then
            win:AddText({ text = line, marginTop = barSpace })
            barSpace = 0
        end
    end
    local allTime = format.AllTime(result)
    if allTime ~= "" then
        if format.IsTracked(result) then
            win:AddDivider(DIVIDER)
        end
        win:AddText({ text = allTime })
    end
end

-- A text column on panel's current row, at x and width, beside its 40 px slot.
local function column(panel, text, x, width, align)
    panel:AddText({
        text = text,
        x = x,
        width = width,
        height = 40,
        inline = true,
        maxLines = 1,
        alignHorizontal = align,
    })
end

-- A unique's row: slot (its tooltip adds the average player's drops), name,
-- luck with its bar, and the dry streak.
local function addRow(panel, row, tracked)
    local item = row.item
    local received = math.tointeger(item.received) or 0
    local slot = panel:AddItemSlot(config.Obj.FromID(math.tointeger(row.id)), {
        -- the game's text breaks lines on <br>
        tooltip = tracked and (row.name .. "<br>Average player: " .. format.AverageShort(item))
            or row.name,
        itemInset = 4,
        disabled = received == 0, -- dimmed until one is tracked
        quantity = received > 0 and received or nil,
        quantityMode = ui.ObjectQuantityDisplayMode.ALWAYS,
    })
    local name = common.Fit(row.name, id.Font.MUSEO_SANS_15PT_REGULAR, NAME_WIDTH)
    column(panel, name, NAME_X, NAME_WIDTH)
    if not tracked then
        column(panel, "not tracked yet", VALUE_X, DRY_X - VALUE_X)
        column(panel, "-", DRY_X, DRY_WIDTH, RIGHT)
        return
    end
    if item.luck then
        luckBar.AddInRow(panel, slot, VALUE_X, item.luck, BAR_WIDTH)
        local x = VALUE_X + BAR_WIDTH + 6
        column(panel, format.LuckShort(item), x, DRY_X - x)
    else
        column(panel, format.LuckShort(item), VALUE_X, DRY_X - VALUE_X)
    end
    local dry = format.DryCount(item)
    column(panel, dry ~= "" and dry or "-", DRY_X, DRY_WIDTH, RIGHT) -- "-": no dry streak yet
end

-- The column names, fixed above the panel.
local function addHeader(page)
    page:AddText({ text = "Item", x = INSET + 2, width = NAME_X + NAME_WIDTH, height = 20 })
    page:AddText({ text = "Luck", inline = true, x = INSET + VALUE_X, width = 60, height = 20 })
    page:AddText({
        text = "Dry",
        inline = true,
        x = INSET + DRY_X,
        width = DRY_WIDTH,
        height = 20,
        alignHorizontal = RIGHT,
    })
end

local function addTabs(entry)
    local result = entry.stats
    local tracked = format.IsTracked(result)
    local notes = entry.notes
    local tabs = win:AddTabs({
        { text = "Luck", scrollable = false }, -- its panel scrolls instead
        { text = "Info", disabled = #notes == 0 },
    }, {
        y = TABS_Y,
        height = 42 + PAGE_HEIGHT, -- the tab strip is 42 px
        activeIndex = activeTab,
        contentLayout = { startY = 4, padding = 6, rowGap = 4 },
        onChange = function(_, index)
            activeTab = index
        end,
    })
    local page = tabs:GetPage(1)
    addHeader(page)
    local panel = page:AddPanel({
        height = PANEL_HEIGHT,
        rowBackgroundColours = STRIPES,
        layout = { startY = 2, padding = 2, rowGap = ROW_GAP },
    })
    for _, row in ipairs(entry.rows) do
        addRow(panel, row, tracked)
    end
    panel:RefreshRowBackgrounds()
    addNotes(tabs:GetPage(2), notes)
end

function window.Draw(state)
    window.Close()
    win = prettyui.Window.new(common.TopLayer(), {
        title = "Boss RNG",
        x = position.x,
        y = position.y,
        width = WIDTH,
        height = HEIGHT,
        scrollable = false,
        destroyOnClose = true,
        layout = { startY = SUMMARY_Y, padding = PAD },
        onClose = function(closing)
            if win == closing then
                remember()
                win = nil
            end
        end,
    })
    if not state.selected then
        win:AddText({ text = "No boss kills yet. Kill a supported boss to start." })
        return
    end
    local entry = state.list[state.selected]
    addSummary(entry.stats)
    addTabs(entry)
    common.AddBossPicker(win, state.list, state.selected, state.onPick, { y = 8 })
end

return window

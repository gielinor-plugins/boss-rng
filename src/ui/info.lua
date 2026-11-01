-- A small gold "i" that shows a box of notes while the mouse is over it.

local safe = require("src/utils/safe")
local widgets = require("src/ui/widgets")

local info = {}

local SIZE = 16 -- the "i" badge
local BADGE_BACK = Vector4.new(0.0, 0.0, 0.0, 0.6)

-- Styled like the game's own hover boxes.
local BOX_WIDTH = 270
local PAD = 6
local LINE_HEIGHT = 16
local BULLET_WIDTH = 10
local BORDER = Vector4.new(0.42, 0.39, 0.33, 1.0)
local BACK = Vector4.new(0.04, 0.04, 0.03, 0.94)
local TITLE = Vector4.new(1.0, 0.6, 0.12, 1.0)
local TEXT = Vector4.new(0.92, 0.92, 0.92, 1.0)

local shown = nil -- the box while the mouse is over an "i"

function info.Hide()
    widgets.Destroy(shown)
    shown = nil
end

local function addWrapped(box, content, x, y, width, colour)
    return widgets.AddWrapped(box, content, x, y, width, widgets.SMALL_FONT, LINE_HEIGHT, colour or TEXT)
end

local function addDivider(box, y, width)
    widgets.AddRect(box, PAD, y, width, 1, BORDER)
    return y + 4
end

-- The border and fill are added first, so they're drawn underneath, and
-- sized once the lines are drawn.
local function show(parent, x, y, title, notes, footer)
    info.Hide()
    local box = widgets.Place(ui.Layer.new(parent), x, y, BOX_WIDTH, 0)
    shown = box
    local border = widgets.AddRect(box, 0, 0, BOX_WIDTH, 0, BORDER)
    local back = widgets.AddRect(box, 1, 1, BOX_WIDTH - 2, 0, BACK)

    local innerWidth = BOX_WIDTH - 2 * PAD
    widgets.AddText(box, title, PAD, PAD, innerWidth, widgets.ROW_FONT).colour = TITLE
    local lineY = addDivider(box, PAD + widgets.TEXT_HEIGHT, innerWidth)

    for _, note in ipairs(notes) do
        addWrapped(box, "-", PAD, lineY, BULLET_WIDTH)
        lineY = addWrapped(box, note, PAD + BULLET_WIDTH, lineY, innerWidth - BULLET_WIDTH)
    end
    if footer then
        lineY = addWrapped(box, footer, PAD, addDivider(box, lineY + 2, innerWidth), innerWidth, widgets.GREY)
    end

    local height = lineY + PAD
    box:SetSize(BOX_WIDTH, height)
    border:SetSize(BOX_WIDTH, height)
    back:SetSize(BOX_WIDTH - 2, height - 2)
end

-- Adds an "i" at x, y in parent. The box opens below it, right edges aligned.
function info.Add(parent, x, y, title, notes, footer)
    widgets.AddRect(parent, x, y, SIZE, SIZE, widgets.GOLD) -- a 1 px gold border
    widgets.AddRect(parent, x + 1, y + 1, SIZE - 2, SIZE - 2, BADGE_BACK)
    local label = widgets.Place(ui.Text.new(parent), x, y, SIZE, SIZE)
    label.font = widgets.ROW_FONT
    label.content = "i"
    label.colour = widgets.GOLD
    widgets.Center(label)

    -- The label catches the mouse for the whole badge.
    label.clickthrough = false
    label:Subscribe(ui.Hook.ONMOUSEOVER, function()
        safe.Call("showing notes", show, parent, x + SIZE - BOX_WIDTH, y + SIZE + 4, title, notes, footer)
    end)
    label:Subscribe(ui.Hook.ONMOUSELEAVE, info.Hide)
end

return info

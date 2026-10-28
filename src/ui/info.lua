-- A small gold "i" that shows a box of notes while the mouse is over it. The
-- Details window uses it for the assumptions behind a boss's numbers.

local safe = require("src/safe")
local widgets = require("src/ui/widgets")

local info = {}

local SIZE = 16 -- the "i" badge
local BADGE_BACK = Vector4.new(0.0, 0.0, 0.0, 0.6)

-- The box copies the game's own hover boxes: a near-black fill with a thin
-- warm-grey border, an orange title over a line, and white text.
local BOX_WIDTH = 240
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

local function addLine(box, content, x, y, width)
    widgets.AddText(box, content, x, y, width, widgets.SMALL_FONT).colour = TEXT
end

-- Opens the box at x, y in parent: title, then each note as a bullet. A note too
-- long for one line wraps, its later lines lined up under its text. The border
-- and fill are added first, so they're drawn underneath, and sized once the
-- lines are drawn.
local function show(parent, x, y, title, notes)
    info.Hide()
    local box = widgets.Place(ui.Layer.new(parent), x, y, BOX_WIDTH, 0)
    shown = box
    local border = widgets.AddRect(box, 0, 0, BOX_WIDTH, 0, BORDER)
    local back = widgets.AddRect(box, 1, 1, BOX_WIDTH - 2, 0, BACK)

    local innerWidth = BOX_WIDTH - 2 * PAD
    widgets.AddText(box, title, PAD, PAD, innerWidth, widgets.ROW_FONT).colour = TITLE
    local lineY = PAD + widgets.TEXT_HEIGHT
    widgets.AddRect(box, PAD, lineY, innerWidth, 1, BORDER)
    lineY = lineY + 4

    local textWidth = innerWidth - BULLET_WIDTH
    for _, note in ipairs(notes) do
        addLine(box, "-", PAD, lineY, BULLET_WIDTH)
        for _, line in ipairs(widgets.Wrap(note, widgets.SMALL_FONT, textWidth)) do
            addLine(box, line, PAD + BULLET_WIDTH, lineY, textWidth)
            lineY = lineY + LINE_HEIGHT
        end
    end

    local height = lineY + PAD
    box:SetSize(BOX_WIDTH, height)
    border:SetSize(BOX_WIDTH, height)
    back:SetSize(BOX_WIDTH - 2, height - 2)
end

-- Adds an "i" with its top-left corner at x, y in parent. While the mouse is over
-- it, a box with title and one bullet per note opens just below it, its right
-- edge lined up with the "i".
function info.Add(parent, x, y, title, notes)
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
        safe.Call("showing notes", show, parent, x + SIZE - BOX_WIDTH, y + SIZE + 4, title, notes)
    end)
    label:Subscribe(ui.Hook.ONMOUSELEAVE, info.Hide)
end

return info

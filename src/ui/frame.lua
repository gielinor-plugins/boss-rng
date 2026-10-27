-- A movable window in the game's style, and a scrolling area to put in it. The
-- window has a title strip like the collection log's, with the game's close X,
-- and is dragged by that strip. What goes inside is up to the caller.

local safe = require("src/safe")
local widgets = require("src/ui/widgets")

local frame = {}

-- The DEFAULT_CONTAINER box draws its children about 5 px in from its edges, so
-- content is laid out in a width this much narrower on each side.
frame.INSET = 5
frame.TITLE_HEIGHT = 26 -- the title strip and the line under it

local THUMB_WIDTH = 3 -- the scroll position marker
frame.THUMB_SPACE = THUMB_WIDTH + 4 -- room to leave for it at a scrolling area's right edge
local SCROLL_STEP = 30 -- pixels per mouse wheel notch

-- The title strip copies the collection log's: gold Cinzel on a dark gradient
-- that lightens toward the bottom, with a gold line under it.
local TITLE_TOP = { 0.11, 0.10, 0.09 } -- red, green, blue
local TITLE_BOTTOM = { 0.20, 0.18, 0.15 }
local TITLE_LINE = Vector4.new(0.30, 0.24, 0.15, 1.0)
local GRADIENT_BAND = 3 -- pixels per band of the gradient
local THUMB = Vector4.new(1.0, 1.0, 1.0, 0.35)

local function clamp(value, low, high)
    return math.max(low, math.min(value, high))
end

-- Lets the player move the box by its title strip. The mouse hooks give x and y
-- relative to the box, so each hold moves it by how far the mouse has moved from
-- where the strip was grabbed. The new position is kept in position.
local function makeDraggable(box, layer, position)
    local grab = nil
    box.clickthrough = false
    box:Subscribe(ui.Hook.ONCLICK, function(_, x, y)
        grab = y <= frame.TITLE_HEIGHT and { x = x, y = y } or nil
    end)
    box:Subscribe(ui.Hook.ONHOLD, function(_, x, y)
        if grab then
            safe.Call("moving the window", function()
                position.x = clamp(position.x + x - grab.x, 0, layer.width - box.width)
                position.y = clamp(position.y + y - grab.y, 0, layer.height - box.height)
                box:SetPos(position.x, position.y)
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

local function addTitleBar(box, title, innerWidth, onClose)
    local stripHeight = frame.TITLE_HEIGHT - 2
    addGradient(box, 0, 0, innerWidth, stripHeight, TITLE_TOP, TITLE_BOTTOM)
    widgets.AddRect(box, 0, stripHeight, innerWidth, 2, TITLE_LINE)
    local text = widgets.AddText(box, title, 0, 3, innerWidth, widgets.TITLE_FONT)
    text.colour = widgets.GOLD
    widgets.Center(text)
    local close = widgets.AddSprite(box, "AIF_CLOSE_1_0", innerWidth - 24, 2, 20, 20)
    close.clickthrough = false
    close:Subscribe(ui.Hook.ONCLICK, onClose)
end

-- An empty window of the given width at position ({ x, y }, updated as the
-- player drags it), with a title strip. onClose runs when its X is clicked.
-- Size it with box:SetSize(width, height) once its contents are known.
function frame.New(title, width, position, onClose)
    local layer = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP)
    local box = ui.GroupBox.new(layer)
    box.stylesheetID = id.StyleSheet.DEFAULT_CONTAINER
    box:SetPos(position.x, position.y)
    makeDraggable(box, layer, position)
    addTitleBar(box, title, width - 2 * frame.INSET, onClose)
    return box
end

-- A clipped area whose contents scroll with the mouse wheel, with a thin marker
-- at its right edge showing the position when there is more than fits. Add the
-- contents to the returned layer, keeping THUMB_SPACE free at the right.
function frame.AddScrollView(box, x, y, width, height, contentHeight)
    local view = widgets.Place(ui.Layer.new(box), x, y, width, height)
    view.clickthrough = false
    view:SetScrollSize(width, contentHeight)

    local maxScroll = contentHeight - height
    if maxScroll > 0 then
        local thumbX = x + width - THUMB_WIDTH
        local thumbHeight = math.max(20, height * height // contentHeight)
        local thumb = widgets.AddRect(box, thumbX, y, THUMB_WIDTH, thumbHeight, THUMB)
        local scrolled = 0
        view:Subscribe(ui.Hook.ONSCROLLWHEEL, function(_, notches)
            safe.Call("scrolling", function()
                scrolled = clamp(scrolled + notches * SCROLL_STEP, 0, maxScroll)
                view:SetScrollPos(0, scrolled)
                thumb:SetPos(thumbX, y + (height - thumbHeight) * scrolled // maxScroll)
            end)
        end)
    end
    return view
end

return frame

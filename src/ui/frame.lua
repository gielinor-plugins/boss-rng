-- A movable window in the game's style, and a scrolling area to put in it. The
-- window has a title strip like the collection log's, with the game's close X,
-- and is dragged by that strip. What goes inside is up to the caller. The
-- scrolling area's scrollbar is drawn from the game's own scrollbar sprites,
-- since the API documents no scrollbar component.

local safe = require("src/safe")
local widgets = require("src/ui/widgets")

local frame = {}

-- The DEFAULT_CONTAINER box draws its children about 5 px in from its edges, so
-- content is laid out in a width this much narrower on each side.
frame.INSET = 5
frame.TITLE_HEIGHT = 26 -- the title strip and the line under it

local BAR_WIDTH = 12 -- the scrollbar
frame.SCROLLBAR_SPACE = BAR_WIDTH + 4 -- room to leave for it at a scrolling area's right edge
local ARROW_HEIGHT = 12
local CAP_HEIGHT = 6 -- the handle's rounded ends
local MIN_HANDLE = 2 * CAP_HEIGHT + 8
local SCROLL_STEP = 30 -- pixels per mouse wheel notch or arrow click

-- The game's scrollbar sprites: arrows (up, down) normal, under the mouse and
-- greyed out at the end, the track, and the handle's top, middle and bottom.
local ARROWS = {
    up = { normal = "SCROLLBAR_V2_0", over = "SCROLLBAR_V2_2", ended = "SCROLLBAR_V2_6" },
    down = { normal = "SCROLLBAR_V2_1", over = "SCROLLBAR_V2_3", ended = "SCROLLBAR_V2_7" },
}
local TRACK = "SCROLLBAR_DRAGGER_V2_3"
local HANDLE_TOP, HANDLE_MIDDLE, HANDLE_BOTTOM = "SCROLLBAR_DRAGGER_V2_0", "SCROLLBAR_DRAGGER_V2_1",
    "SCROLLBAR_DRAGGER_V2_2"

-- The title strip copies the collection log's: gold Cinzel on a dark gradient
-- that lightens toward the bottom, with a gold line under it.
local TITLE_TOP = { 0.11, 0.10, 0.09 } -- red, green, blue
local TITLE_BOTTOM = { 0.20, 0.18, 0.15 }
local TITLE_LINE = Vector4.new(0.30, 0.24, 0.15, 1.0)
local GRADIENT_BAND = 3 -- pixels per band of the gradient

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

-- An arrow button of the scrollbar, pointing which way ("up" or "down"). It
-- lights up under the mouse, greys out once the end is reached (see update),
-- and calls onPress when clicked.
local function addArrow(box, which, x, y, onPress)
    local sprites = ARROWS[which]
    local arrow = widgets.AddSprite(box, sprites.normal, x, y, BAR_WIDTH, ARROW_HEIGHT)
    arrow.clickthrough = false
    local ended, over = false, false
    local function show()
        local name = ended and sprites.ended or (over and sprites.over or sprites.normal)
        arrow.sprite = id.Sprite[name]
    end
    arrow:Subscribe(ui.Hook.ONMOUSEOVER, function() over = true; show() end)
    arrow:Subscribe(ui.Hook.ONMOUSELEAVE, function() over = false; show() end)
    arrow:Subscribe(ui.Hook.ONCLICK, function() safe.Call("scrolling", onPress) end)
    return function(atEnd)
        ended = atEnd
        show()
    end
end

-- The scrollbar's handle: its rounded top and bottom, and a middle stretched
-- between them, in a layer moved as one.
local function addHandle(box, x, height)
    local handle = widgets.Place(ui.Layer.new(box), x, 0, BAR_WIDTH, height)
    handle.clickthrough = false
    widgets.AddSprite(handle, HANDLE_TOP, 0, 0, BAR_WIDTH, CAP_HEIGHT)
    widgets.AddSprite(handle, HANDLE_MIDDLE, 0, CAP_HEIGHT, BAR_WIDTH, height - 2 * CAP_HEIGHT)
    widgets.AddSprite(handle, HANDLE_BOTTOM, 0, height - CAP_HEIGHT, BAR_WIDTH, CAP_HEIGHT)
    return handle
end

-- A clipped area whose contents scroll, with the game's scrollbar at its right
-- edge when there is more than fits: arrows, a track and a handle to drag, and
-- the mouse wheel over the area. Add the contents to the returned layer,
-- keeping SCROLLBAR_SPACE free at the right. Optional scroll ({ y = pixels })
-- keeps the position across redraws: the view starts there, and updates it as
-- the player scrolls.
function frame.AddScrollView(box, x, y, width, height, contentHeight, scroll)
    local view = widgets.Place(ui.Layer.new(box), x, y, width, height)
    view.clickthrough = false
    view:SetScrollSize(width, contentHeight)

    local maxScroll = contentHeight - height
    if maxScroll <= 0 then
        return view
    end
    scroll = scroll or { y = 0 }
    local barX = x + width - BAR_WIDTH
    local trackTop, trackHeight = y + ARROW_HEIGHT, height - 2 * ARROW_HEIGHT
    widgets.AddSprite(box, TRACK, barX, trackTop, BAR_WIDTH, trackHeight)
    local handleHeight = clamp(trackHeight * height // contentHeight, MIN_HANDLE, trackHeight)
    local handle = addHandle(box, barX, handleHeight)
    local travel = trackHeight - handleHeight -- how far the handle moves, top to bottom

    local updateUp, updateDown
    local function scrollTo(position)
        scroll.y = clamp(position, 0, maxScroll)
        view:SetScrollPos(0, scroll.y)
        handle:SetPos(barX, trackTop + travel * scroll.y // maxScroll)
        updateUp(scroll.y == 0)
        updateDown(scroll.y == maxScroll)
    end
    updateUp = addArrow(box, "up", barX, y, function() scrollTo(scroll.y - SCROLL_STEP) end)
    updateDown = addArrow(box, "down", barX, y + height - ARROW_HEIGHT, function()
        scrollTo(scroll.y + SCROLL_STEP)
    end)
    scrollTo(scroll.y)

    view:Subscribe(ui.Hook.ONSCROLLWHEEL, function(_, notches)
        safe.Call("scrolling", scrollTo, scroll.y + notches * SCROLL_STEP)
    end)
    -- Dragging the handle: hooks give y relative to the handle, so each hold
    -- moves it by how far the mouse has moved from where it was grabbed.
    local grab = nil
    handle:Subscribe(ui.Hook.ONCLICK, function(_, _, mouseY) grab = mouseY end)
    handle:Subscribe(ui.Hook.ONHOLD, function(_, _, mouseY)
        if grab and travel > 0 then
            safe.Call("scrolling", function()
                local handleY = travel * scroll.y / maxScroll + mouseY - grab
                scrollTo(math.floor(handleY * maxScroll / travel + 0.5))
            end)
        end
    end)
    handle:Subscribe(ui.Hook.ONRELEASE, function() grab = nil end)
    return view
end

return frame

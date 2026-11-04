-- A bar filled to a luck share, with a tick at the middle for an average player.

local luckBar = {}

luckBar.HEIGHT = 10

local BAR_BACK = Vector4.new(0.0, 0.0, 0.0, 0.6)
local TICK = Vector4.new(1.0, 1.0, 1.0, 0.9) -- marks average luck on a bar
-- The filled part: a plain gold sprite that stretches cleanly.
local BAR_FILL = "TIMERBAR_120_S_1"

local function rect(parent, x, y, width, colour)
    local bar = ui.Rectangle.new(parent)
    bar:SetPos(x, y)
    bar:SetSize(width, luckBar.HEIGHT)
    bar.colour, bar.fill = colour, true
end

-- On host (a window, page or panel) at x, y in its content layer.
function luckBar.Add(host, x, y, share, width)
    local parent = host.content
    rect(parent, x, y, width, BAR_BACK)
    local filled = math.floor(width * share)
    if filled > 0 then
        local fill = ui.Sprite.new(parent)
        fill:SetPos(x, y)
        fill:SetSize(filled, luckBar.HEIGHT)
        fill.sprite = id.Sprite[BAR_FILL]
    end
    rect(parent, x + width // 2, y, 2, TICK)
end

-- On host at x, centered on the row that starts with component.
function luckBar.AddInRow(host, component, x, share, width)
    local row = component.root
    luckBar.Add(host, x, row.y + (row.height - luckBar.HEIGHT) // 2, share, width)
end

return luckBar

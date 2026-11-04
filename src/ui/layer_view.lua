-- A view filling a layer the game gives Boss RNG: the ribbon panel or the settings
-- page. The game clears the layer each time it opens or resizes it, and when it
-- minimizes it or hands it to another plugin, with no event for either. So the view
-- keeps a tiny invisible marker in the layer: once it's no longer among the layer's
-- children, the layer isn't Boss RNG's to draw in until it's given back (tested:
-- docs/technical/ui.md).

local layerView = {}

-- A 1 x 1 transparent rectangle in layer, or nil if it can't be made.
local function newMarker(layer)
    local ok, marker = pcall(function()
        local rectangle = ui.Rectangle.new(layer)
        rectangle:SetSize(1, 1)
        rectangle.alpha = 0
        return rectangle
    end)
    return ok and marker or nil
end

-- Whether marker is still one of layer's children: false once the game has cleared it.
-- A layer that can't list its children falls back to the marker's own visibility.
local function isShown(layer, marker)
    local listed, isChild = pcall(function()
        local found = false
        layer:IterateDynamicComponents(function(component)
            found = component == marker
            return found -- stops at the marker
        end)
        return found
    end)
    if listed then
        return isChild
    end
    local ok, shown = pcall(function()
        return marker.visibleGlobal
    end)
    return ok and shown == true
end

-- layout: the view's flow layout options.
function layerView.New(layout)
    local page = { layer = nil, view = nil, marker = nil }

    -- Destroying may fail if the game already cleared the layer.
    local function destroy()
        if page.view then
            pcall(function()
                page.view:Destroy()
            end)
        end
        page.view = nil
    end

    function page.Attach(layer)
        page.layer, page.view, page.marker = layer, nil, newMarker(layer)
    end

    -- Attached, and still shown: not minimized, closed or given to another plugin.
    function page.IsOpen()
        return page.layer ~= nil and page.marker ~= nil and isShown(page.layer, page.marker)
    end

    -- A fresh, empty view to draw into.
    function page.Fresh()
        destroy()
        page.view = prettyui.SimpleView.new(page.layer, {
            width = 0,
            height = 0,
            widthAnchor = 1.0,
            heightAnchor = 1.0,
            layout = layout,
        })
        return page.view
    end

    function page.Detach()
        destroy()
        page.layer, page.marker = nil, nil
    end

    return page
end

return layerView

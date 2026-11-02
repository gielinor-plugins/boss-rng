-- A view filling a layer the game gives us, the ribbon panel or the settings
-- page. The game clears the layer each time it opens or resizes it.

local layerView = {}

-- layout: the view's flow layout options.
function layerView.New(layout)
    local page = { layer = nil, view = nil }

    -- Destroying may fail if the game already cleared the layer.
    local function destroy()
        if page.view then
            pcall(function() page.view:Destroy() end)
        end
        page.view = nil
    end

    function page.Attach(layer)
        page.layer, page.view = layer, nil
    end

    function page.IsOpen()
        return page.layer ~= nil
    end

    -- A fresh, empty view to draw into.
    function page.Fresh()
        destroy()
        page.view = prettyui.SimpleView.new(page.layer, {
            width = 0, height = 0, widthAnchor = 1.0, heightAnchor = 1.0, layout = layout,
        })
        return page.view
    end

    function page.Detach()
        destroy()
        page.layer = nil
    end

    return page
end

return layerView

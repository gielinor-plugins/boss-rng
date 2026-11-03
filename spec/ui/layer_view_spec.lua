local layerView = require("src/ui/layer_view")

-- A layer the game gives, listing its children like the real one.
local function newLayer()
    local layer = { children = {} }
    function layer:IterateDynamicComponents(fn)
        for _, child in ipairs(self.children) do
            if fn(child, true) then
                return
            end
        end
    end
    return layer
end

describe("layer view", function()
    local savedUi

    before_each(function()
        savedUi = rawget(_G, "ui")
        _G.ui = {
            Rectangle = {
                new = function(parent)
                    local marker = { visibleGlobal = true }
                    function marker.SetSize() end
                    table.insert(parent.children, marker)
                    return marker
                end,
            },
        }
    end)

    after_each(function()
        _G.ui = savedUi
    end)

    it("is open only while its marker is still one of the layer's children", function()
        local page = layerView.New({})
        assert.is_false(page.IsOpen())
        local layer = newLayer()
        page.Attach(layer)
        assert.is_true(page.IsOpen())
        layer.children = { {}, {} } -- cleared and given to another plugin
        assert.is_false(page.IsOpen())
        page.Attach(layer) -- given back
        assert.is_true(page.IsOpen())
        page.Detach()
        assert.is_false(page.IsOpen())
    end)

    it("falls back to the marker's visibility if the layer can't list its children", function()
        local page = layerView.New({})
        local layer = { children = {} } -- no IterateDynamicComponents
        page.Attach(layer)
        assert.is_true(page.IsOpen())
        layer.children[1].visibleGlobal = false
        assert.is_false(page.IsOpen())
    end)
end)

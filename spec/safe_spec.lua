-- Run from the project root with: busted

describe("safe.Call", function()
    local safe, printed, realPrint

    before_each(function()
        package.loaded["src/safe"] = nil
        safe = require("src/safe")
        printed = {}
        -- busted runs each spec file with its own globals, so the real print
        -- that src/safe.lua calls has to be replaced through _G.
        realPrint = _G.print
        _G.print = function(text) table.insert(printed, text) end
    end)

    after_each(function()
        _G.print = realPrint
    end)

    it("runs code and reports success", function()
        local result
        assert.is_true(safe.Call("adding", function(a, b) result = a + b end, 1, 2))
        assert.are.equal(3, result)
        assert.are.same({}, printed)
    end)

    it("catches an error and prints it once", function()
        local function broken() error("boom", 0) end
        assert.are.equal(false, safe.Call("drawing", broken))
        assert.are.equal(false, safe.Call("drawing", broken))
        assert.are.same({ "[Boss RNG] Error drawing: boom" }, printed)
    end)
end)

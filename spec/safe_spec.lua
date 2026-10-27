-- Run from the project root with: busted

describe("safe.Call", function()
    local safe, printed, realPrint

    before_each(function()
        package.loaded["src/safe"] = nil
        safe = require("src/safe")
        printed = {}
        realPrint = print
        print = function(text) table.insert(printed, text) end
    end)

    after_each(function()
        print = realPrint
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

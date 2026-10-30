-- Run from the project root with: busted

local rates = require("src/rates")

describe("rates.History", function()
    local history = rates.History({
        { a = 1, b = 2 },
        { since = 100, b = 3 },
        { since = false, a = 9 }, -- an update not live yet
        { since = 200, a = 4 },
    })

    it("writes each version's changes over the one before", function()
        assert.are.same({ a = 1, b = 2 }, history:On(99))
        assert.are.same({ a = 1, b = 3 }, history:On(100))
        assert.are.same({ a = 4, b = 3 }, history:On(250))
    end)

    it("leaves out versions whose update isn't live yet", function()
        assert.are.equal(3, #history.versions)
    end)

    it("gives the newest version for a day not known", function()
        assert.are.equal(4, history:On(0).a)
        assert.are.equal(4, history:On(nil).a)
    end)

    it("gives the same values for every day of a version", function()
        assert.are.equal(history:On(100), history:On(150))
    end)
end)

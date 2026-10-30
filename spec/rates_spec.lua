-- Run from the project root with: busted

local bosses = require("src/bosses")
local rates = require("src/rates")

describe("rates.History", function()
    local history = rates.History({
        { values = { a = 1, b = 2 } },
        { since = 100, values = { b = 3 } },
        { since = false, values = { a = 9 } }, -- an update not live yet
        { since = 200, values = { a = 4 } },
    })

    it("looks up values a version doesn't change in the one before", function()
        assert.are.equal(1, history:On(99).a)
        assert.are.equal(3, history:On(100).b)
        assert.are.equal(1, history:On(100).a)
        assert.are.equal(4, history:On(250).a)
        assert.are.equal(3, history:On(250).b)
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

    it("errors on a rate name no version has", function()
        assert.has_error(function() return history:On(250).c end)
    end)
end)

describe("the rate files", function()
    local base = require("src/rates/base")

    it("give every boss its base rates", function()
        for _, boss in ipairs(bosses) do
            assert.is_true(base.rates[boss.key] ~= nil)
        end
    end)

    it("only change rates a boss already has, for bosses that exist", function()
        local keys = {}
        for _, boss in ipairs(bosses) do
            keys[boss.key] = true
        end
        for i = 2, #rates.UPDATES do
            local update = require("src/rates/" .. rates.UPDATES[i])
            assert.is_true(update.day == false or type(update.day) == "number")
            for key, values in pairs(update.rates) do
                assert.is_true(keys[key] == true)
                for name in pairs(values) do
                    assert.is_true(base.rates[key][name] ~= nil)
                end
            end
        end
    end)
end)

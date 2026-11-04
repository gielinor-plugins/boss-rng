local bosses = require("src/bosses")
local rates = require("src/core/rates")

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

    it("never applies a version whose update isn't live yet", function()
        assert.are.equal(1, history:On(150).a) -- not 9, the not-yet-live value
        assert.are.equal(4, history:On(200).a)
    end)

    it("gives the newest version for a day not known", function()
        assert.are.equal(4, history:On(0).a)
        assert.are.equal(4, history:On(nil).a)
    end)

    it("gives the same values for every day of a version", function()
        assert.are.equal(history:On(100), history:On(150))
    end)

    it("errors on a rate name no version has", function()
        assert.has_error(function()
            return history:On(250).c
        end)
    end)
end)

describe("the rate files", function()
    local base = require("src/core/rates/base")

    it("give every boss its base rates", function()
        for _, boss in ipairs(bosses) do
            assert(base.rates[boss.key] ~= nil, "no base rates for " .. boss.key)
        end
    end)

    it("only change rates a boss already has, for bosses that exist", function()
        local keys = {}
        for _, boss in ipairs(bosses) do
            keys[boss.key] = true
        end
        for i = 2, #rates.UPDATES do
            local name = rates.UPDATES[i]
            local update = require("src/core/rates/" .. name)
            assert(update.day == false or type(update.day) == "number", name .. ": day")
            for key, values in pairs(update.rates) do
                assert(keys[key] == true, name .. ": no boss " .. key)
                for rate in pairs(values) do
                    assert(base.rates[key][rate] ~= nil, name .. ": " .. key .. " has no " .. rate)
                end
            end
        end
    end)
end)

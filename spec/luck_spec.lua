-- Run from the project root with: busted

local luck = require("src/luck")

-- Rasial: a weapon roll (1/320, 2 items) and an armor roll (1/128, 5 items).
local RASIAL = {
    { chance = 1 / 320, items = { w1 = 1, w2 = 1 } },
    { chance = 1 / 128, items = { a1 = 1, a2 = 1, a3 = 1, a4 = 1, a5 = 1 } },
}

describe("luck.ItemChances", function()
    it("splits each roll evenly between equal weights", function()
        local chances = luck.ItemChances(RASIAL)
        for _, itemID in ipairs({ "w1", "w2", "a1", "a2", "a3", "a4", "a5" }) do
            assert.are.near(1 / 640, chances[itemID], 1e-12)
        end
    end)

    it("splits a roll by weight", function()
        -- Raksha: one roll at 1/50. Boots 1/130, the others 1/325 each.
        local chances = luck.ItemChances({
            { chance = 1 / 50, items = { boots = 5, spike = 2, c1 = 2, c2 = 2, c3 = 2 } },
        })
        assert.are.near(1 / 130, chances.boots, 1e-12)
        assert.are.near(1 / 325, chances.spike, 1e-12)
    end)

    it("adds up an item that is in more than one roll", function()
        local chances = luck.ItemChances({
            { chance = 0.1, items = { x = 1 } },
            { chance = 0.2, items = { x = 1, y = 1 } },
        })
        assert.are.near(0.2, chances.x, 1e-12)
    end)
end)

describe("luck.ChanceOfAny", function()
    it("combines independent rolls", function()
        -- 1 - (319/320)(127/128), about 1 in 91.6
        assert.are.near(1 - (319 / 320) * (127 / 128), luck.ChanceOfAny(RASIAL), 1e-12)
    end)

    it("only counts tracked items", function()
        local weaponsOnly = { w1 = true, w2 = true }
        assert.are.near(1 / 320, luck.ChanceOfAny(RASIAL, weaponsOnly), 1e-12)
    end)
end)

describe("luck.Percentile", function()
    it("matches the worked examples", function()
        assert.are.near(0.1839, luck.Percentile(1, 0), 1e-4)
        assert.are.near(0.5518, luck.Percentile(1, 1), 1e-4)
        assert.are.near(0.5312, luck.Percentile(4, 4), 1e-4)
        assert.are.near(0.7849, luck.Percentile(576 / 500, 2), 1e-4)
    end)

    it("has no data without kills", function()
        assert.is_nil(luck.Percentile(0, 0))
    end)

    it("rises with each extra drop", function()
        local previous = luck.Percentile(10, 0)
        for received = 1, 30 do
            local current = luck.Percentile(10, received)
            assert.is_true(current > previous)
            previous = current
        end
    end)

    it("stays near 50% for an average result with large numbers", function()
        assert.are.near(0.5, luck.Percentile(500, 500), 0.02)
    end)
end)

describe("luck.DryPercentile", function()
    it("matches Rasial at 250 kills dry", function()
        assert.are.near(0.9356, luck.DryPercentile(luck.ChanceOfAny(RASIAL), 250), 1e-4)
    end)

    it("is 0 with no kills", function()
        assert.are.equal(0, luck.DryPercentile(0.01, 0))
    end)
end)

-- Run from the project root with: busted

local format = require("src/format")

describe("format", function()
    it("adds thousands separators", function()
        assert.are.equal("7", format.Number(7))
        assert.are.equal("1,234", format.Number(1234))
        assert.are.equal("1,234,567", format.Number(1234567))
    end)

    it("rounds percentages down and never shows 0%", function()
        assert.are.equal("48%", format.Percent(0.4899))
        assert.are.equal("99%", format.Percent(0.9999))
        assert.are.equal("under 1%", format.Percent(0.00002))
    end)

    it("words luck", function()
        assert.are.equal("luckier than 48%", format.Luck({ luck = 0.48 }))
        assert.are.equal("no kills yet", format.Luck({}))
    end)

    it("words the dry streak", function()
        assert.are.equal("12 kills dry · 4% go this long",
            format.Dry({ kills = 100, dryKills = 12, dryShare = 0.96 }))
        assert.are.equal("1 kill dry · 99% go this long",
            format.Dry({ kills = 1, dryKills = 1, dryShare = 0.003 }))
        assert.are.equal("unique on your last kill", format.Dry({ kills = 5, dryKills = 0, dryShare = 0 }))
    end)

    it("words the totals", function()
        assert.are.equal("1,204 kills · 1 unique since install", format.Totals({ kills = 1204, received = 1 }))
    end)
end)

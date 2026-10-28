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

    it("words luck as a top or bottom group, or about average", function()
        assert.are.equal("top 3% luck", format.Luck({ luck = 0.97 }))
        assert.are.equal("top 1% luck", format.Luck({ luck = 0.99996 }))
        assert.are.equal("about average luck", format.Luck({ luck = 0.48 }))
        assert.are.equal("about average luck", format.Luck({ luck = 0.6 }))
        assert.are.equal("bottom 12% luck", format.Luck({ luck = 0.12 }))
        assert.are.equal("bottom 13% luck", format.Luck({ luck = 0.1201 }))
        assert.are.equal("bottom 1% luck", format.Luck({ luck = 0.00002 }))
        assert.are.equal("no kills yet", format.Luck({}))
    end)

    it("words luck in a few words for columns", function()
        assert.are.equal("top 3%", format.LuckShort({ luck = 0.97 }))
        assert.are.equal("average", format.LuckShort({ luck = 0.48 }))
        assert.are.equal("bottom 12%", format.LuckShort({ luck = 0.12 }))
        assert.are.equal("no kills", format.LuckShort({}))
    end)

    it("words the dry streak", function()
        assert.are.equal("12 kills dry · 4% go this long",
            format.Dry({ kills = 100, dryKills = 12, dryShare = 0.96 }))
        assert.are.equal("1 kill dry · 99% go this long",
            format.Dry({ kills = 1, dryKills = 1, dryShare = 0.003 }))
        assert.are.equal("unique on your last kill", format.Dry({ kills = 5, dryKills = 0, dryShare = 0 }))
    end)

    it("marks a dry streak that may be longer", function()
        assert.are.equal("1+ kills dry · 99% go this long",
            format.Dry({ kills = 1, dryKills = 1, dryAtLeast = true, dryShare = 0.003 }))
        assert.are.equal("1,204+", format.DryCount({ dryKills = 1204, dryAtLeast = true }))
        assert.are.equal("7", format.DryCount({ dryKills = 7 }))
        assert.are.equal("?", format.DryCount({ dryKills = 0, dryAtLeast = true }))
        assert.are.equal("0", format.DryCount({ dryKills = 0 }))
        assert.are.equal("Dry streak: counted from your next kill",
            format.Dry({ kills = 300, dryKills = 0, dryAtLeast = true, dryShare = 0 }))
    end)

    it("capitalizes a headline", function()
        assert.are.equal("Bottom 12% luck", format.Capitalize("bottom 12% luck"))
    end)

    it("words what an average player would have", function()
        assert.are.equal("Average player: 2.3 uniques", format.Average({ expected = 2.345 }))
        assert.are.equal("Average player: 1.0 unique", format.Average({ expected = 1.04 }))
        assert.are.equal("Average player: under 1 unique", format.Average({ expected = 0.98 }))
    end)

    it("words the totals", function()
        assert.are.equal("Tracked: 1,204 kills · 1 unique", format.Totals({ kills = 1204, received = 1 }))
        assert.are.equal("All-time: 576 kills · 7 uniques", format.Totals({ allTime = true, kills = 576, received = 7 }))
    end)
end)

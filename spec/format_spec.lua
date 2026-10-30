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
        assert.are.equal("no tracked kills yet", format.Luck({ kills = 0 }))
        assert.are.equal("luck rating in about 14 kills", format.Luck({ kills = 20, killsToLuck = 14 }))
        assert.are.equal("luck rating in about 1 kill", format.Luck({ kills = 20, killsToLuck = 1 }))
        -- A boss counting chests says so.
        assert.are.equal("luck rating in about 3 chests", format.Luck({ kills = 2, killsToLuck = 3, unit = "chest" }))
        assert.are.equal("no tracked chests yet", format.Luck({ kills = 0, unit = "chest" }))
        assert.are.equal("Tracked: 2 chests · 0 uniques", format.Tracked({ kills = 2, received = 0, unit = "chest" }))
    end)

    it("words luck in a few words for columns", function()
        assert.are.equal("top 3%", format.LuckShort({ luck = 0.97 }))
        assert.are.equal("average", format.LuckShort({ luck = 0.48 }))
        assert.are.equal("bottom 12%", format.LuckShort({ luck = 0.12 }))
        assert.are.equal("no kills", format.LuckShort({ kills = 0 }))
        assert.are.equal("too early", format.LuckShort({ expected = 0.4 })) -- an item, before luck shows
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
        assert.are.equal("0", format.DryCount({ dryKills = 0 }))
        assert.are.equal("?", format.DryCount({ dryKills = 0, dryAtLeast = true }))
    end)

    it("capitalizes a headline", function()
        assert.are.equal("Bottom 12% luck", format.Capitalize("bottom 12% luck"))
    end)

    it("words what an average player would have", function()
        assert.are.equal("Average player: 2.3 uniques", format.Average({ kills = 5, expected = 2.345 }))
        assert.are.equal("Average player: 1.0 unique", format.Average({ kills = 5, expected = 1.04 }))
        assert.are.equal("Average player: under 1 unique", format.Average({ kills = 5, expected = 0.98 }))
        assert.are.equal("", format.Average({ kills = 0, expected = 0 }))
        assert.are.equal("avg 19.4", format.AverageShort({ expected = 19.38 }))
        assert.are.equal("avg 0.5", format.AverageShort({ expected = 0.53 }))
        assert.are.equal("avg under 0.1", format.AverageShort({ expected = 0.04 }))
        assert.are.equal("avg 0", format.AverageShort({ expected = 0 }))
        assert.are.equal("12 · avg 19.4", format.CountShort({ received = 12, expected = 19.38 }))
    end)

    it("words the tracked totals, with the day tracking started", function()
        assert.are.equal("Tracked: 212 kills · 1 unique", format.Tracked({ since = 20755, kills = 212, received = 1 }))
        assert.are.equal("Tracked: 9 kills (+4 partial) · 0 uniques",
            format.Tracked({ kills = 9, extraKills = 4, extraLabel = "partial", received = 0 }))
        assert.are.equal("Tracked: 3 kills · 0 uniques", format.Tracked({ kills = 3, received = 0 }))
        assert.are.equal("", format.Tracked({ kills = 0, received = 0 }))
        assert.are.equal("212 tracked kills · 1 unique", format.TrackedShort({ kills = 212, received = 1 }))
        assert.are.equal("", format.TrackedShort({ kills = 0, received = 0 }))
    end)

    it("words the game's all-time totals, once read", function()
        assert.are.equal("Boss log: 408 kills · 3 uniques · 184 spikes", format.AllTime({
            allTime = { kills = 408, received = 3, stacks = { { word = "spike", count = 184 } } } }))
        assert.are.equal("Boss log: 924 kills · 9 uniques",
            format.AllTime({ allTime = { kills = 924, received = 9 } }))
        assert.are.equal("", format.AllTime({}))
    end)

    it("words a day as a date", function()
        assert.are.equal("1 Jan 1970", format.Date(0))
        assert.are.equal("29 Feb 2024", format.Date(19782))
    end)
end)

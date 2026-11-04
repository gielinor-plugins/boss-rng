local format = require("src/ui/format")

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
        -- Whole percents that floats store a hair low.
        assert.are.equal("29%", format.Percent(0.29))
        assert.are.equal("57%", format.Percent(0.57))
    end)

    it("words luck as a top or bottom group, or about average", function()
        assert.are.equal("Spooned: top 3% luck", format.Luck({ kills = 10, luck = 0.97 }))
        assert.are.equal("Spooned: top 1% luck", format.Luck({ kills = 10, luck = 0.99996 }))
        assert.are.equal("About average luck", format.Luck({ kills = 10, luck = 0.48 }))
        assert.are.equal("About average luck", format.Luck({ kills = 10, luck = 0.6 }))
        assert.are.equal("Bottom 12% luck", format.Luck({ kills = 10, luck = 0.12 }))
        assert.are.equal("Bottom 13% luck", format.Luck({ kills = 10, luck = 0.1201 }))
        assert.are.equal("Cursed: bottom 1% luck", format.Luck({ kills = 10, luck = 0.00002 }))
        -- The top and bottom 10% are named, as shown: 90% luck is the top 10%.
        assert.are.equal("Spooned: top 10% luck", format.Luck({ kills = 10, luck = 0.9 }))
        assert.are.equal("Top 11% luck", format.Luck({ kills = 10, luck = 0.89 }))
        assert.are.equal("Cursed: bottom 10% luck", format.Luck({ kills = 10, luck = 0.1 }))
        assert.are.equal("Bottom 11% luck", format.Luck({ kills = 10, luck = 0.1001 }))
        assert.are.equal("No tracked kills yet", format.Luck({ kills = 0 }))
        assert.are.equal(
            "Luck: next unique or 14 kills",
            format.Luck({ kills = 20, killsToLuck = 14 })
        )
        assert.are.equal(
            "Luck: next unique or 1 kill",
            format.Luck({ kills = 20, killsToLuck = 1 })
        )
        -- A boss counting chests says so.
        assert.are.equal(
            "Luck: next unique or 3 chests",
            format.Luck({ kills = 2, killsToLuck = 3, unit = "chest" })
        )
        assert.are.equal("No tracked chests yet", format.Luck({ kills = 0, unit = "chest" }))
        assert.are.equal(
            "Tracked: 2 chests · 0 uniques",
            format.Tracked({ kills = 2, received = 0, unit = "chest" })
        )
    end)

    it("words luck in a few words for columns", function()
        assert.are.equal("top 3%", format.LuckShort({ luck = 0.97 }))
        assert.are.equal("average", format.LuckShort({ luck = 0.48 }))
        assert.are.equal("bottom 12%", format.LuckShort({ luck = 0.12 }))
        assert.are.equal("no kills", format.LuckShort({ kills = 0 }))
        -- Before luck shows: the share still dry, or no chance yet when no kill could drop it.
        assert.are.equal("91% are still dry", format.LuckShort({ expected = 0.1, dryShare = 0.09 }))
        assert.are.equal("no chance yet", format.LuckShort({ expected = 0, dryShare = 0 }))
    end)

    it("words the dry streak", function()
        assert.are.equal(
            "12 kills dry · 4% go this long",
            format.Dry({ kills = 100, dryKills = 12, dryShare = 0.96 })
        )
        assert.are.equal(
            "1 kill dry · 99% go this long",
            format.Dry({ kills = 1, dryKills = 1, dryShare = 0.003 })
        )
        assert.are.equal(
            "Unique on your last kill",
            format.Dry({ kills = 5, dryKills = 0, dryShare = 0 })
        )
    end)

    it("marks a dry streak that may be longer", function()
        assert.are.equal(
            "1+ kills dry · 99% go this long",
            format.Dry({ kills = 1, dryKills = 1, dryAtLeast = true, dryShare = 0.003 })
        )
        assert.are.equal("1,204+", format.DryCount({ dryKills = 1204, dryAtLeast = true }))
        assert.are.equal("7", format.DryCount({ dryKills = 7 }))
        assert.are.equal("0", format.DryCount({ dryKills = 0 }))
        assert.are.equal("", format.DryCount({ dryKills = 0, dryAtLeast = true }))
    end)

    it("capitalizes a headline", function() end)

    it("words what an average player would have", function()
        assert.are.equal(
            "Average player: 2.3 uniques",
            format.Average({ kills = 5, expected = 2.345 })
        )
        assert.are.equal(
            "Average player: 1.0 unique",
            format.Average({ kills = 5, expected = 1.04 })
        )
        assert.are.equal(
            "Average player: under 1 unique",
            format.Average({ kills = 5, expected = 0.98 })
        )
        -- Exactly 1, short by float error.
        assert.are.equal(
            "Average player: 1.0 unique",
            format.Average({ kills = 5, expected = 0.9999999999999999 })
        )
        assert.are.equal("", format.Average({ kills = 0, expected = 0 }))
        assert.are.equal("19.4 drops", format.AverageShort({ expected = 19.38 }))
        assert.are.equal("0.5 drops", format.AverageShort({ expected = 0.53 }))
        assert.are.equal("<lt>0.1 drops", format.AverageShort({ expected = 0.04 }))
        assert.are.equal("0 drops", format.AverageShort({ expected = 0 }))
        assert.are.equal("1.0 drop", format.AverageShort({ expected = 1.02 }))
        -- The same value, added up in a different order, stored a hair either side.
        assert.are.equal("0.4 drops", format.AverageShort({ expected = 0.35 }))
        assert.are.equal("0.4 drops", format.AverageShort({ expected = 0.05 * 7 }))
        assert.are.equal("0.1 drops", format.AverageShort({ expected = 0.3 - 0.25 }))
    end)

    it("words the tracked totals, with partial kills and loot piles", function()
        assert.are.equal(
            "212 kills · 1 unique",
            format.TrackedCounts({ kills = 212, received = 1 })
        )
        -- Barrows: partial chests after the chests in the kill count.
        assert.are.equal(
            "12 chests (+2 partial) · 0 uniques",
            format.TrackedCounts({
                kills = 12,
                extraKills = 2,
                extraLabel = "partial",
                received = 0,
                unit = "chest",
            })
        )
        -- Kerapac's loot piles.
        assert.are.equal(
            "40 kills (97 piles) · 2 uniques",
            format.TrackedCounts({ kills = 40, piles = 97, received = 2 })
        )
        assert.are.equal("", format.TrackedCounts({ kills = 0, received = 0 }))
    end)

    it("labels the tracked totals for the details window", function()
        assert.are.equal(
            "Tracked: 3 kills · 0 uniques",
            format.Tracked({ kills = 3, received = 0 })
        )
        assert.are.equal("", format.Tracked({ kills = 0, received = 0 }))
    end)

    it("words the game's all-time totals, once read", function()
        assert.are.equal(
            "All-time: 408 kills · 184 spikes · 3 other uniques",
            format.AllTime({
                allTime = {
                    kills = 408,
                    received = 3,
                    stacks = { { word = "spike", count = 184 } },
                },
            })
        )
        assert.are.equal(
            "All-time: 233 kills · 7 dark nilas · 5 other uniques",
            format.AllTime({
                allTime = {
                    kills = 233,
                    received = 5,
                    stacks = { { word = "dark nilas", plural = "dark nilas", count = 7 } },
                },
            })
        )
        assert.are.equal(
            "All-time: 924 kills · 9 uniques",
            format.AllTime({ allTime = { kills = 924, received = 9 } })
        )
        assert.are.equal("", format.AllTime({}))
    end)
end)

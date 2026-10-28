-- Run from the project root with: busted

local luck = require("src/luck")
local stats = require("src/stats")

-- A test boss: normal mode rolls item 1 at 1/100 and item 2 at 1/50; hard mode
-- rolls item 1 at 1/20.
local BOSS = {
    modes = {
        { name = "Normal", rolls = { { chance = 3 / 100, items = { [1] = 1, [2] = 2 } } } },
        { name = "Hard mode", rolls = { { chance = 1 / 20, items = { [1] = 1 } } } },
    },
}

-- Tallies with these kills, dry kills and items (dry defaults to all kills).
local function tallies(kills, items, dry)
    return { kills = kills, dry = dry or kills, items = items or {} }
end

describe("stats.ForBoss", function()
    it("has nothing without tallies", function()
        assert.is_nil(stats.ForBoss(BOSS, nil))
    end)

    it("adds up expected drops per mode", function()
        local result = stats.ForBoss(BOSS, tallies({ Normal = 100, ["Hard mode"] = 20 }))
        assert.are.equal(120, result.kills)
        assert.are.near(1 + 1, result.items[1].expected, 1e-9) -- 100/100 + 20/20
        assert.are.near(2, result.items[2].expected, 1e-9) -- 100/50
        assert.are.near(4, result.expected, 1e-9)
    end)

    it("compares received drops with expected", function()
        local result = stats.ForBoss(BOSS, tallies({ Normal = 100 }, {
            ["1"] = { count = 1, atKill = 40 },
            ["2"] = { count = 2, atKill = 90 },
        }, { Normal = 10 }))
        assert.are.equal(3, result.received)
        assert.are.near(luck.Percentile(3, 3), result.luck, 1e-12)
        assert.are.near(luck.Percentile(1, 1), result.items[1].luck, 1e-12)
    end)

    it("counts the dry streak from the latest unique", function()
        local result = stats.ForBoss(BOSS, tallies({ Normal = 100 }, {
            ["1"] = { count = 1, atKill = 40 },
            ["2"] = { count = 2, atKill = 90 },
        }, { Normal = 10 }))
        assert.are.equal(10, result.dryKills)
        assert.are.equal(60, result.items[1].dryKills)
        assert.are.near(luck.DryPercentile(3 / 100, 10), result.dryShare, 1e-12)
    end)

    it("counts every kill as dry before the first unique", function()
        local result = stats.ForBoss(BOSS, tallies({ Normal = 30 }))
        assert.are.equal(30, result.dryKills)
        assert.are.equal(0, result.received)
    end)

    it("uses each mode's own rates for the dry streak", function()
        local result = stats.ForBoss(BOSS, tallies({ Normal = 50, ["Hard mode"] = 50 }))
        local missAll = (1 - 3 / 100) ^ 50 * (1 - 1 / 20) ^ 50
        assert.are.near(1 - missAll, result.dryShare, 1e-12)
    end)

    it("has no luck without kills", function()
        local result = stats.ForBoss(BOSS, tallies({}))
        assert.is_nil(result.luck)
        assert.are.equal(0, result.dryShare)
    end)

    describe("with all-time totals", function()
        local function withAllTime(t, kills, items)
            t.allTime = { kills = kills, items = items }
            return t
        end

        it("uses them for luck", function()
            local result = stats.ForBoss(BOSS, withAllTime(tallies({ Normal = 10 }),
                { Normal = 100, ["Hard mode"] = 20 }, { ["1"] = 2, ["2"] = 1 }))
            assert.is_true(result.allTime)
            assert.are.equal(120, result.kills)
            assert.are.near(4, result.expected, 1e-9)
            assert.are.equal(3, result.received)
            assert.are.equal(2, result.items[1].received)
        end)

        it("keeps dry streaks from tracking, marking ones that may be longer", function()
            local result = stats.ForBoss(BOSS, withAllTime(tallies({ Normal = 10 }, {
                ["1"] = { count = 1, atKill = 4 },
            }, { Normal = 6 }), { Normal = 100 }, { ["1"] = 3, ["2"] = 1 }))
            assert.are.equal(6, result.dryKills)
            assert.is_false(result.dryAtLeast)
            assert.are.equal(6, result.items[1].dryKills)
            assert.is_false(result.items[1].dryAtLeast)
            assert.are.equal(10, result.items[2].dryKills)
            assert.is_true(result.items[2].dryAtLeast)
        end)

        it("counts every kill as dry for uniques never received", function()
            local result = stats.ForBoss(BOSS, withAllTime(tallies({ Normal = 10 }),
                { Normal = 100, ["Hard mode"] = 20 }, { ["1"] = 2 }))
            assert.are.equal(120, result.items[2].dryKills)
            assert.is_false(result.items[2].dryAtLeast)
            assert.are.equal(10, result.items[1].dryKills) -- received, so from tracking
            assert.is_true(result.items[1].dryAtLeast)
        end)

        it("counts every kill as dry for the boss with no uniques at all", function()
            local result = stats.ForBoss(BOSS, withAllTime(tallies({ Normal = 10 }),
                { Normal = 100, ["Hard mode"] = 20 }, {}))
            assert.are.equal(120, result.dryKills)
            assert.is_false(result.dryAtLeast)
            local missAll = (1 - 3 / 100) ^ 100 * (1 - 1 / 20) ^ 20
            assert.are.near(1 - missAll, result.dryShare, 1e-12)
        end)

        it("knows the streak is exact when every kill was tracked", function()
            local result = stats.ForBoss(BOSS, withAllTime(tallies({ Normal = 10 }), { Normal = 10 }, {}))
            assert.is_false(result.dryAtLeast)
            assert.is_false(result.items[1].dryAtLeast)
        end)
    end)

    it("marks dry streaks as possibly longer without all-time totals", function()
        assert.is_true(stats.ForBoss(BOSS, tallies({ Normal = 30 })).dryAtLeast)
    end)
end)

describe("stats.Overall", function()
    it("adds up bosses and applies the same percentile", function()
        local overall = stats.Overall({
            { kills = 10, expected = 1.5, received = 1 },
            { kills = 30, expected = 2.5, received = 5 },
        })
        assert.are.equal(40, overall.kills)
        assert.are.equal(4, overall.expected)
        assert.are.equal(6, overall.received)
        assert.are.near(luck.Percentile(4, 6), overall.luck, 1e-12)
    end)
end)

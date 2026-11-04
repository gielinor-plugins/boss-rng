local luck = require("src/core/luck")
local rates = require("src/core/rates")
local stats = require("src/core/stats")

local DAY = 20756 -- 30 Oct 2026

-- Normal mode rolls item 1 at 1/100 and item 2 at 1/50; hard mode item 1 at 1/20.
-- Test bosses are written as loaded, with each mode's key set (see src/bosses.lua).
local BOSS = {
    modes = {
        n = { key = "n", rolls = { { chance = 3 / 100, items = { [1] = 1, [2] = 2 } } } },
        h = { key = "h", rolls = { { chance = 1 / 20, items = { [1] = 1 } } } },
    },
    items = { [1] = {}, [2] = {} },
}

-- { [mode name] = kills } as kills on one day.
local function onDay(kills, day)
    local byMode = {}
    for name, n in pairs(kills) do
        byMode[name] = { [tostring(day or DAY)] = n }
    end
    return byMode
end

-- Tallies on DAY. Each dry streak ({ [key] = kills by mode }) defaults to all kills;
-- a shorter one starts after the rest of that day's kills.
local function tallies(kills, items, dry)
    local result = { kills = onDay(kills), items = items or {}, dryFrom = {} }
    for key, streak in pairs(dry or {}) do
        local before = {}
        for name, n in pairs(kills) do
            before[name] = n - (streak[name] or 0)
        end
        result.dryFrom[key] = { day = DAY, at = onDay(before) }
    end
    return result
end

local function totals(kills, items)
    return { kills = kills, items = items }
end

local function forBoss(boss, t, allTime, readings)
    return stats.ForBoss({ boss = boss, tallies = t, allTime = allTime, readings = readings })
end

describe("stats.ForBoss", function()
    it("has nothing without tallies", function()
        assert.is_nil(forBoss(BOSS, nil))
    end)

    it("adds up loot piles for modes that count them", function()
        local piled = {
            modes = {
                p1 = { key = "p1", piles = 1, rolls = {} },
                p3 = { key = "p3", piles = 3, rolls = {} },
            },
            items = {},
        }
        local result = forBoss(piled, tallies({ p1 = 2, p3 = 5 }))
        assert.are.equal(7, result.kills)
        assert.are.equal(17, result.piles)
        assert.is_nil(forBoss(BOSS, tallies({ n = 5 })).piles) -- a boss without piles
    end)

    it("adds up expected drops per mode over tracked kills", function()
        local result = forBoss(BOSS, tallies({ n = 100, h = 20 }))
        assert.are.equal(120, result.kills)
        assert.are.near(1 + 1, result.items[1].expected, 1e-9) -- 100/100 + 20/20
        assert.are.near(2, result.items[2].expected, 1e-9) -- 100/50
        assert.are.near(4, result.expected, 1e-9)
    end)

    it("compares tracked drops with expected", function()
        local result = forBoss(BOSS, tallies({ n = 100 }, { ["1"] = 1, ["2"] = 2 }))
        assert.are.equal(3, result.received)
        assert.are.near(luck.Percentile(3, 3), result.luck, 1e-12)
        assert.are.near(luck.Percentile(1, 1), result.items[1].luck, 1e-12)
    end)

    it("shows luck once an average player would have a unique", function()
        local result = forBoss(BOSS, tallies({ n = 20 })) -- 0.6 expected, none received
        assert.is_nil(result.luck)
        assert.are.equal(14, result.killsToLuck) -- 0.4 more at 0.03 a kill
        assert.is_nil(result.items[2].luck) -- 0.4 expected
        assert.are.near(luck.DryPercentile(1 / 50, 20), result.items[2].dryShare, 1e-12)
        assert.is_true(forBoss(BOSS, tallies({ n = 34 })).luck ~= nil) -- 1.02 expected
    end)

    it("shows luck from the first unique received, however early", function()
        local result = forBoss(BOSS, tallies({ n = 20 }, { ["2"] = 1 })) -- 0.6 expected
        assert.are.near(luck.Percentile(0.6, 1), result.luck, 1e-12)
        assert.are.near(luck.Percentile(0.4, 1), result.items[2].luck, 1e-12)
        assert.is_nil(result.items[1].luck) -- none of item 1 yet
    end)

    it("counts the dry streaks the tracker kept", function()
        local result = forBoss(
            BOSS,
            tallies(
                { n = 100 },
                { ["1"] = 1, ["2"] = 2 },
                { any = { n = 10 }, ["1"] = { n = 60 }, ["2"] = { n = 10 } }
            )
        )
        assert.are.equal(10, result.dryKills)
        assert.are.equal(60, result.items[1].dryKills)
        assert.are.near(luck.DryPercentile(3 / 100, 10), result.dryShare, 1e-12)
    end)

    it("counts an item's dry streak only over kills that can drop it", function()
        local result = forBoss(BOSS, tallies({ n = 50, h = 30 }))
        assert.are.equal(50, result.items[2].dryKills) -- hard mode can't drop item 2
        assert.are.equal(80, result.items[1].dryKills)
    end)

    it("uses each mode's own rates for the dry streak", function()
        local result = forBoss(BOSS, tallies({ n = 50, h = 50 }))
        local missAll = (1 - 3 / 100) ^ 50 * (1 - 1 / 20) ^ 50
        assert.are.near(1 - missAll, result.dryShare, 1e-12)
    end)

    it("has no luck and no dry share without kills", function()
        local result = forBoss(BOSS, tallies({}))
        assert.is_nil(result.luck)
        assert.is_nil(result.killsToLuck)
        assert.are.equal(0, result.dryShare)
    end)

    describe("with all-time totals", function()
        it("shows them as facts, without using them for luck", function()
            local result = forBoss(
                BOSS,
                tallies({ n = 40 }),
                totals({ KC_NORMAL = 100, KC_HARD = 20 }, { ["1"] = 2, ["2"] = 1 })
            )
            assert.are.same({ kills = 120, received = 3, stacks = {} }, result.allTime)
            assert.are.equal(40, result.kills)
            assert.are.equal(0, result.received)
            assert.are.near(1.2, result.expected, 1e-9)
            assert.are.equal(2, result.items[1].allTime)
        end)

        it(
            "marks dry streaks that may be longer: nothing tracked, and kills before tracking",
            function()
                local result = forBoss(
                    BOSS,
                    tallies({ n = 10 }, { ["1"] = 1 }),
                    totals({ KC_NORMAL = 100, KC_HARD = 0 }, { ["1"] = 3, ["2"] = 1 })
                )
                assert.is_false(result.dryAtLeast)
                assert.is_false(result.items[1].dryAtLeast)
                assert.is_true(result.items[2].dryAtLeast)
            end
        )

        it("shows a stacked unique's log count apart, since it counts items, not drops", function()
            local boss = {
                modes = BOSS.modes,
                items = {
                    [1] = { stack = { most = 9, word = "spike" } },
                    [2] = {},
                },
            }
            local result = forBoss(
                boss,
                tallies({ n = 10 }),
                totals({ KC_NORMAL = 10, KC_HARD = 0 }, { ["1"] = 184, ["2"] = 3 })
            )
            assert.are.same(
                { kills = 10, received = 3, stacks = { { word = "spike", count = 184 } } },
                result.allTime
            )
            assert.is_nil(result.items[1].allTime)
        end)

        it("knows a streak is exact when every kill was tracked", function()
            local result =
                forBoss(BOSS, tallies({ n = 10 }), totals({ KC_NORMAL = 10, KC_HARD = 0 }, {}))
            assert.is_false(result.dryAtLeast)
            assert.is_false(result.items[2].dryAtLeast)
        end)
    end)

    it("marks dry streaks as possibly longer without all-time totals", function()
        assert.is_true(forBoss(BOSS, tallies({ n = 30 })).dryAtLeast)
    end)

    it("uses rolls that depend on values read from the game", function()
        local boss = {
            items = { [1] = {} },
            modes = {
                n = {
                    key = "n",
                    rolls = function(_, readings)
                        return { { chance = 1 / readings.rate, items = { [1] = 1 } } }
                    end,
                },
            },
        }
        assert.are.near(2, forBoss(boss, tallies({ n = 100 }), nil, { rate = 50 }).expected, 1e-9)
    end)

    it("shows a group of uniques as one row", function()
        local group = { name = "Pieces" }
        local boss = {
            items = {
                [1] = { group = group },
                [2] = { group = group },
            },
            modes = {
                n = {
                    key = "n",
                    rolls = { { chance = 1 / 10, items = { [1] = 1, [2] = 1 } } },
                },
            },
        }
        local result = forBoss(
            boss,
            tallies(
                { n = 100 },
                { ["1"] = 2, ["2"] = 1 },
                { any = { n = 10 }, ["1"] = { n = 40 }, ["2"] = { n = 10 } }
            ),
            totals({ KC = 100 }, { ["1"] = 2, ["2"] = 1 })
        )
        assert.is_nil(result.items[2])
        local row = result.items[1]
        assert.are.equal(group, row.group)
        assert.are.near(10, row.expected, 1e-9)
        assert.are.equal(3, row.received)
        assert.are.equal(3, row.allTime)
        assert.are.equal(10, row.dryKills) -- since the latest of either
    end)
end)

describe("stats with sums", function()
    -- Item 1 at a chance of the day's average "level" in hundredths.
    local LEVELLED = {
        modes = {
            n = {
                key = "n",
                rolls = function(_, _, means)
                    return { { chance = means.level / 100, items = { [1] = 1 } } }
                end,
            },
        },
        items = { [1] = {} },
    }

    it("rates each day's kills at the averages of their sums", function()
        local t = {
            kills = { n = { [tostring(DAY)] = 2, [tostring(DAY + 1)] = 4 } },
            sums = { level = { n = { [tostring(DAY)] = 2, [tostring(DAY + 1)] = 20 } } },
            dryFrom = {},
            items = {},
        }
        assert.are.near(2 * 1 / 100 + 4 * 5 / 100, forBoss(LEVELLED, t).expected, 1e-12)
    end)
end)

describe("stats with rates that changed", function()
    local CHANGE = DAY + 10
    -- Item 1 at 1/10 before CHANGE, 1/5 from it.
    local CHANGED = {
        rates = rates.History({
            { values = { item = 1 / 10 } },
            { since = CHANGE, values = { item = 1 / 5 } },
        }),
        modes = {
            n = {
                key = "n",
                rolls = function(r)
                    return { { chance = r.item, items = { [1] = 1 } } }
                end,
            },
        },
        items = { [1] = {} },
    }

    -- Tallies with 20 kills before CHANGE and 10 from it, all dry.
    local function spanning()
        local byMode = { n = { [tostring(CHANGE - 1)] = 20, [tostring(CHANGE)] = 10 } }
        return { kills = byMode, dryFrom = {}, items = {} } -- dry from the first kill
    end

    it("uses the drop rates in effect on each kill's day", function()
        assert.are.near(20 / 10 + 10 / 5, forBoss(CHANGED, spanning()).expected, 1e-9)
    end)

    it("rates a dry streak spanning the change kill by kill", function()
        local missAll = (1 - 1 / 10) ^ 20 * (1 - 1 / 5) ^ 10
        assert.are.near(1 - missAll, forBoss(CHANGED, spanning()).dryShare, 1e-12)
    end)

    it("doesn't count kills from days an item wasn't on the table", function()
        local added = {
            rates = rates.History({
                { values = { new = 0 } },
                { since = CHANGE, values = { new = 1 / 5 } },
            }),
            modes = {
                n = {
                    key = "n",
                    rolls = function(r)
                        return { { chance = r.new, items = { [1] = 1 } } }
                    end,
                },
            },
            items = { [1] = {} },
        }
        local result = forBoss(added, spanning())
        assert.are.near(10 / 5, result.expected, 1e-9) -- only the 10 kills from CHANGE
        assert.are.equal(10, result.items[1].dryKills)
    end)

    it("rates kills of an unknown day (0) at today's rates", function()
        local byMode = { n = { ["0"] = 10 } }
        local result = forBoss(CHANGED, { kills = byMode, dryFrom = {}, items = {} })
        assert.are.near(10 / 5, result.expected, 1e-9)
    end)
end)

-- A boss whose kills are told apart at each kill: full chests in the kill count
-- (item 1 at 1/10), partial ones outside it (1/20).
local EVENTED = {
    modes = {
        Full = { key = "Full", rolls = { { chance = 1 / 10, items = { [1] = 1 } } } },
        Partial = {
            key = "Partial",
            partial = true,
            rolls = { { chance = 1 / 20, items = { [1] = 1 } } },
        },
    },
    extraKills = "partial",
    items = { [1] = {} },
}

describe("stats with kills counted at each kill", function()
    it("counts each kill for its own mode, apart from kills outside the kill count", function()
        local result = forBoss(EVENTED, tallies({ Full = 10, Partial = 4 }))
        assert.are.equal(10, result.kills)
        assert.are.equal(4, result.extraKills)
        assert.are.equal("partial", result.extraLabel)
        assert.are.near(10 / 10 + 4 / 20, result.expected, 1e-9)
    end)

    it("estimates kills until luck shows at the rate of kills in the kill count", function()
        assert.are.equal(5, forBoss(EVENTED, tallies({ Full = 5 })).killsToLuck) -- 0.5 more at 0.1
        -- 0.3 more
        assert.are.equal(3, forBoss(EVENTED, tallies({ Full = 5, Partial = 4 })).killsToLuck)
    end)

    it("leaves out kills of modes the boss no longer has", function()
        local boss = { modes = { Partial = EVENTED.modes.Partial }, items = EVENTED.items }
        assert.are.equal(0, forBoss(boss, tallies({ Full = 10 })).kills)
    end)
end)

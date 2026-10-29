-- Run from the project root with: busted

local luck = require("src/luck")
local stats = require("src/stats")

-- A test boss: normal mode rolls item 1 at 1/100 and item 2 at 1/50; hard mode
-- rolls item 1 at 1/20.
local BOSS = {
    modes = {
        { name = "Normal", kc = "KC_NORMAL", rolls = { { chance = 3 / 100, items = { [1] = 1, [2] = 2 } } } },
        { name = "Hard mode", kc = "KC_HARD", rolls = { { chance = 1 / 20, items = { [1] = 1 } } } },
    },
    items = { [1] = { kind = "unique" }, [2] = { kind = "unique" } },
}

-- Tallies with these kills, dry kills and items (dry defaults to all kills).
local function tallies(kills, items, dry)
    return { kills = kills, dry = dry or kills, items = items or {} }
end

-- All-time totals as the game gives them: kills per kill count var, log counts per item.
local function totals(kills, items)
    return { kills = kills, items = items }
end

-- Stats for boss from tallies, all-time totals (optional) and picks (optional).
local function forBoss(boss, t, allTime, picks)
    return stats.ForBoss({ boss = boss, tallies = t, allTime = allTime, picks = picks })
end

describe("stats.ForBoss", function()
    it("has nothing without tallies", function()
        assert.is_nil(forBoss(BOSS, nil))
    end)

    it("adds up expected drops per mode", function()
        local result = forBoss(BOSS, tallies({ Normal = 100, ["Hard mode"] = 20 }))
        assert.are.equal(120, result.kills)
        assert.are.near(1 + 1, result.items[1].expected, 1e-9) -- 100/100 + 20/20
        assert.are.near(2, result.items[2].expected, 1e-9) -- 100/50
        assert.are.near(4, result.expected, 1e-9)
    end)

    it("compares received drops with expected", function()
        local result = forBoss(BOSS, tallies({ Normal = 100 }, {
            ["1"] = { count = 1, atKills = { Normal = 40 } },
            ["2"] = { count = 2, atKills = { Normal = 90 } },
        }, { Normal = 10 }))
        assert.are.equal(3, result.received)
        assert.are.near(luck.Percentile(3, 3), result.luck, 1e-12)
        assert.are.near(luck.Percentile(1, 1), result.items[1].luck, 1e-12)
    end)

    it("counts the dry streak from the latest unique", function()
        local result = forBoss(BOSS, tallies({ Normal = 100 }, {
            ["1"] = { count = 1, atKills = { Normal = 40 } },
            ["2"] = { count = 2, atKills = { Normal = 90 } },
        }, { Normal = 10 }))
        assert.are.equal(10, result.dryKills)
        assert.are.equal(60, result.items[1].dryKills)
        assert.are.near(luck.DryPercentile(3 / 100, 10), result.dryShare, 1e-12)
    end)

    it("counts an item's dry streak only over kills that can drop it", function()
        local result = forBoss(BOSS, tallies({ Normal = 50, ["Hard mode"] = 30 }, {
            ["2"] = { count = 1, atKills = { Normal = 40, ["Hard mode"] = 5 } },
        }))
        assert.are.equal(10, result.items[2].dryKills) -- hard mode can't drop item 2
        assert.are.equal(80, result.items[1].dryKills)
    end)

    it("counts every kill as dry before the first unique", function()
        local result = forBoss(BOSS, tallies({ Normal = 30 }))
        assert.are.equal(30, result.dryKills)
        assert.are.equal(0, result.received)
    end)

    it("uses each mode's own rates for the dry streak", function()
        local result = forBoss(BOSS, tallies({ Normal = 50, ["Hard mode"] = 50 }))
        local missAll = (1 - 3 / 100) ^ 50 * (1 - 1 / 20) ^ 50
        assert.are.near(1 - missAll, result.dryShare, 1e-12)
    end)

    it("has no luck without kills", function()
        local result = forBoss(BOSS, tallies({}))
        assert.is_nil(result.luck)
        assert.are.equal(0, result.dryShare)
    end)

    describe("with all-time totals", function()
        it("uses them for luck", function()
            local result = forBoss(BOSS, tallies({ Normal = 10 }),
                totals({ KC_NORMAL = 100, KC_HARD = 20 }, { ["1"] = 2, ["2"] = 1 }))
            assert.is_true(result.allTime)
            assert.are.equal(120, result.kills)
            assert.are.near(4, result.expected, 1e-9)
            assert.are.equal(3, result.received)
            assert.are.equal(2, result.items[1].received)
        end)

        it("keeps dry streaks from tracking, marking ones that may be longer", function()
            local result = forBoss(BOSS, tallies({ Normal = 10 }, {
                ["1"] = { count = 1, atKills = { Normal = 4 } },
            }, { Normal = 6 }), totals({ KC_NORMAL = 100, KC_HARD = 0 }, { ["1"] = 3, ["2"] = 1 }))
            assert.are.equal(6, result.dryKills)
            assert.is_false(result.dryAtLeast)
            assert.are.equal(6, result.items[1].dryKills)
            assert.is_false(result.items[1].dryAtLeast)
            assert.are.equal(10, result.items[2].dryKills)
            assert.is_true(result.items[2].dryAtLeast)
        end)

        it("counts every kill that could drop it as dry for uniques never received", function()
            local result = forBoss(BOSS, tallies({ Normal = 10 }),
                totals({ KC_NORMAL = 100, KC_HARD = 20 }, { ["1"] = 2, ["2"] = 0 }))
            assert.are.equal(100, result.items[2].dryKills)
            assert.is_false(result.items[2].dryAtLeast)
            assert.are.equal(10, result.items[1].dryKills) -- received, so from tracking
            assert.is_true(result.items[1].dryAtLeast)
        end)

        it("counts every kill as dry for the boss with no uniques at all", function()
            local result = forBoss(BOSS, tallies({ Normal = 10 }),
                totals({ KC_NORMAL = 100, KC_HARD = 20 }, { ["1"] = 0, ["2"] = 0 }))
            assert.are.equal(120, result.dryKills)
            assert.is_false(result.dryAtLeast)
            local missAll = (1 - 3 / 100) ^ 100 * (1 - 1 / 20) ^ 20
            assert.are.near(1 - missAll, result.dryShare, 1e-12)
        end)

        it("knows the streak is exact when every kill was tracked", function()
            local result = forBoss(BOSS, tallies({ Normal = 10 }),
                totals({ KC_NORMAL = 10, KC_HARD = 0 }, { ["1"] = 1, ["2"] = 0 }))
            assert.is_false(result.dryAtLeast)
            assert.is_false(result.items[1].dryAtLeast)
        end)
    end)

    it("marks dry streaks as possibly longer without all-time totals", function()
        assert.is_true(forBoss(BOSS, tallies({ Normal = 30 })).dryAtLeast)
    end)

    it("uses rolls that depend on the player's picks", function()
        local boss = { items = { [1] = { kind = "unique" } }, modes = { { name = "Normal", kc = "KC",
            rolls = function(picks) return { { chance = 1 / picks.rate, items = { [1] = 1 } } } end } } }
        assert.are.near(2, forBoss(boss, tallies({ Normal = 100 }), nil, { rate = 50 }).expected, 1e-9)
    end)

    it("shows a group of uniques as one row", function()
        local group = { name = "Pieces" }
        local boss = {
            items = { [1] = { kind = "unique", group = group }, [2] = { kind = "unique", group = group } },
            modes = { { name = "Normal", kc = "KC", rolls = { { chance = 1 / 10, items = { [1] = 1, [2] = 1 } } } } },
        }
        local result = forBoss(boss, tallies({ Normal = 100 }, {
            ["1"] = { count = 2, atKills = { Normal = 60 } },
            ["2"] = { count = 1, atKills = { Normal = 90 } },
        }, { Normal = 10 }))
        assert.is_nil(result.items[2])
        local row = result.items[1]
        assert.are.equal(group, row.group)
        assert.are.near(10, row.expected, 1e-9)
        assert.are.equal(3, row.received)
        assert.are.equal(10, row.dryKills) -- since the latest of either
        assert.are.equal(3, result.received)
    end)

    describe("with modes that are tiers of a choice", function()
        -- Two tiers sharing one kill count: item 1 at 1/10 in tier 1, 1/5 in tier 2.
        local TIERED = {
            modes = {
                { name = "Low", kc = "KC", tier = { choice = "level", value = 1 },
                    rolls = { { chance = 1 / 10, items = { [1] = 1 } } } },
                { name = "High", kc = "KC", tier = { choice = "level", value = 2 },
                    rolls = { { chance = 1 / 5, items = { [1] = 1 } } } },
            },
            items = { [1] = { kind = "unique" } },
        }

        it("gives kills from before tracking to the picked tier", function()
            local t, allTime = tallies({ Low = 10, High = 5 }), totals({ KC = 100 }, { ["1"] = 0 })
            local low = forBoss(TIERED, t, allTime, { level = 1 })
            assert.are.near((10 + 85) / 10 + 5 / 5, low.expected, 1e-9)
            local high = forBoss(TIERED, t, allTime, { level = 2 })
            assert.are.near(10 / 10 + (5 + 85) / 5, high.expected, 1e-9)
            assert.are.equal(100, high.kills)
        end)
    end)
end)

describe("stats.Pools", function()
    -- Two bosses listing pooled item 9 (1/10 at A, 1/20 at B), and A's own item 1.
    local A = { key = "a", modes = { { name = "Normal", kc = "KC_A",
        rolls = { { chance = 1 / 10, items = { [9] = 1 } }, { chance = 1 / 50, items = { [1] = 1 } } } } } }
    local B = { key = "b", modes = { { name = "Normal", kc = "KC_B",
        rolls = { { chance = 1 / 20, items = { [9] = 1 } } } } } }
    local POOLED = { kind = "unique", pooledBy = { A, B } }
    A.items = { [1] = { kind = "unique" }, [9] = POOLED }
    B.items = { [9] = POOLED }

    -- Entries with stats, as src/ui.lua builds them, from each boss's
    -- { tallies, allTime }; returns the entries and pools.
    local function build(a, b, splits)
        local entries = {
            { boss = A, tallies = a.tallies, allTime = a.allTime, picks = {} },
            { boss = B, tallies = b.tallies, allTime = b.allTime, picks = {} },
        }
        local pools = stats.Pools(entries, splits or {})
        for _, entry in ipairs(entries) do
            entry.stats = stats.ForBoss(entry, pools)
        end
        return entries, pools
    end

    -- 100 kills at A (20 tracked, with 1 drop of item 9) and 40 at B (10
    -- tracked, none); 8 of item 9 in the shared log count.
    local function allTimeA()
        return { tallies = tallies({ Normal = 20 }, { ["9"] = { count = 1, atKills = { Normal = 15 } } }),
            allTime = totals({ KC_A = 100 }, { ["1"] = 0, ["9"] = 8 }) }
    end
    local function allTimeB()
        return { tallies = tallies({ Normal = 10 }), allTime = totals({ KC_B = 40 }, { ["9"] = 8 }) }
    end

    it("counts tracked drops at each boss until every boss's all-time totals can be read", function()
        local entries, pools = build(allTimeA(), { tallies = tallies({ Normal = 10 }) })
        assert.is_nil(pools[9].untracked)
        assert.are.near(20 / 10, entries[1].stats.items[9].expected, 1e-9) -- tracked kills only
        assert.are.equal(1, entries[1].stats.items[9].received)
        assert.are.equal(0, entries[2].stats.items[9].received)
    end)

    it("leaves a pooled unique out of every boss until untracked drops are split", function()
        local entries, pools = build(allTimeA(), allTimeB())
        assert.are.equal(7, pools[9].untracked)
        assert.is_true(pools[9].ask)
        assert.is_nil(entries[1].stats.items[9])
        assert.is_nil(entries[2].stats.items[9])
        assert.are.near(2, entries[1].stats.expected, 1e-9) -- item 1 only
        assert.are.equal(0, entries[2].stats.received)
    end)

    it("gives each boss its own count once the player splits untracked drops", function()
        local entries, pools = build(allTimeA(), allTimeB(), { ["9"] = { a = 5, b = 2 } })
        assert.are.same({ a = 6, b = 2 }, pools[9].received)
        assert.are.equal(6, entries[1].stats.items[9].received)
        assert.are.near(2 + 10, entries[1].stats.expected, 1e-9)
        assert.are.equal(2, entries[2].stats.received)
    end)

    it("keeps the player's split when a tracked drop lands, counting it for that boss only", function()
        local splits = { ["9"] = { a = 5, b = 2 } }
        -- Before: A has 1 tracked drop, and the log count is 8 (7 untracked).
        local _, before = build(allTimeA(), allTimeB(), splits)
        -- A tracked drop at A: its tracked count and the shared log count both go up.
        local a = allTimeA()
        a.tallies.items["9"] = { count = 2, atKills = { Normal = 20 } }
        a.allTime.items["9"] = 9
        local b = allTimeB()
        b.allTime.items["9"] = 9
        local entries, after = build(a, b, splits)
        assert.are.equal(before[9].untracked, after[9].untracked)
        assert.are.same(splits["9"], after[9].split)
        assert.are.same({ a = 7, b = 2 }, after[9].received)
        assert.are.equal(7, entries[1].stats.items[9].received)
        assert.are.equal(2, entries[2].stats.items[9].received)
    end)

    it("ignores a split that no longer adds up", function()
        local _, pools = build(allTimeA(), allTimeB(), { ["9"] = { a = 5, b = 1 } })
        assert.is_nil(pools[9].received)
        assert.is_nil(pools[9].split)
    end)

    it("gives untracked drops to the only boss with untracked kills", function()
        local b = { tallies = tallies({ Normal = 40 }), allTime = totals({ KC_B = 40 }, { ["9"] = 8 }) }
        local _, pools = build(allTimeA(), b)
        assert.is_false(pools[9].ask)
        assert.are.same({ a = 8, b = 0 }, pools[9].received)
    end)
end)

describe("stats.Untracked", function()
    it("counts every kill as without Boss RNG until kills are tracked", function()
        assert.are.same({ 5000, 1 }, { stats.Untracked(BOSS, tallies({}), totals({ KC_NORMAL = 5000 })) })
    end)

    it("leaves out tracked kills", function()
        assert.are.same({ 5000, 5000 / 5020 },
            { stats.Untracked(BOSS, tallies({ Normal = 20 }), totals({ KC_NORMAL = 5020 })) })
    end)

    it("adds kills made while Boss RNG was off", function()
        assert.are.same({ 5030, 5030 / 5050 },
            { stats.Untracked(BOSS, tallies({ Normal = 20 }), totals({ KC_NORMAL = 5050 })) })
    end)

    it("adds up every mode", function()
        local untracked = stats.Untracked(BOSS, tallies({ Normal = 3, ["Hard mode"] = 2 }),
            totals({ KC_NORMAL = 10, KC_HARD = 10 }))
        assert.are.equal(15, untracked)
    end)

    it("never goes below 0 if the game's count lags", function()
        assert.are.same({ 0, 0 }, { stats.Untracked(BOSS, tallies({ Normal = 12 }), totals({ KC_NORMAL = 10 })) })
    end)

    it("gives a share of 0 with no kills", function()
        assert.are.same({ 0, 0 }, { stats.Untracked(BOSS, tallies({}), totals({})) })
    end)
end)

-- A test boss whose tracked kills are counted for modes made at each kill: full
-- ones (in the kill count) roll item 1 at 1/10, partial ones (outside it) at 1/20.
local EVENTED = {
    modes = { { name = "Normal", kc = "KC", untracked = true, rolls = { { chance = 1 / 10, items = { [1] = 1 } } } } },
    modeFor = function(name)
        local full = name == "Full"
        local chance = full and 1 / 10 or 1 / 20
        return { name = name, kc = full and "KC" or nil, rolls = { { chance = chance, items = { [1] = 1 } } } }
    end,
    extraKills = "partial chest",
    items = { [1] = { kind = "unique" } },
}

describe("stats with kills counted at each kill", function()
    it("counts tracked kills for their own modes, and the kill count's rest for the untracked one", function()
        local result = forBoss(EVENTED, tallies({ Full = 10, Partial = 4 }), totals({ KC = 30 }, { ["1"] = 3 }))
        assert.are.equal(30, result.kills)
        assert.are.equal(4, result.extraKills)
        assert.are.equal("partial chest", result.extraLabel)
        assert.are.near(30 / 10 + 4 / 20, result.expected, 1e-9) -- 20 untracked + 10 full at 1/10, 4 at 1/20
    end)

    it("doesn't count kills outside the kill count as tracked ones in it", function()
        local untracked = { stats.Untracked(EVENTED, tallies({ Full = 10, Partial = 4 }), totals({ KC = 30 })) }
        assert.are.same({ 20, 20 / 30 }, untracked)
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

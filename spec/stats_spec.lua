-- Run from the project root with: busted

local luck = require("src/luck")
local rates = require("src/rates")
local stats = require("src/stats")

local DAY = 20756 -- 30 Oct 2026

-- A test boss: normal mode rolls item 1 at 1/100 and item 2 at 1/50; hard mode
-- rolls item 1 at 1/20.
local BOSS = {
    modes = {
        { name = "Normal", kc = "KC_NORMAL", rolls = { { chance = 3 / 100, items = { [1] = 1, [2] = 2 } } } },
        { name = "Hard mode", kc = "KC_HARD", rolls = { { chance = 1 / 20, items = { [1] = 1 } } } },
    },
    items = { [1] = { kind = "unique" }, [2] = { kind = "unique" }, [3] = { kind = "pet" } },
}

-- Kills on one day, { [mode name] = { [day] = kills } }, from { [mode name] = kills }.
local function onDay(kills, day)
    local byMode = {}
    for name, n in pairs(kills) do
        byMode[name] = { [tostring(day or DAY)] = n }
    end
    return byMode
end

-- Tallies with these kills on DAY, items ({ [item id text] = drops }) and dry
-- streaks ({ [key] = { [mode name] = kills } }, each defaulting to all kills).
local function tallies(kills, items, dry)
    local result = { kills = onDay(kills), items = items or {}, dry = {} }
    for _, key in ipairs({ "any", "1", "2" }) do
        result.dry[key] = onDay((dry or {})[key] or kills)
    end
    return result
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

    it("adds up expected drops per mode over tracked kills", function()
        local result = forBoss(BOSS, tallies({ Normal = 100, ["Hard mode"] = 20 }))
        assert.are.equal(120, result.kills)
        assert.are.near(1 + 1, result.items[1].expected, 1e-9) -- 100/100 + 20/20
        assert.are.near(2, result.items[2].expected, 1e-9) -- 100/50
        assert.are.near(4, result.expected, 1e-9)
        assert.is_nil(result.items[3]) -- pets aren't counted
    end)

    it("compares tracked drops with expected", function()
        local result = forBoss(BOSS, tallies({ Normal = 100 }, { ["1"] = 1, ["2"] = 2 }))
        assert.are.equal(3, result.received)
        assert.are.near(luck.Percentile(3, 3), result.luck, 1e-12)
        assert.are.near(luck.Percentile(1, 1), result.items[1].luck, 1e-12)
    end)

    it("shows luck once an average player would have a unique", function()
        local result = forBoss(BOSS, tallies({ Normal = 20 })) -- 0.6 expected, none received
        assert.is_nil(result.luck)
        assert.are.equal(14, result.killsToLuck) -- 0.4 more at 0.03 a kill
        assert.is_nil(result.items[2].luck) -- 0.4 expected
        assert.are.near(luck.DryPercentile(1 / 50, 20), result.items[2].dryShare, 1e-12)
        assert.is_true(forBoss(BOSS, tallies({ Normal = 34 })).luck ~= nil) -- 1.02 expected
    end)

    it("shows luck from the first unique received, however early", function()
        local result = forBoss(BOSS, tallies({ Normal = 20 }, { ["2"] = 1 })) -- 0.6 expected
        assert.are.near(luck.Percentile(0.6, 1), result.luck, 1e-12)
        assert.are.near(luck.Percentile(0.4, 1), result.items[2].luck, 1e-12)
        assert.is_nil(result.items[1].luck) -- none of item 1 yet
    end)

    it("counts the dry streaks the tracker kept", function()
        local result = forBoss(BOSS, tallies({ Normal = 100 }, { ["1"] = 1, ["2"] = 2 },
            { any = { Normal = 10 }, ["1"] = { Normal = 60 }, ["2"] = { Normal = 10 } }))
        assert.are.equal(10, result.dryKills)
        assert.are.equal(60, result.items[1].dryKills)
        assert.are.near(luck.DryPercentile(3 / 100, 10), result.dryShare, 1e-12)
    end)

    it("counts an item's dry streak only over kills that can drop it", function()
        local result = forBoss(BOSS, tallies({ Normal = 50, ["Hard mode"] = 30 }))
        assert.are.equal(50, result.items[2].dryKills) -- hard mode can't drop item 2
        assert.are.equal(80, result.items[1].dryKills)
    end)

    it("uses each mode's own rates for the dry streak", function()
        local result = forBoss(BOSS, tallies({ Normal = 50, ["Hard mode"] = 50 }))
        local missAll = (1 - 3 / 100) ^ 50 * (1 - 1 / 20) ^ 50
        assert.are.near(1 - missAll, result.dryShare, 1e-12)
    end)

    it("has no luck and no dry share without kills", function()
        local result = forBoss(BOSS, tallies({}))
        assert.is_nil(result.luck)
        assert.is_nil(result.killsToLuck)
        assert.are.equal(0, result.dryShare)
        assert.is_nil(result.since)
    end)

    it("remembers the day of the first tracked kill", function()
        local t = tallies({ Normal = 5 })
        t.kills.Normal[tostring(DAY - 3)] = 2
        assert.are.equal(DAY - 3, forBoss(BOSS, t).since)
    end)

    describe("with all-time totals", function()
        it("shows them as facts, without using them for luck", function()
            local result = forBoss(BOSS, tallies({ Normal = 40 }),
                totals({ KC_NORMAL = 100, KC_HARD = 20 }, { ["1"] = 2, ["2"] = 1 }))
            assert.are.same({ kills = 120, received = 3, stacks = {} }, result.allTime)
            assert.are.equal(40, result.kills)
            assert.are.equal(0, result.received)
            assert.are.near(1.2, result.expected, 1e-9)
            assert.are.equal(2, result.items[1].allTime)
        end)

        it("marks dry streaks that may be longer: nothing tracked, and kills before tracking", function()
            local result = forBoss(BOSS, tallies({ Normal = 10 }, { ["1"] = 1 }),
                totals({ KC_NORMAL = 100, KC_HARD = 0 }, { ["1"] = 3, ["2"] = 1 }))
            assert.is_false(result.dryAtLeast)
            assert.is_false(result.items[1].dryAtLeast)
            assert.is_true(result.items[2].dryAtLeast)
        end)

        it("shows a stacked unique's log count apart, since it counts items, not drops", function()
            local boss = { modes = BOSS.modes, items = {
                [1] = { kind = "unique", stack = { most = 9, word = "spike" } }, [2] = { kind = "unique" } } }
            local result = forBoss(boss, tallies({ Normal = 10 }), totals({ KC_NORMAL = 10, KC_HARD = 0 }, { ["1"] = 184, ["2"] = 3 }))
            assert.are.same({ kills = 10, received = 3, stacks = { { word = "spike", count = 184 } } }, result.allTime)
            assert.is_nil(result.items[1].allTime)
        end)

        it("knows a streak is exact when every kill was tracked", function()
            local result = forBoss(BOSS, tallies({ Normal = 10 }), totals({ KC_NORMAL = 10, KC_HARD = 0 }, {}))
            assert.is_false(result.dryAtLeast)
            assert.is_false(result.items[2].dryAtLeast)
        end)
    end)

    it("marks dry streaks as possibly longer without all-time totals", function()
        assert.is_true(forBoss(BOSS, tallies({ Normal = 30 })).dryAtLeast)
    end)

    it("uses rolls that depend on the player's picks", function()
        local boss = { items = { [1] = { kind = "unique" } }, modes = { { name = "Normal", kc = "KC",
            rolls = function(_, picks) return { { chance = 1 / picks.rate, items = { [1] = 1 } } } end } } }
        assert.are.near(2, forBoss(boss, tallies({ Normal = 100 }), nil, { rate = 50 }).expected, 1e-9)
    end)

    it("shows a group of uniques as one row", function()
        local group = { name = "Pieces" }
        local boss = {
            items = { [1] = { kind = "unique", group = group }, [2] = { kind = "unique", group = group } },
            modes = { { name = "Normal", kc = "KC", rolls = { { chance = 1 / 10, items = { [1] = 1, [2] = 1 } } } } },
        }
        local result = forBoss(boss, tallies({ Normal = 100 }, { ["1"] = 2, ["2"] = 1 },
            { any = { Normal = 10 }, ["1"] = { Normal = 40 }, ["2"] = { Normal = 10 } }),
            totals({ KC = 100 }, { ["1"] = 2, ["2"] = 1 }))
        assert.is_nil(result.items[2])
        local row = result.items[1]
        assert.are.equal(group, row.group)
        assert.are.near(10, row.expected, 1e-9)
        assert.are.equal(3, row.received)
        assert.are.equal(3, row.allTime)
        assert.are.equal(10, row.dryKills) -- since the latest of either
    end)
end)

describe("stats with rates that changed", function()
    local CHANGE = DAY + 10
    -- Item 1 at 1/10 before CHANGE, 1/5 from it.
    local CHANGED = {
        rates = rates.History({ { values = { item = 1 / 10 } }, { since = CHANGE, values = { item = 1 / 5 } } }),
        modes = { { name = "Normal", kc = "KC", rolls = function(r)
            return { { chance = r.item, items = { [1] = 1 } } }
        end } },
        items = { [1] = { kind = "unique" } },
    }

    -- Tallies with 20 kills before CHANGE and 10 from it, all dry.
    local function spanning()
        local byMode = { Normal = { [tostring(CHANGE - 1)] = 20, [tostring(CHANGE)] = 10 } }
        return { kills = byMode, dry = { any = byMode, ["1"] = byMode }, items = {} }
    end

    it("rates each kill at the rates of its day", function()
        assert.are.near(20 / 10 + 10 / 5, forBoss(CHANGED, spanning()).expected, 1e-9)
    end)

    it("rates a dry streak spanning the change kill by kill", function()
        local missAll = (1 - 1 / 10) ^ 20 * (1 - 1 / 5) ^ 10
        assert.are.near(1 - missAll, forBoss(CHANGED, spanning()).dryShare, 1e-12)
    end)

    it("rates kills of an unknown day (0) at today's rates", function()
        local byMode = { Normal = { ["0"] = 10 } }
        local result = forBoss(CHANGED, { kills = byMode, dry = { any = byMode }, items = {} })
        assert.are.near(10 / 5, result.expected, 1e-9)
        assert.is_nil(result.since)
    end)
end)

-- A boss whose kills are counted at each kill: full chests in the kill count
-- (item 1 at 1/10), partial ones outside it (1/20).
local EVENTED = {
    modes = { { name = "Normal", kc = "KC", byEvent = true } },
    modeFor = function(name)
        local full = name == "Full"
        local chance = full and 1 / 10 or 1 / 20
        return { name = name, kc = full and "KC" or nil, rolls = { { chance = chance, items = { [1] = 1 } } } }
    end,
    extraKills = "partial",
    items = { [1] = { kind = "unique" } },
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
        assert.are.equal(3, forBoss(EVENTED, tallies({ Full = 5, Partial = 4 })).killsToLuck) -- 0.3 more
    end)

    it("leaves out kills of modes the boss no longer has", function()
        local boss = { modes = EVENTED.modes, items = EVENTED.items } -- no modeFor
        assert.are.equal(0, forBoss(boss, tallies({ Full = 10 })).kills)
    end)
end)

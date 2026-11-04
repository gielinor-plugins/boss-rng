-- Checks every boss file follows the data format.

local bosses = require("src/bosses")
local luck = require("src/core/luck")
local stats = require("src/core/stats")

-- A day before the Late-Game Rebalance (30 October 2026), and the day it's set to go live.
local BEFORE, AFTER = 20756, require("src/core/rates/late_game_rebalance").day

-- A boss's assumptions for readings (none read yet by default).
local function assumptions(boss, readings)
    local own = boss.assumptions
    return type(own) == "function" and own(readings or {}) or own
end

local function startsWith(text, prefix)
    return type(text) == "string" and text:sub(1, #prefix) == prefix
end

describe("boss data", function()
    it("gives every boss a different key", function()
        local seen = {}
        for _, boss in ipairs(bosses) do
            assert.is_nil(seen[boss.key])
            seen[boss.key] = true
        end
    end)

    for _, boss in ipairs(bosses) do
        describe(boss.name, function()
            it("names its kill count varbits, each counted directly or another way", function()
                assert.is_true(#boss.killCounts > 0)
                local otherWay = (boss.killEvents or boss.claims or boss.containers) ~= nil
                for _, killCount in ipairs(boss.killCounts) do
                    assert.is_true(startsWith(killCount.var, "BSLAY_KILLS_"))
                    if killCount.mode then
                        assert.is_true(boss.modes[killCount.mode] ~= nil)
                    else
                        assert.is_true(otherWay)
                    end
                end
            end)

            it("gives every mode its rolls", function()
                for key, mode in pairs(boss.modes) do
                    assert.is_true(mode.rolls ~= nil)
                    assert.are.equal(key, mode.key)
                end
            end)

            it("gives every unique a log varbit", function()
                for _, item in pairs(boss.items) do
                    assert.is_true(startsWith(item.log, "ITEMLOG_ITEM_"))
                end
            end)

            it("states its assumptions, if any, in plain words", function()
                for _, note in ipairs(assumptions(boss)) do
                    assert.are.equal("string", type(note))
                    assert.is_nil(note:find("<", 1, true)) -- the game would read it as a tag
                end
            end)

            it("only rolls its listed uniques", function()
                for _, mode in pairs(boss.modes) do
                    for _, day in ipairs({ BEFORE, AFTER }) do
                        for itemID in pairs(luck.ItemChances(stats.Rolls(boss, mode, {}, day))) do
                            assert.is_true(boss.items[itemID] ~= nil)
                        end
                    end
                end
            end)
        end)
    end
end)

-- Each boss's wiki rates for a few items in its first two modes (or the two modes
-- named), before the Late-Game Rebalance; after and afterHard, from its day.
local HILT = 63 / 64 / 512 -- a general's hilt: only rolled when the unique table misses
local NEX = 1 / 384
local CASES = {
    {
        file = "graardor",
        rates = { [25022] = 1 / 384, [11704] = HILT },
        after = { [25022] = 1 / 320, [25019] = 1 / 320, [11704] = 1 / 384 },
    },
    {
        file = "kreearra",
        rates = { [11718] = 1 / 384, [11702] = HILT },
        after = { [11718] = 1 / 320, [25013] = 1 / 320, [11702] = 1 / 384 },
    },
    {
        file = "zilyana",
        rates = { [11730] = 1 / 320, [25037] = 1 / 640, [25034] = 1 / 320, [11706] = HILT },
        after = { [11730] = 1 / 320, [25037] = 1 / 320, [34855] = 1 / 320, [11706] = 1 / 384 },
    },
    {
        file = "kril",
        rates = { [24992] = 1 / 512, [11716] = 1 / 512, [11708] = HILT },
        after = {
            [24992] = 1 / 320,
            [25001] = 1 / 320,
            [11716] = 1 / 384,
            [11736] = 1 / 64,
            [11708] = 1 / 384,
        },
    },
    { file = "nex", rates = { [20135] = NEX, [25664] = NEX, [20171] = NEX } },
    {
        file = "helwyr",
        rates = { [37027] = 1 / 256, [40600] = 1 / 256, [37033] = (1 - 6 / 256) / 64 },
        hard = { [37085] = 1 / 179, [37033] = (1 - 6 / 179) / 44 },
        after = { [37027] = 1 / 128, [40600] = 1 / 256, [37033] = (1 - 1 / 128 - 5 / 256) / 64 },
        afterHard = { [37027] = 1 / 128, [37085] = 1 / 179 },
    },
    {
        file = "vindicta",
        rates = { [37018] = 1 / 255, [37070] = 1 / 255, [37030] = (1 - 5 / 255) / 64 },
        hard = { [37070] = 1 / 179, [37030] = (1 - 5 / 179) / 44 },
        after = { [37018] = 1 / 128, [37070] = 1 / 255 },
        afterHard = { [37018] = 1 / 128 },
    },
    {
        file = "furies",
        rates = { [37090] = 1 / 256, [37095] = 1 / 256 },
        hard = { [37024] = 1 / 179 },
        after = { [37024] = 1 / 128 },
        afterHard = { [37024] = 1 / 128 },
    },
    {
        file = "gregorovic",
        rates = { [37075] = 1 / 256, [37080] = 1 / 256 },
        hard = { [37021] = 1 / 179 },
        after = { [37021] = 1 / 128 },
        afterHard = { [37021] = 1 / 128 },
    },
    -- Normal mode, then the 100% enrage tier: an armor piece, a weapon, the Nexus and the Shard.
    {
        file = "amascut",
        modes = { "n", "e100" },
        rates = { [59344] = 3 / 4 / 5 / 600, [59350] = 1 / 4 / 2 / 600, [59358] = 1 / 750 },
        hard = {
            [59336] = 3 / 4 / 5 / 70,
            [59354] = 1 / 4 / 2 / 70,
            [59358] = 1 / 280,
            [57128] = 1 / 280,
        },
    },
    -- Vermyx, then Vermyx in hard mode.
    {
        file = "sanctum",
        modes = { "v", "vh" },
        rates = { [57156] = 1 / 250, [57124] = 1 / 250 },
        hard = { [57156] = 1 / 200 },
    },
    -- Nakatra, then in hard mode: a book, a weapon and, in hard mode only, the Shard.
    {
        file = "sanctum",
        modes = { "n", "nh" },
        rates = { [57124] = 1 / 250, [57162] = 1 / 150 },
        hard = { [57158] = 1 / 120, [57128] = 1 / 75 },
    },
    -- Solo, then duo: a leg and an add-on, each group split evenly.
    {
        file = "araxxi",
        modes = { "s", "d" },
        rates = { [31718] = 1 / 40 / 3, [31723] = 1 / 120 / 3 },
        hard = { [31719] = 1 / 70 / 3, [31724] = 1 / 200 / 3 },
    },
    -- All seven brothers (7 rolls at 1/73), Linza (1/96 over five items) and the
    -- amulet (1/480). Dharok has 4 items, Ahrim 6.
    {
        file = "barrows",
        modes = { "cff" },
        rates = {
            [4716] = 7 / 73 / 7 / 4,
            [25652] = 7 / 73 / 7 / 6,
            [21744] = 7 / 73 / 7 / 4,
            [37449] = 1 / 96 / 5,
            [39061] = 1 / 480,
        },
        after = { [39061] = 1 / 240, [37449] = 1 / 96 / 5 },
    },
    -- One rare roll per chest: normal, then hard mode.
    {
        file = "vorkath",
        rates = { [56079] = 1 / 45, [56068] = 1 / 249 },
        hard = { [56079] = 1 / 15, [56068] = 1 / 150, [56321] = 1 / 150 },
    },
    {
        file = "rots",
        rates = { [30014] = 1 / 240, [30022] = 1 / 240, [30018] = 1 / 240 },
    },
    {
        file = "dragonkin",
        modes = { "as", "a2" },
        rates = { [43391] = 1 / 83 },
        hard = { [43391] = 1 / 166 },
    },
    -- Any crossbow piece, split evenly.
    {
        file = "shadow_reef",
        modes = { "as", "a3" },
        rates = { [47490] = 1 / 55 / 3, [47492] = 1 / 55 / 3 },
        hard = { [47494] = 1 / 166 / 3 },
    },
    {
        file = "corp",
        rates = { [13752] = 1 / 1024, [13748] = 1 / 1024, [13754] = 3 / 512 },
    },
    -- Solo, then duo: the same rates.
    {
        file = "raksha",
        modes = { "s", "d" },
        rates = { [51082] = 1 / 130, [51086] = 1 / 325, [51098] = 1 / 325 },
        hard = { [51082] = 1 / 130, [51094] = 1 / 325 },
    },
    -- Four rares on one roll, raised by the Late-Game Rebalance, and the Latent Offering.
    {
        file = "elidinis",
        rates = { [57519] = 1 / 480, [57544] = 1 / 480, [57528] = 1 / 71 },
        after = { [57519] = 1 / 256, [57524] = 1 / 256, [57528] = 1 / 71 },
    },
    -- Two rolls of their own, both raised by the Late-Game Rebalance.
    {
        file = "magister",
        rates = { [40650] = 1 / 18, [40320] = 1 / 500 },
        after = { [40650] = 1 / 10, [40320] = 1 / 128 },
    },
    -- Every unique is 1/640: a 1/320 weapon roll and a 1/128 armor roll.
    {
        file = "rasial",
        rates = { [55480] = 1 / 640, [55482] = 1 / 640, [55488] = 1 / 640, [55496] = 1 / 640 },
    },
    {
        file = "solak",
        rates = {
            [42785] = 1 / 200,
            [42770] = 1 / 400,
            [42774] = 1 / 400,
            [42767] = 1 / 500,
            [42782] = 1 / 500,
        },
        after = { [42785] = 1 / 200, [42770] = 1 / 200, [42774] = 1 / 200, [42767] = 1 / 500 },
    },
    -- Full contribution: 12 rolls at 1/5,400 each, then 1/3,000 armor and 1/2,500 others.
    {
        file = "croesus",
        modes = { "r12" },
        rates = { [52250] = 12 / 5400, [52345] = 12 / 5400 },
        after = { [52250] = 12 / 3000, [52345] = 12 / 2500, [52213] = 12 / 2500 },
    },
    -- Three loot piles, normal then hard mode.
    {
        file = "kerapac",
        modes = { "n3", "h3" },
        rates = { [51767] = 1 / 256, [51843] = 1 / 256 },
        hard = { [51782] = 1 / 400, [51812] = 399 / 400 / 180 },
    },
    -- Hard mode without checkpoints: 1/27 for any sword piece.
    {
        file = "zuk",
        rates = { [52530] = 1 / 100, [52492] = 1 / 100 },
        hard = { [52505] = 1 / 27 / 3, [52530] = 1 / 50, [52492] = 1 / 50 },
    },
    -- Hard mode only, a streak's first kill at 0% enrage: any unique 1,525 in a million.
    {
        file = "archglacor",
        modes = { "h" },
        rates = { [52020] = 1525 / 1e6 * 0.24, [52115] = 1525 / 1e6 * 0.38, [52019] = 1 / 100 },
    },
}

for _, case in ipairs(CASES) do
    describe(case.file, function()
        local boss = require("src/bosses/" .. case.file)

        -- expected is { rates, hard rates }.
        local function check(day, expected)
            for modeIndex, rates in pairs(expected) do
                local mode = boss.modes[(case.modes or { "n", "h" })[modeIndex]]
                local chances = luck.ItemChances(stats.Rolls(boss, mode, {}, day))
                for itemID, rate in pairs(rates) do
                    assert.are.near(rate, chances[itemID], 1e-12)
                end
            end
        end

        it("has the wiki rates", function()
            check(BEFORE, { case.rates, case.hard })
        end)

        if case.after then
            it("has the Late-Game Rebalance's rates from its day", function()
                check(AFTER, { case.after, case.afterHard })
                check(AFTER - 1, { case.rates, case.hard })
            end)
        end
    end)
end

it("counts each tracked Araxxi kill as solo or duo by the duo flag", function()
    local event = require("src/bosses/araxxi").killEvents[1]
    assert.are.equal("s", event.mode({ duo = 0 }))
    assert.are.equal("d", event.mode({ duo = 1 }))
end)

it("counts Kerapac's kills by the loot piles seen at them", function()
    local boss = require("src/bosses/kerapac")
    local normal, hard = boss.killEvents[1], boss.killEvents[2]
    assert.are.equal("n3", normal.mode({ piles = 3 }))
    assert.are.equal("h2", hard.mode({ piles = 2 }))
    assert.are.equal("n1", normal.mode({ piles = 0 })) -- away at the kill
    assert.are.equal("n3", normal.mode({ piles = 4 }))
    local twoPiles = boss.modes.n2
    assert.are.equal(2, twoPiles.piles)
    assert.are.near(2 / 256 / 3, luck.ItemChances(stats.Rolls(boss, twoPiles, {}))[51767], 1e-12)
end)

describe("TzKal-Zuk's checkpoints", function()
    local boss = require("src/bosses/zuk")
    local event = boss.killEvents[1]

    local function pieceChance(key)
        return luck.ItemChances(stats.Rolls(boss, boss.modes[key], {}))[52505] * 3
    end

    it("counts a hard mode kill by whether an Igneous stone came in its tick", function()
        assert.are.equal("h", event.mode({ stone = true, stones = 109 }))
        assert.are.equal("hc", event.mode({ stone = false, stones = 109 }))
        assert.are.equal("h", event.mode({ stone = false, stones = 250 })) -- the log is full
        assert.are.near(1 / 27, pieceChance("h"), 1e-12)
        assert.are.near(1 / 30, pieceChance("hc"), 1e-12)
    end)

    it("assumes no checkpoints only once the stone log is full", function()
        assert.are.equal(0, #assumptions(boss, {}))
        assert.are.equal(0, #assumptions(boss, { stones = 249 }))
        assert.are.equal(1, #assumptions(boss, { stones = 250 }))
    end)
end)

describe("the pontifex shadow ring", function()
    local zuk = require("src/bosses/zuk")

    -- Each Elder God Wars Dungeon boss's mode, and items the ring doesn't raise.
    local BOSSES = {
        { file = "zuk", mode = "h" },
        { file = "kerapac", mode = "h3" },
        { file = "croesus", mode = "r12" },
        { file = "archglacor", mode = "h", unraised = { [52019] = true } }, -- dark nilas
    }

    it("raises every Elder God Wars Dungeon unique 2% once overcharged", function()
        for _, case in ipairs(BOSSES) do
            local boss = require("src/bosses/" .. case.file)
            local mode = boss.modes[case.mode]
            local plain = luck.ItemChances(stats.Rolls(boss, mode, { ring = 0 }))
            local raised = luck.ItemChances(stats.Rolls(boss, mode, { ring = 1 }))
            for itemID, chance in pairs(plain) do
                local expected = (case.unraised or {})[itemID] and chance or chance / 0.98
                assert.are.near(expected, raised[itemID], 1e-12)
            end
        end
        assert.are.near(
            1 / 49,
            luck.ItemChances(stats.Rolls(zuk, zuk.modes.h, { ring = 1 }))[52492],
            1e-12
        )
    end)
end)

describe("Arch-Glacor's streaks", function()
    local boss = require("src/bosses/archglacor")
    local hard = boss.modes.h

    it("rates each kill by the fight's enrage and its place in the streak", function()
        assert.are.equal(hard, boss.modes[boss.killEvents[1].mode({})])
        local means = { enrage = 4000, streak = 200 } -- the most: any unique 66,500 in a million
        local chances = luck.ItemChances(stats.Rolls(boss, hard, { ring = 1 }, nil, means))
        assert.are.near(66500 / 1e6 * 0.38 / 0.98, chances[52021], 1e-12) -- the Leng artefact
        assert.are.near(66500 / 1e6 * 0.24 / 0.98, chances[52020], 1e-12) -- the Frozen core
    end)
end)

it("counts each tracked Dragonkin Laboratory group kill by the players at the kill", function()
    local boss = require("src/bosses/dragonkin")
    local event = boss.killEvents[3] -- the Black stone dragon's
    assert.is_nil(event.mode({ players = 0 })) -- not read yet: left uncounted
    assert.are.equal("b1", event.mode({ players = 1 }))
    assert.are.equal("b3", event.mode({ players = 4 }))
    local mode = boss.modes[event.mode({ players = 2 })]
    assert.are.equal("b2", mode.key)
    assert.are.near(1 / 166, luck.ItemChances(stats.Rolls(boss, mode, {}))[43393], 1e-12)
end)

it("counts the Shadow Reef's group kills by the players at the kill", function()
    local boss = require("src/bosses/shadow_reef")
    local event = boss.killEvents[1]
    local mode = boss.modes[event.mode({ players = 2 })]
    assert.are.equal("a2", mode.key)
    assert.are.near(1 / 111 / 3, luck.ItemChances(stats.Rolls(boss, mode, {}))[47490], 1e-12)
end)

it("counts each tracked Croesus kill at the unique rolls of its contribution", function()
    local boss = require("src/bosses/croesus")
    local event = boss.killEvents[1]
    assert.are.equal("r12", event.mode({ contribution = 466 })) -- seen in game
    assert.are.equal("r11", event.mode({ contribution = 419 }))
    assert.are.equal("r1", event.mode({ contribution = 60 }))
    assert.are.equal("r0", event.mode({ contribution = 59 })) -- one loot roll, no uniques
    assert.is_nil(event.mode({})) -- no contribution seen: uncounted
    local two = boss.modes.r2
    assert.are.near(2 / 5400, luck.ItemChances(stats.Rolls(boss, two, {}, BEFORE))[52250], 1e-12)
    -- The rebalance
    assert.are.near(2 / 3000, luck.ItemChances(stats.Rolls(boss, two, {}, AFTER))[52250], 1e-12)
    assert.are.near(2 / 2500, luck.ItemChances(stats.Rolls(boss, two, {}, AFTER))[52345], 1e-12)
    assert.are.same({}, stats.Rolls(boss, boss.modes.r0, {}))
end)

describe("Barrows", function()
    local boss = require("src/bosses/barrows")
    local SIX = { "Ahrim", "Dharok", "Guthan", "Karil", "Torag", "Verac" }

    -- The chest's mode key from the game's values for these brothers.
    local function opened(originals, akrisae, linza)
        local values = { Ahrim = 0, Dharok = 0, Guthan = 0, Karil = 0, Torag = 0, Verac = 0 }
        for _, name in ipairs(originals) do
            values[name] = 1
        end
        values.linzaKilled = linza and 1 or 0
        values.killedCount = #originals + (akrisae and 1 or 0) + values.linzaKilled
        return boss.killEvents[1].mode(values)
    end

    it("keys a tracked chest by the brothers killed, Akrisae from the count", function()
        assert.are.equal("cff", opened(SIX, true, true))
        assert.are.equal("cbf", opened(SIX, false, true))
        assert.are.equal("c7f", opened(SIX, true, false))
        assert.are.equal("c7", opened({ "Ahrim", "Dharok", "Guthan" }, false, false))
    end)

    it("gives a full chest the kill count and a partial one only its brothers' items", function()
        local full = boss.modes[opened(SIX, true, true)]
        assert.is_nil(full.partial)
        local chances = luck.ItemChances(stats.Rolls(boss, full, {}, BEFORE))
        assert.are.near(7 / 73 / 7 / 4, chances[4716], 1e-12)
        assert.are.near(1 / 96 / 5, chances[37449], 1e-12)

        -- Five originals and Akrisae make six: in the kill count too.
        local fiveAndAkrisae =
            opened({ "Dharok", "Guthan", "Karil", "Torag", "Verac" }, true, false)
        assert.is_nil(boss.modes[fiveAndAkrisae].partial)

        local threeBrothers = boss.modes[opened({ "Ahrim", "Dharok", "Guthan" }, false, false)]
        assert.is_true(threeBrothers.partial)
        chances = luck.ItemChances(stats.Rolls(boss, threeBrothers, {}, BEFORE))
        assert.are.near(4 / 276 / 3 / 4, chances[4716], 1e-12) -- 3 brothers: 4 rolls at 1/276
        assert.is_nil(chances[4732]) -- no Karil
        assert.is_nil(chances[37449]) -- no Linza
        assert.are.near(1 / 480, chances[39061], 1e-12) -- the amulet, in every chest
    end)
end)

it("counts Amascut's claimed loot piles by mode: normal, or the enrage's tier", function()
    local boss = require("src/bosses/amascut")
    local claim = boss.claims[1]
    -- The loot var's old values seen in game: 2 piles at 1,000% enrage, 3 in normal mode.
    assert.are.equal("e1000", claim.mode({ enrage = 1000 }, 0x500207D0))
    assert.are.equal("n", claim.mode({ enrage = 1000 }, 0x000307D0))
    assert.are.equal("e100", claim.mode({ enrage = 100 }, 0x100107D0))
    assert.are.equal("e500", claim.mode({ enrage = 749 }, 0x200107D0))
    assert.are.equal("e2000", claim.mode({ enrage = 4000 }, 0x700107D0))
end)

it("counts each Sanctum boss's claimed loot as one kill, by its difficulty", function()
    local boss = require("src/bosses/sanctum")
    local vermyx, kezalam, nakatra = boss.claims[1], boss.claims[2], boss.claims[3]
    -- The loot var's values seen in game (rare fields left out): each boss's loot
    -- waiting bit, with difficulty 0 in normal mode and 1 in hard mode.
    assert.are.equal("v", vermyx.mode({}, 0xC001))
    assert.are.equal("k", kezalam.mode({}, 0xC004))
    assert.are.equal("n", nakatra.mode({}, 0xC010))
    assert.are.equal("nh", nakatra.mode({}, 0xD010))
    assert.are.equal("vh", vermyx.mode({}, 0xC101))
end)

it("rolls Nakatra's Shard of Genesis Essence only in hard mode", function()
    local sanctum = require("src/bosses/sanctum")
    local normal = luck.ItemChances(stats.Rolls(sanctum, sanctum.modes.n, {}))
    assert.is_nil(normal[57128])
end)

it("pools the Shard of Genesis Essence between Amascut and the Sanctum", function()
    local shard = require("src/bosses/amascut").items[57128]
    assert.are.equal(2, #shard.pooledBy)
    assert.are.equal(shard, require("src/bosses/sanctum").items[57128])
end)

-- The generals' uniques can't drop together, so their chances simply add up.
it("gives a general at most one unique per kill", function()
    local zilyana = require("src/bosses/zilyana")
    local rolls = stats.Rolls(zilyana, zilyana.modes.n, {}, BEFORE)
    assert.are.near(1 / 64 + HILT, luck.ChanceOfAny(rolls), 1e-12)
end)

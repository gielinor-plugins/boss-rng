-- Checks every boss file follows the data format.

local bosses = require("src/bosses")
local luck = require("src/core/luck")
local stats = require("src/core/stats")

-- A day before the Late-Game Rebalance (30 Oct 2026), and the day it went live.
local BEFORE, AFTER = 20756, require("src/core/rates/late_game_rebalance").day

-- A boss's assumptions for readings (none read yet by default).
local function assumptions(boss, readings)
    local own = boss.assumptions
    return type(own) == "function" and own(readings or {}) or own
end

local KINDS = { unique = true, shared = true, lore = true, pet = true, excluded = true }

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
            it("names a KC varbit for each mode", function()
                assert.is_true(#boss.modes > 0)
                for _, mode in ipairs(boss.modes) do
                    assert.is_true(startsWith(mode.kc, "BSLAY_KILLS_"))
                end
            end)

            it("keys each mode uniquely", function()
                local seen = {}
                for _, mode in ipairs(boss.modes) do
                    assert.is_nil(seen[mode.key])
                    seen[mode.key] = true
                end
            end)

            it("counts a kill count by its kill events only if it has them", function()
                for _, mode in ipairs(boss.modes) do
                    assert.is_true(mode.byEvent == true or mode.rolls ~= nil)
                    assert.is_true(
                        not mode.byEvent
                            or (boss.killEvents or boss.containers or boss.claims) ~= nil
                    )
                end
            end)

            it("gives every item a known kind, and counted items a log varbit", function()
                for _, item in pairs(boss.items) do
                    assert.is_true(KINDS[item.kind] == true)
                    if item.kind == "unique" or item.kind == "shared" then
                        assert.is_true(startsWith(item.log, "ITEMLOG_ITEM_"))
                    end
                end
            end)

            it("states its assumptions, if any, in plain words", function()
                for _, note in ipairs(assumptions(boss)) do
                    assert.are.equal("string", type(note))
                    assert.is_nil(note:find("<", 1, true)) -- the game would read it as a tag
                end
            end)

            it("only rolls unique items", function()
                for _, mode in ipairs(boss.modes) do
                    for _, day in ipairs({ BEFORE, AFTER }) do
                        for itemID in pairs(luck.ItemChances(stats.Rolls(boss, mode, {}, day))) do
                            assert.are.equal("unique", boss.items[itemID].kind)
                        end
                    end
                end
            end)
        end)
    end
end)

-- Each boss's log item count and wiki rates for a few items in its first two
-- modes (or modes), before the Late-Game Rebalance; after and afterHard, after it.
local HILT = 63 / 64 / 512 -- a general's hilt: only rolled when the unique table misses
local NEX = 1 / 384
local CASES = {
    {
        file = "graardor",
        items = 18,
        rates = { [25022] = 1 / 384, [11704] = HILT },
        after = { [25022] = 1 / 320, [25019] = 1 / 320, [11704] = 1 / 384 },
    },
    {
        file = "kreearra",
        items = 18,
        rates = { [11718] = 1 / 384, [11702] = HILT },
        after = { [11718] = 1 / 320, [25013] = 1 / 320, [11702] = 1 / 384 },
    },
    {
        file = "zilyana",
        items = 19,
        rates = { [11730] = 1 / 320, [25037] = 1 / 640, [25034] = 1 / 320, [11706] = HILT },
        after = { [11730] = 1 / 320, [25037] = 1 / 320, [34855] = 1 / 320, [11706] = 1 / 384 },
    },
    {
        file = "kril",
        items = 20,
        rates = { [24992] = 1 / 512, [11716] = 1 / 512, [11708] = HILT },
        after = {
            [24992] = 1 / 320,
            [25001] = 1 / 320,
            [11716] = 1 / 384,
            [11736] = 1 / 64,
            [11708] = 1 / 384,
        },
    },
    { file = "nex", items = 21, rates = { [20135] = NEX, [25664] = NEX, [20171] = NEX } },
    {
        file = "helwyr",
        items = 8,
        rates = { [37027] = 1 / 256, [40600] = 1 / 256, [37033] = (1 - 6 / 256) / 64 },
        hard = { [37085] = 1 / 179, [37033] = (1 - 6 / 179) / 44 },
        after = { [37027] = 1 / 128, [40600] = 1 / 256, [37033] = (1 - 1 / 128 - 5 / 256) / 64 },
        afterHard = { [37027] = 1 / 128, [37085] = 1 / 179 },
    },
    {
        file = "vindicta",
        items = 8,
        rates = { [37018] = 1 / 255, [37070] = 1 / 255, [37030] = (1 - 5 / 255) / 64 },
        hard = { [37070] = 1 / 179, [37030] = (1 - 5 / 179) / 44 },
        after = { [37018] = 1 / 128, [37070] = 1 / 255 },
        afterHard = { [37018] = 1 / 128 },
    },
    {
        file = "furies",
        items = 9,
        rates = { [37090] = 1 / 256, [37095] = 1 / 256 },
        hard = { [37024] = 1 / 179 },
        after = { [37024] = 1 / 128 },
        afterHard = { [37024] = 1 / 128 },
    },
    {
        file = "gregorovic",
        items = 8,
        rates = { [37075] = 1 / 256, [37080] = 1 / 256 },
        hard = { [37021] = 1 / 179 },
        after = { [37021] = 1 / 128 },
        afterHard = { [37021] = 1 / 128 },
    },
    -- Normal mode, then the 100% enrage tier: an armor piece, a weapon, the Nexus and the Shard.
    {
        file = "amascut",
        items = 11,
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
        items = 9,
        rates = { [57156] = 1 / 250, [57124] = 1 / 250 },
        hard = { [57156] = 1 / 200 },
    },
    -- Solo, then duo: a leg and an add-on, each group split evenly.
    {
        file = "araxxi",
        items = 15,
        modes = { "s", "d" },
        rates = { [31718] = 1 / 40 / 3, [31723] = 1 / 120 / 3 },
        hard = { [31719] = 1 / 70 / 3, [31724] = 1 / 200 / 3 },
    },
    -- All seven brothers (7 rolls at 1/73), Linza (1/96 over five items) and the
    -- amulet (1/480). Dharok has 4 items, Ahrim 6.
    {
        file = "barrows",
        items = 39,
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
        items = 5,
        rates = { [56079] = 1 / 45, [56068] = 1 / 249 },
        hard = { [56079] = 1 / 15, [56068] = 1 / 150, [56321] = 1 / 150 },
    },
    {
        file = "rots",
        items = 10,
        rates = { [30014] = 1 / 240, [30022] = 1 / 240, [30018] = 1 / 240 },
    },
    {
        file = "dragonkin",
        items = 7,
        modes = { "as", "a2" },
        rates = { [43391] = 1 / 83 },
        hard = { [43391] = 1 / 166 },
    },
    -- Any crossbow piece, split evenly.
    {
        file = "shadow_reef",
        items = 7,
        modes = { "as", "a3" },
        rates = { [47490] = 1 / 55 / 3, [47492] = 1 / 55 / 3 },
        hard = { [47494] = 1 / 166 / 3 },
    },
    {
        file = "corp",
        items = 7,
        rates = { [13752] = 1 / 1024, [13748] = 1 / 1024, [13754] = 3 / 512 },
    },
    -- Solo, then duo: the same rates.
    {
        file = "raksha",
        items = 6,
        rates = { [51082] = 1 / 130, [51086] = 1 / 325, [51098] = 1 / 325 },
        hard = { [51082] = 1 / 130, [51094] = 1 / 325 },
    },
    -- Four rares on one roll, raised by the Late-Game Rebalance, and the Latent Offering.
    {
        file = "elidinis",
        items = 7,
        rates = { [57519] = 1 / 480, [57544] = 1 / 480, [57528] = 1 / 71 },
        after = { [57519] = 1 / 256, [57524] = 1 / 256, [57528] = 1 / 71 },
    },
    -- Two rolls of their own, both raised by the Late-Game Rebalance.
    {
        file = "magister",
        items = 8,
        rates = { [40650] = 1 / 18, [40320] = 1 / 500 },
        after = { [40650] = 1 / 10, [40320] = 1 / 128 },
    },
    -- Every unique is 1/640: a 1/320 weapon roll and a 1/128 armor roll.
    {
        file = "rasial",
        items = 8,
        rates = { [55480] = 1 / 640, [55482] = 1 / 640, [55488] = 1 / 640, [55496] = 1 / 640 },
    },
    {
        file = "solak",
        items = 7,
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
        items = 10,
        rates = { [52250] = 12 / 5400, [52345] = 12 / 5400 },
        after = { [52250] = 12 / 3000, [52345] = 12 / 2500, [52213] = 12 / 2500 },
    },
    -- Three loot piles, normal then hard mode.
    {
        file = "kerapac",
        items = 7,
        modes = { "n3", "h3" },
        rates = { [51767] = 1 / 256, [51843] = 1 / 256 },
        hard = { [51782] = 1 / 400, [51812] = 399 / 400 / 180 },
    },
    -- Hard mode without checkpoints: 1/27 for any sword piece.
    {
        file = "zuk",
        items = 7,
        rates = { [52530] = 1 / 100, [52492] = 1 / 100 },
        hard = { [52505] = 1 / 27 / 3, [52530] = 1 / 50, [52492] = 1 / 50 },
    },
    -- Hard mode only, a streak's first kill at 0% enrage: any unique 1,525 in a million.
    {
        file = "archglacor",
        items = 13,
        rates = { [52020] = 1525 / 1e6 * 0.24, [52115] = 1525 / 1e6 * 0.38, [52019] = 1 / 100 },
    },
}

local function modeKeyed(boss, key)
    for _, mode in ipairs(boss.modes) do
        if mode.key == key then
            return mode
        end
    end
    return boss.modeFor(key)
end

for _, case in ipairs(CASES) do
    describe(case.file, function()
        local boss = require("src/bosses/" .. case.file)

        it("lists all " .. case.items .. " boss log items", function()
            local count = 0
            for _ in pairs(boss.items) do
                count = count + 1
            end
            assert.are.equal(case.items, count)
        end)

        -- expected is { rates, hard rates }.
        local function check(day, expected)
            for modeIndex, rates in pairs(expected) do
                local mode = case.modes and modeKeyed(boss, case.modes[modeIndex])
                    or boss.modes[modeIndex]
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
    local boss = require("src/bosses/araxxi")
    local event = boss.killEvents[1]
    assert.are.equal("BSLAY_KILLS_ARAXXI", event.var)
    assert.are.equal("s", event.mode({ duo = 0 }))
    assert.are.equal("d", event.mode({ duo = 1 }))
    local duo = luck.ItemChances(stats.Rolls(boss, boss.modeFor("d"), {}))
    assert.are.near(1 / 70 / 3, duo[31718], 1e-12)
    assert.are.near(
        1 / 120 / 3,
        luck.ItemChances(stats.Rolls(boss, boss.modeFor("s"), {}))[31722],
        1e-12
    )
    assert.are.equal("BSLAY_KILLS_ARAXXI", boss.modeFor("d").kc)
end)

it("counts Kerapac's kills by the loot piles seen at them", function()
    local boss = require("src/bosses/kerapac")
    local normal, hard = boss.killEvents[1], boss.killEvents[2]
    assert.are.same({ 51804, 51805 }, normal.piles) -- Resonant anima of Jas, in every pile
    assert.are.equal("n3", normal.mode({ piles = 3 }))
    assert.are.equal("h2", hard.mode({ piles = 2 }))
    assert.are.equal("n1", normal.mode({ piles = 0 })) -- away at the kill
    assert.are.equal("n3", normal.mode({ piles = 4 }))
    local twoPiles = boss.modeFor("n2")
    assert.are.equal(2, twoPiles.piles)
    assert.are.near(2 / 256 / 3, luck.ItemChances(stats.Rolls(boss, twoPiles, {}))[51767], 1e-12)
    assert.are.near(
        1 / 400 / 3,
        luck.ItemChances(stats.Rolls(boss, boss.modeFor("h1"), {}))[51782],
        1e-12
    )
    assert.are.equal("BSLAY_KILLS_EGWD_JAS_BOSS_HARDMODE", boss.modeFor("h1").kc)
end)

describe("TzKal-Zuk's checkpoints", function()
    local boss = require("src/bosses/zuk")
    local event = boss.killEvents[1]

    local function pieceChance(key)
        return luck.ItemChances(stats.Rolls(boss, boss.modeFor(key), {}))[52505] * 3
    end

    it("counts a hard mode kill by whether an Igneous stone came in its tick", function()
        assert.are.equal("BSLAY_KILLS_EGWD_FUL_BOSS_HARDMODE", event.var)
        assert.are.equal("h", event.mode({ stone = true, stones = 109 }))
        assert.are.equal("hc", event.mode({ stone = false, stones = 109 }))
        assert.are.equal("h", event.mode({ stone = false, stones = 250 })) -- the log is full
        assert.are.near(1 / 27, pieceChance("h"), 1e-12)
        assert.are.near(1 / 30, pieceChance("hc"), 1e-12)
        assert.are.equal("BSLAY_KILLS_EGWD_FUL_BOSS_HARDMODE", boss.modeFor("hc").kc)
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
            local mode = boss.modeFor(case.mode)
            local plain = luck.ItemChances(stats.Rolls(boss, mode, { ring = 0 }))
            local raised = luck.ItemChances(stats.Rolls(boss, mode, { ring = 1 }))
            for itemID, chance in pairs(plain) do
                local expected = (case.unraised or {})[itemID] and chance or chance / 0.98
                assert.are.near(expected, raised[itemID], 1e-12)
            end
        end
        assert.are.near(
            1 / 49,
            luck.ItemChances(stats.Rolls(zuk, zuk.modeFor("h"), { ring = 1 }))[52492],
            1e-12
        )
    end)
end)

describe("Arch-Glacor's streaks", function()
    local boss = require("src/bosses/archglacor")
    local hard = boss.modeFor("h")

    it("notes that a claim's dark nilas count as one drop", function()
        assert.are.same({ "A claim's dark nilas count as one drop" }, assumptions(boss, {}))
    end)

    it("rates each kill by the fight's enrage and its place in the streak", function()
        local event = boss.killEvents[1]
        assert.are.equal("BSLAY_KILLS_EGWD_WEN_BOSS_HARDMODE", event.var)
        assert.are.same({ "enrage", "streak" }, event.sums)
        assert.are.equal(hard, boss.modeFor(event.mode({})))
        local means = { enrage = 4000, streak = 200 } -- the most: any unique 66,500 in a million
        local chances = luck.ItemChances(stats.Rolls(boss, hard, { ring = 1 }, nil, means))
        assert.are.near(66500 / 1e6 * 0.38 / 0.98, chances[52021], 1e-12) -- the Leng artefact
        assert.are.near(66500 / 1e6 * 0.24 / 0.98, chances[52020], 1e-12) -- the Frozen core
    end)
end)

it("counts each tracked Dragonkin Laboratory group kill by the players at the kill", function()
    local boss = require("src/bosses/dragonkin")
    local event = boss.killEvents[3] -- the Black stone dragon's
    assert.are.equal("BSLAY_KILLS_DUNGEON_DRAGONFORT3", event.var)
    assert.is_nil(event.mode({ players = 0 })) -- not read yet: left uncounted
    assert.are.equal("b1", event.mode({ players = 1 }))
    assert.are.equal("b3", event.mode({ players = 4 }))
    local mode = boss.modeFor(event.mode({ players = 2 }))
    assert.are.equal("b2", mode.key)
    assert.are.equal("BSLAY_KILLS_DUNGEON_DRAGONFORT3", mode.kc)
    assert.are.near(1 / 166, luck.ItemChances(stats.Rolls(boss, mode, {}))[43393], 1e-12)
end)

it("counts the Shadow Reef's group kills by the players at the kill", function()
    local boss = require("src/bosses/shadow_reef")
    local event = boss.killEvents[1]
    assert.are.equal("BSLAY_KILLS_DUNGEON_ULTHVEN3", event.var)
    assert.are.equal("BSLAY_KILLS_DUNGEON_ULTHVEN3_SOLO", boss.modes[1].kc)
    local mode = boss.modeFor(event.mode({ players = 2 }))
    assert.are.equal("a2", mode.key)
    assert.are.near(1 / 111 / 3, luck.ItemChances(stats.Rolls(boss, mode, {}))[47490], 1e-12)
end)

it("counts each tracked Croesus kill at the unique rolls of its contribution", function()
    local boss = require("src/bosses/croesus")
    local event = boss.killEvents[1]
    assert.are.equal("EGWD_BIK_BOSS_PERSONAL_CONTRIBUTION", event.lasts.contribution)
    assert.are.equal("r12", event.mode({ contribution = 466 })) -- seen in game
    assert.are.equal("r11", event.mode({ contribution = 419 }))
    assert.are.equal("r1", event.mode({ contribution = 60 }))
    assert.are.equal("r0", event.mode({ contribution = 59 })) -- one loot roll, no uniques
    assert.is_nil(event.mode({})) -- no contribution seen: uncounted
    local two = boss.modeFor("r2")
    assert.are.near(2 / 5400, luck.ItemChances(stats.Rolls(boss, two, {}, BEFORE))[52250], 1e-12)
    assert.are.near(2 / 3000, luck.ItemChances(stats.Rolls(boss, two, {}, AFTER))[52250], 1e-12) -- the rebalance
    assert.are.near(2 / 2500, luck.ItemChances(stats.Rolls(boss, two, {}, AFTER))[52345], 1e-12)
    assert.are.same({}, stats.Rolls(boss, boss.modeFor("r0"), {}))
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
        local full = boss.modeFor(opened(SIX, true, true))
        assert.are.equal("BSLAY_KILLS_BARROWS", full.kc)
        local chances = luck.ItemChances(stats.Rolls(boss, full, {}, BEFORE))
        assert.are.near(7 / 73 / 7 / 4, chances[4716], 1e-12)
        assert.are.near(1 / 96 / 5, chances[37449], 1e-12)

        -- Five originals and Akrisae make six: in the kill count too.
        local fiveAndAkrisae =
            opened({ "Dharok", "Guthan", "Karil", "Torag", "Verac" }, true, false)
        assert.are.equal("BSLAY_KILLS_BARROWS", boss.modeFor(fiveAndAkrisae).kc)

        local partial = boss.modeFor(opened({ "Ahrim", "Dharok", "Guthan" }, false, false))
        assert.is_nil(partial.kc)
        chances = luck.ItemChances(stats.Rolls(boss, partial, {}, BEFORE))
        assert.are.near(4 / 276 / 3 / 4, chances[4716], 1e-12) -- 3 brothers: 4 rolls at 1/276
        assert.is_nil(chances[4732]) -- no Karil
        assert.is_nil(chances[37449]) -- no Linza
        assert.are.near(1 / 480, chances[39061], 1e-12) -- the amulet, in every chest
    end)
end)

it("counts Amascut's claimed loot piles by mode: normal, or the enrage's tier", function()
    local boss = require("src/bosses/amascut")
    local claim = boss.claims[1]
    assert.are.equal("AMASCUT_BOSS_VARP_1", claim.var)
    -- The loot var's old values seen in game: 2 piles at 1,000% enrage, 3 in normal mode.
    assert.are.equal(2, (0x500207D0 & claim.mask) >> 16)
    assert.are.equal("e1000", claim.mode({ enrage = 1000 }, 0x500207D0))
    assert.are.equal("n", claim.mode({ enrage = 1000 }, 0x000307D0))
    assert.are.equal("e100", claim.mode({ enrage = 100 }, 0x100107D0))
    assert.are.equal("e500", claim.mode({ enrage = 749 }, 0x200107D0))
    assert.are.equal("e2000", claim.mode({ enrage = 4000 }, 0x700107D0))
    assert.are.same(
        { "BSLAY_KILLS_AMASCUT_BOSS", "BSLAY_KILLS_AMASCUT_BOSS_HARDMODE" },
        claim.kills
    )
    assert.are.equal("BSLAY_KILLS_AMASCUT_BOSS_HARDMODE", boss.modeFor("e750").kc)
    assert.are.equal("pile", boss.unit)
end)

it("counts each Sanctum boss's claimed loot as one kill, by its difficulty", function()
    local boss = require("src/bosses/sanctum")
    local vermyx, kezalam, nakatra = boss.claims[1], boss.claims[2], boss.claims[3]
    -- The loot var's values seen in game (rare fields left out): each boss's loot
    -- waiting bit, with difficulty 0 in normal mode and 1 in hard mode.
    assert.are.equal("RAID_REBIRTH1_VARP_1", nakatra.var)
    assert.are.same({ 0x1, 0x4, 0x10 }, { vermyx.mask, kezalam.mask, nakatra.mask })
    assert.are.equal("v", vermyx.mode({}, 0xC001))
    assert.are.equal("k", kezalam.mode({}, 0xC004))
    assert.are.equal("n", nakatra.mode({}, 0xC010))
    assert.are.equal("nh", nakatra.mode({}, 0xD010))
    assert.are.equal("vh", vermyx.mode({}, 0xC101))
    assert.are.same({
        "BSLAY_KILLS_RAID_REBIRTH1_SLAYER_MASTER_BOSS",
        "BSLAY_KILLS_RAID_REBIRTH1_SLAYER_MASTER_BOSS_HARDMODE",
    }, nakatra.kills)
    assert.are.equal("BSLAY_KILLS_RAID_REBIRTH1_BEAST_BOSS_HARDMODE", boss.modeFor("kh").kc)
    assert.is_nil(boss.unit) -- shown as kills
end)

-- Nakatra's rolls, normal then hard mode.
describe("sanctum's Nakatra", function()
    local sanctum = require("src/bosses/sanctum")
    local modes = sanctum.modes
    local function chances(mode)
        return luck.ItemChances(stats.Rolls(sanctum, mode, {}))
    end

    it("has the wiki rates", function()
        local normal, hard = chances(modes[5]), chances(modes[6])
        assert.are.near(1 / 250, normal[57124], 1e-12)
        assert.are.near(1 / 150, normal[57162], 1e-12)
        assert.is_nil(normal[57128])
        assert.are.near(1 / 120, hard[57158], 1e-12)
        assert.are.near(1 / 75, hard[57128], 1e-12)
    end)
end)

it("pools the Shard of Genesis Essence between Amascut and the Sanctum", function()
    local shard = require("src/bosses/amascut").items[57128]
    assert.are.equal(2, #shard.pooledBy)
    assert.are.equal(shard, require("src/bosses/sanctum").items[57128])
end)

-- The generals' uniques can't drop together, so their chances simply add up.
it("gives a general at most one unique per kill", function()
    local zilyana = require("src/bosses/zilyana")
    local rolls = stats.Rolls(zilyana, zilyana.modes[1], {}, BEFORE)
    assert.are.near(1 / 64 + HILT, luck.ChanceOfAny(rolls), 1e-12)
end)

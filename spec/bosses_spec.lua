-- Checks every boss file follows the data format. Run from the project root: busted

local bosses = require("src/bosses")
local choices = require("src/choices")
local luck = require("src/luck")
local stats = require("src/stats")

-- A day before the Late-Game Rebalance (30 Oct 2026), and the day it went live.
local BEFORE, AFTER = 20756, require("src/rates/late_game_rebalance").day

-- Each of a boss's choices at its default: { [choice key] = value }.
local function defaults(boss)
    local picks = {}
    for _, choice in ipairs(boss.choices or {}) do
        picks[choice.key] = choice.default
    end
    return picks
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
            it("names its log page and a KC varbit for each mode", function()
                assert.is_true(startsWith(boss.logPage, "COLLECTION_BOSS_"))
                assert.is_true(#boss.modes > 0)
                for _, mode in ipairs(boss.modes) do
                    assert.is_true(startsWith(mode.kc, "BSLAY_KILLS_"))
                end
            end)

            it("counts a kill count by its kill events only if it has them", function()
                for _, mode in ipairs(boss.modes) do
                    assert.is_true(mode.byEvent == true or mode.rolls ~= nil)
                    assert.is_true(not mode.byEvent or boss.killEvents ~= nil or boss.containers ~= nil)
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
                for _, note in ipairs(choices.Assumptions(boss, defaults(boss))) do
                    assert.are.equal("string", type(note))
                    assert.is_nil(note:find("<", 1, true)) -- the game would read it as a tag
                end
            end)

            it("only rolls unique items", function()
                for _, mode in ipairs(boss.modes) do
                    for _, day in ipairs({ BEFORE, AFTER }) do
                        for itemID in pairs(luck.ItemChances(stats.Rolls(boss, mode, defaults(boss), day))) do
                            assert.are.equal("unique", boss.items[itemID].kind)
                        end
                    end
                end
            end)
        end)
    end
end)

-- Each boss's boss log item count, and its wiki rates per kill for a few items,
-- in its first two modes, or the modes named in modes (made by its kill events),
-- before the Late-Game Rebalance; after and afterHard, the ones it changed.
local HILT = 63 / 64 / 512 -- a general's hilt: only rolled when the unique table misses
local NEX = 1 / 384
local CASES = {
    { file = "graardor", items = 18, rates = { [25022] = 1 / 384, [11704] = HILT },
        after = { [25022] = 1 / 320, [25019] = 1 / 320, [11704] = 1 / 384 } },
    { file = "kreearra", items = 18, rates = { [11718] = 1 / 384, [11702] = HILT },
        after = { [11718] = 1 / 320, [25013] = 1 / 320, [11702] = 1 / 384 } },
    { file = "zilyana", items = 19, rates = { [11730] = 1 / 320, [25037] = 1 / 640, [25034] = 1 / 320, [11706] = HILT },
        after = { [11730] = 1 / 320, [25037] = 1 / 320, [34855] = 1 / 320, [11706] = 1 / 384 } },
    { file = "kril", items = 20, rates = { [24992] = 1 / 512, [11716] = 1 / 512, [11708] = HILT },
        after = { [24992] = 1 / 320, [25001] = 1 / 320, [11716] = 1 / 384, [11736] = 1 / 64, [11708] = 1 / 384 } },
    { file = "nex", items = 21, rates = { [20135] = NEX, [25664] = NEX, [20171] = NEX } },
    { file = "helwyr", items = 8,
        rates = { [37027] = 1 / 256, [40600] = 1 / 256, [37033] = (1 - 6 / 256) / 64 },
        hard = { [37085] = 1 / 179, [37033] = (1 - 6 / 179) / 44 },
        after = { [37027] = 1 / 128, [40600] = 1 / 256, [37033] = (1 - 1 / 128 - 5 / 256) / 64 },
        afterHard = { [37027] = 1 / 128, [37085] = 1 / 179 } },
    { file = "vindicta", items = 8,
        rates = { [37018] = 1 / 255, [37070] = 1 / 255, [37030] = (1 - 5 / 255) / 64 },
        hard = { [37070] = 1 / 179, [37030] = (1 - 5 / 179) / 44 },
        after = { [37018] = 1 / 128, [37070] = 1 / 255 }, afterHard = { [37018] = 1 / 128 } },
    { file = "furies", items = 9, rates = { [37090] = 1 / 256, [37095] = 1 / 256 }, hard = { [37024] = 1 / 179 },
        after = { [37024] = 1 / 128 }, afterHard = { [37024] = 1 / 128 } },
    { file = "gregorovic", items = 8, rates = { [37075] = 1 / 256, [37080] = 1 / 256 }, hard = { [37021] = 1 / 179 },
        after = { [37021] = 1 / 128 }, afterHard = { [37021] = 1 / 128 } },
    -- Normal mode, then the 100% enrage tier: an armor piece, a weapon, the Nexus and the Shard.
    { file = "amascut", items = 11, modes = { "Normal", "Enrage 100%" },
        rates = { [59344] = 3 / 4 / 5 / 600, [59350] = 1 / 4 / 2 / 600, [59358] = 1 / 750 },
        hard = { [59336] = 3 / 4 / 5 / 70, [59354] = 1 / 4 / 2 / 70, [59358] = 1 / 280, [57128] = 1 / 280 } },
    -- Vermyx, then Vermyx in hard mode.
    { file = "sanctum", items = 9, rates = { [57156] = 1 / 250, [57124] = 1 / 250 }, hard = { [57156] = 1 / 200 } },
    -- Solo, then duo: a leg and an add-on, each group split evenly.
    { file = "araxxi", items = 15, modes = { "Solo", "Duo" },
        rates = { [31718] = 1 / 40 / 3, [31723] = 1 / 120 / 3 }, hard = { [31719] = 1 / 70 / 3, [31724] = 1 / 200 / 3 } },
    -- A chest with all seven brothers (7 rolls at 1/73) and Linza (1/96 over
    -- her five items), plus the amulet at 1/480. Dharok has 4 items, Ahrim 6.
    { file = "barrows", items = 39, modes = { "Chest: Ahrim, Dharok, Guthan, Karil, Torag, Verac, Akrisae, Linza" },
        rates = { [4716] = 7 / 73 / 7 / 4, [25652] = 7 / 73 / 7 / 6, [21744] = 7 / 73 / 7 / 4, [37449] = 1 / 96 / 5, [39061] = 1 / 480 },
        after = { [39061] = 1 / 240, [37449] = 1 / 96 / 5 } },
    -- One rare roll per chest: normal, then hard mode.
    { file = "vorkath", items = 5, rates = { [56079] = 1 / 45, [56068] = 1 / 249 },
        hard = { [56079] = 1 / 15, [56068] = 1 / 150, [56321] = 1 / 150 } },
    { file = "rots", items = 10, rates = { [30014] = 1 / 240, [30022] = 1 / 240, [30018] = 1 / 240 } },
    -- Astellarn solo, then in a duo.
    { file = "dragonkin", items = 7, modes = { "Astellarn, solo", "Astellarn, 2 players" },
        rates = { [43391] = 1 / 83 }, hard = { [43391] = 1 / 166 } },
    { file = "corp", items = 7, rates = { [13752] = 1 / 1024, [13748] = 1 / 1024, [13754] = 3 / 512 } },
    -- Solo, then duo: the same rates.
    { file = "raksha", items = 6, rates = { [51082] = 1 / 130, [51086] = 1 / 325, [51098] = 1 / 325 },
        hard = { [51082] = 1 / 130, [51094] = 1 / 325 } },
    -- Every unique is 1/640: a 1/320 weapon roll and a 1/128 armor roll.
    { file = "rasial", items = 8,
        rates = { [55480] = 1 / 640, [55482] = 1 / 640, [55488] = 1 / 640, [55496] = 1 / 640 } },
    { file = "solak", items = 7,
        rates = { [42785] = 1 / 200, [42770] = 1 / 400, [42774] = 1 / 400, [42767] = 1 / 500, [42782] = 1 / 500 },
        after = { [42785] = 1 / 200, [42770] = 1 / 200, [42774] = 1 / 200, [42767] = 1 / 500 } },
    -- Full contribution: 12 rolls at 1/5,400 each, then 1/3,000 armor and 1/2,500 others.
    { file = "croesus", items = 10, rates = { [52250] = 12 / 5400, [52345] = 12 / 5400 },
        after = { [52250] = 12 / 3000, [52345] = 12 / 2500, [52213] = 12 / 2500 } },
    -- Three loot piles, the default.
    { file = "kerapac", items = 7, rates = { [51767] = 1 / 256, [51843] = 1 / 256 },
        hard = { [51782] = 1 / 400, [51812] = 399 / 400 / 180 } },
    -- Hard mode before the stones are read: 1/27 for any sword piece.
    { file = "zuk", items = 7, rates = { [52530] = 1 / 100, [52492] = 1 / 100 },
        hard = { [52505] = 1 / 27 / 3, [52530] = 1 / 50, [52492] = 1 / 50 } },
}

-- A boss's mode by name: one of its own, or one its kill events make.
local function modeNamed(boss, name)
    for _, mode in ipairs(boss.modes) do
        if mode.name == name then
            return mode
        end
    end
    return boss.modeFor(name)
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

        -- Checks each mode's chances on day against expected, { rates, hard rates }.
        local function check(day, expected)
            for modeIndex, rates in pairs(expected) do
                local mode = case.modes and modeNamed(boss, case.modes[modeIndex]) or boss.modes[modeIndex]
                local chances = luck.ItemChances(stats.Rolls(boss, mode, defaults(boss), day))
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
    assert.are.equal("Solo", event.mode({ duo = 0 }))
    assert.are.equal("Duo", event.mode({ duo = 1 }))
    local duo = luck.ItemChances(stats.Rolls(boss, boss.modeFor("Duo"), {}))
    assert.are.near(1 / 70 / 3, duo[31718], 1e-12)
    assert.are.near(1 / 120 / 3, luck.ItemChances(stats.Rolls(boss, boss.modeFor("Solo"), {}))[31722], 1e-12)
    assert.are.equal("BSLAY_KILLS_ARAXXI", boss.modeFor("Duo").kc)
end)

it("scales Kerapac's loot piles by the player's average", function()
    local boss = require("src/bosses/kerapac")
    local picks = { normalPiles = 1.5, hardPiles = 1 }
    assert.are.near(1.5 / 256 / 3, luck.ItemChances(stats.Rolls(boss, boss.modes[1], picks))[51767], 1e-12)
    assert.are.near(1 / 400 / 3, luck.ItemChances(stats.Rolls(boss, boss.modes[2], picks))[51782], 1e-12)
    assert.are.same({ "Normal Mode loot piles per kill: 1.5", "Hard Mode loot piles per kill: 1" },
        choices.Assumptions(boss, picks))
end)

describe("TzKal-Zuk's checkpoints", function()
    local boss = require("src/bosses/zuk")
    local function pieceChance(stones, normalKills, hardKills)
        local picks = { stones = stones, normalKills = normalKills, hardKills = hardKills }
        return luck.ItemChances(stats.Rolls(boss, boss.modes[2], picks))[52505] * 3
    end

    it("takes the share of runs without checkpoints from the Igneous stones", function()
        assert.are.near(1 / 27, pieceChance(107, 8, 99), 1e-12)
        assert.are.near(1 / 30, pieceChance(0, 8, 99), 1e-12)
        assert.are.near(0.5 / 27 + 0.5 / 30, pieceChance(50, 0, 100), 1e-12)
    end)

    it("only assumes how checkpoints split between modes when the stones can't tell", function()
        local function notes(stones, normalKills, hardKills)
            return #choices.Assumptions(boss, { stones = stones, normalKills = normalKills, hardKills = hardKills })
        end
        assert.are.equal(0, notes(107, 8, 99)) -- every run without checkpoints
        assert.are.equal(0, notes(0, 8, 99)) -- every run with them
        assert.are.equal(0, notes(50, 0, 100)) -- hard mode only
        assert.are.equal(1, notes(60, 8, 99))
    end)
end)

it("counts each tracked Dragonkin Laboratory group kill by the players at the kill", function()
    local boss = require("src/bosses/dragonkin")
    local event = boss.killEvents[3] -- the Black stone dragon's
    assert.are.equal("BSLAY_KILLS_DUNGEON_DRAGONFORT3", event.var)
    assert.is_nil(event.mode({ players = 0 })) -- not read yet: left uncounted
    assert.are.equal("Black stone dragon, 1 player", event.mode({ players = 1 }))
    assert.are.equal("Black stone dragon, 3 players", event.mode({ players = 4 }))
    local mode = boss.modeFor(event.mode({ players = 2 }))
    assert.are.equal("Black stone dragon, 2 players", mode.name)
    assert.are.equal("BSLAY_KILLS_DUNGEON_DRAGONFORT3", mode.kc)
    assert.are.near(1 / 166, luck.ItemChances(stats.Rolls(boss, mode, {}))[43393], 1e-12)
end)

describe("Barrows", function()
    local boss = require("src/bosses/barrows")
    local SIX = { "Ahrim", "Dharok", "Guthan", "Karil", "Torag", "Verac" }

    -- The tracked chest's mode name from the game's values as it's looted, for
    -- these originals, Akrisae and Linza.
    local function opened(originals, akrisae, linza)
        local values = { Ahrim = 0, Dharok = 0, Guthan = 0, Karil = 0, Torag = 0, Verac = 0 }
        for _, name in ipairs(originals) do
            values[name] = 1
        end
        values.linzaKilled = linza and 1 or 0
        values.killedCount = #originals + (akrisae and 1 or 0) + values.linzaKilled
        return boss.killEvents[1].mode(values)
    end

    it("names a tracked chest by the brothers killed, Akrisae from the count", function()
        assert.are.equal("Chest: Ahrim, Dharok, Guthan, Karil, Torag, Verac, Akrisae, Linza", opened(SIX, true, true))
        assert.are.equal("Chest: Ahrim, Dharok, Guthan, Karil, Torag, Verac, Linza", opened(SIX, false, true))
        assert.are.equal("Chest: Ahrim, Dharok, Guthan, Karil, Torag, Verac, Akrisae", opened(SIX, true, false))
        assert.are.equal("Chest: Ahrim, Dharok, Guthan", opened({ "Ahrim", "Dharok", "Guthan" }, false, false))
    end)

    it("gives a full chest the kill count and a partial one only its brothers' items", function()
        local full = boss.modeFor(opened(SIX, true, true))
        assert.are.equal("BSLAY_KILLS_BARROWS", full.kc)
        local chances = luck.ItemChances(stats.Rolls(boss, full, {}, BEFORE))
        assert.are.near(7 / 73 / 7 / 4, chances[4716], 1e-12)
        assert.are.near(1 / 96 / 5, chances[37449], 1e-12)

        -- Five originals and Akrisae make six: in the kill count too.
        local fiveAndAkrisae = opened({ "Dharok", "Guthan", "Karil", "Torag", "Verac" }, true, false)
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

it("counts each tracked Amascut enrage kill at the tier of its enrage", function()
    local boss = require("src/bosses/amascut")
    local event = boss.killEvents[1]
    assert.are.equal("BSLAY_KILLS_AMASCUT_BOSS_HARDMODE", event.var)
    assert.are.equal("Enrage 100%", event.mode({ enrage = 50 }))
    assert.are.equal("Enrage 500%", event.mode({ enrage = 749 }))
    assert.are.equal("Enrage 2,000%+", event.mode({ enrage = 4000 }))
    assert.are.equal("BSLAY_KILLS_AMASCUT_BOSS_HARDMODE", boss.modeFor("Enrage 750%").kc)
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

-- Checks every boss file follows the data format. Run from the project root: busted

local bosses = require("src/bosses")
local choices = require("src/choices")
local stats = require("src/stats")

-- Each of a boss's choices at its default: { [choice key] = value }.
local function defaults(boss)
    local picks = {}
    for _, choice in ipairs(boss.choices or {}) do
        picks[choice.key] = choice.default
    end
    return picks
end
local luck = require("src/luck")

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

            it("has a mode for every option of a choice its modes are tiers of", function()
                for _, mode in ipairs(boss.modes) do
                    local choice = mode.tier and choices.Find(boss, mode.tier.choice)
                    for _, option in ipairs(choice and choice.options or {}) do
                        local found = false
                        for _, other in ipairs(boss.modes) do
                            found = found or (other.tier ~= nil and other.tier.choice == choice.key
                                and other.tier.value == option.value)
                        end
                        assert.is_true(found)
                    end
                end
            end)

            it("only rolls unique items", function()
                for _, mode in ipairs(boss.modes) do
                    for itemID in pairs(luck.ItemChances(stats.Rolls(mode, defaults(boss)))) do
                        assert.are.equal("unique", boss.items[itemID].kind)
                    end
                end
            end)
        end)
    end
end)

-- Each boss's boss log item count, and its wiki rates per kill for a few items.
local HILT = 63 / 64 / 512 -- a general's hilt: only rolled when the unique table misses
local NEX = 1 / 384
local CASES = {
    { file = "graardor", items = 18, rates = { [25022] = 1 / 384, [11704] = HILT } },
    { file = "kreearra", items = 18, rates = { [11718] = 1 / 384, [11702] = HILT } },
    { file = "zilyana", items = 19, rates = { [11730] = 1 / 320, [25037] = 1 / 640, [25034] = 1 / 320, [11706] = HILT } },
    { file = "kril", items = 20, rates = { [24992] = 1 / 512, [11716] = 1 / 512, [11708] = HILT } },
    { file = "nex", items = 21, rates = { [20135] = NEX, [25664] = NEX, [20171] = NEX } },
    { file = "helwyr", items = 8,
        rates = { [37027] = 1 / 256, [40600] = 1 / 256, [37033] = (1 - 6 / 256) / 64 },
        hard = { [37085] = 1 / 179, [37033] = (1 - 6 / 179) / 44 } },
    { file = "vindicta", items = 8,
        rates = { [37018] = 1 / 255, [37070] = 1 / 255, [37030] = (1 - 5 / 255) / 64 },
        hard = { [37070] = 1 / 179, [37030] = (1 - 5 / 179) / 44 } },
    { file = "furies", items = 9, rates = { [37090] = 1 / 256, [37095] = 1 / 256 }, hard = { [37024] = 1 / 179 } },
    { file = "gregorovic", items = 8, rates = { [37075] = 1 / 256, [37080] = 1 / 256 }, hard = { [37021] = 1 / 179 } },
    -- Normal mode, then the 100% enrage tier: an armor piece, a weapon, the Nexus and the Shard.
    { file = "amascut", items = 11,
        rates = { [59344] = 3 / 4 / 5 / 600, [59350] = 1 / 4 / 2 / 600, [59358] = 1 / 750 },
        hard = { [59336] = 3 / 4 / 5 / 70, [59354] = 1 / 4 / 2 / 70, [59358] = 1 / 280, [57128] = 1 / 280 } },
    -- Vermyx, then Vermyx in hard mode.
    { file = "sanctum", items = 9, rates = { [57156] = 1 / 250, [57124] = 1 / 250 }, hard = { [57156] = 1 / 200 } },
    -- Solo, the default: a leg and an add-on, each group split evenly.
    { file = "araxxi", items = 15, rates = { [31718] = 1 / 40 / 3, [31723] = 1 / 120 / 3 } },
    -- The defaults: every chest with all seven brothers (7 rolls at 1/73) and
    -- Linza (1/96 over her five items). Dharok has 4 items, Ahrim 6.
    { file = "barrows", items = 39,
        rates = { [4716] = 7 / 73 / 7 / 4, [25652] = 7 / 73 / 7 / 6, [21744] = 7 / 73 / 7 / 4, [37449] = 1 / 96 / 5 } },
    { file = "rots", items = 10, rates = { [30014] = 1 / 240, [30022] = 1 / 240, [30018] = 1 / 240 } },
    -- Astellarn solo, then in a group, by default duo.
    { file = "dragonkin", items = 7, rates = { [43391] = 1 / 83 }, hard = { [43391] = 1 / 166 } },
    -- Before the game is read: every kill at today's rates.
    { file = "corp", items = 7, rates = { [13752] = 1 / 1024, [13748] = 1 / 1024, [13754] = 3 / 512 } },
    -- Solo, then duo: the same rates.
    { file = "raksha", items = 6, rates = { [51082] = 1 / 130, [51086] = 1 / 325, [51098] = 1 / 325 },
        hard = { [51082] = 1 / 130, [51094] = 1 / 325 } },
    -- Every unique is 1/640: a 1/320 weapon roll and a 1/128 armor roll.
    { file = "rasial", items = 8,
        rates = { [55480] = 1 / 640, [55482] = 1 / 640, [55488] = 1 / 640, [55496] = 1 / 640 } },
    { file = "solak", items = 7,
        rates = { [42785] = 1 / 200, [42770] = 1 / 400, [42774] = 1 / 400, [42767] = 1 / 500, [42782] = 1 / 500 } },
    -- Full contribution: 12 rolls at 1/5,400 each.
    { file = "croesus", items = 10, rates = { [52250] = 12 / 5400, [52345] = 12 / 5400 } },
    -- Solo, the default: three loot piles.
    { file = "kerapac", items = 7, rates = { [51767] = 1 / 256, [51843] = 1 / 256 },
        hard = { [51782] = 1 / 400, [51812] = 399 / 400 / 180 } },
    -- Hard mode before the stones are read: 1/27 for any sword piece.
    { file = "zuk", items = 7, rates = { [52530] = 1 / 100, [52492] = 1 / 100 },
        hard = { [52505] = 1 / 27 / 3, [52530] = 1 / 50, [52492] = 1 / 50 } },
}

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

        it("has the wiki rates", function()
            for modeIndex, rates in ipairs({ case.rates, case.hard }) do
                local chances = luck.ItemChances(stats.Rolls(boss.modes[modeIndex], defaults(boss)))
                for itemID, rate in pairs(rates) do
                    assert.are.near(rate, chances[itemID], 1e-12)
                end
            end
        end)
    end)
end

it("mixes Araxxi's solo and duo rates by the share of duo kills", function()
    local mode = require("src/bosses/araxxi").modes[1]
    local chances = luck.ItemChances(stats.Rolls(mode, { duo = 25 }))
    assert.are.near((0.75 / 40 + 0.25 / 70) / 3, chances[31718], 1e-12)
    assert.are.near((0.75 / 120 + 0.25 / 200) / 3, chances[31722], 1e-12)
end)

it("scales Kerapac's loot piles by the player's team", function()
    local modes = require("src/bosses/kerapac").modes
    local picks = { normalTeam = "duo", hardTeam = "trio" }
    assert.are.near(1.5 / 256 / 3, luck.ItemChances(stats.Rolls(modes[1], picks))[51767], 1e-12)
    assert.are.near(1 / 400 / 3, luck.ItemChances(stats.Rolls(modes[2], picks))[51782], 1e-12)
end)

it("only assumes Kerapac's duo damage when a pick has duo kills", function()
    local boss = require("src/bosses/kerapac")
    assert.are.same({ "Normal mode kills done: Solo", "Hard mode kills done: Trio" },
        choices.Assumptions(boss, { normalTeam = "solo", hardTeam = "trio" }))
    assert.are.same({ "Top damage on half of duo kills", "Normal mode kills done: Half solo, half duo",
        "Hard mode kills done: Solo" }, choices.Assumptions(boss, { normalTeam = "soloDuo", hardTeam = "solo" }))
end)

describe("TzKal-Zuk's checkpoints", function()
    local boss = require("src/bosses/zuk")
    local function pieceChance(stones, normalKills, hardKills)
        local picks = { stones = stones, normalKills = normalKills, hardKills = hardKills }
        return luck.ItemChances(stats.Rolls(boss.modes[2], picks))[52505] * 3
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

it("mixes the Dragonkin Laboratory's group rates by the player's pick", function()
    local boss = require("src/bosses/dragonkin")
    local chances = luck.ItemChances(stats.Rolls(boss.modes[6], { group = "duoTrio" }))
    assert.are.near(1 / 166 / 2 + 1 / 250 / 2, chances[43393], 1e-12)
    assert.are.equal("BSLAY_KILLS_DUNGEON_DRAGONFORT3", boss.modes[6].kc)
end)

it("mixes the Corporeal Beast's old and new sigil rates for untracked kills", function()
    local mode = require("src/bosses/corp").modes[1]
    -- Half of all kills untracked, half of those before the change: a quarter old.
    local chances = luck.ItemChances(stats.Rolls(mode, { before = 50, untracked = 0.5 }))
    assert.are.near(0.25 / 1280 + 0.75 / 1024, chances[13752], 1e-12)
    assert.are.near(0.25 / 2560 + 0.75 / 1024, chances[13746], 1e-12)
end)

it("says the Corporeal Beast's pick in full in the assumptions, with the kills it's for", function()
    local boss = require("src/bosses/corp")
    assert.are.equal("Of your kills without Boss RNG, share before the July 2026 sigil rate change: 70%",
        choices.Assumptions(boss, { before = 70 })[2])
    assert.are.equal("Of your 5,000 kills without Boss RNG, share before the July 2026 sigil rate change: 70%",
        choices.Assumptions(boss, { before = 70, untrackedKills = 5000 })[2])
end)

it("mixes Raksha's old and new rates for untracked kills, solo and duo alike", function()
    local boss = require("src/bosses/raksha")
    -- Half of all kills untracked, all of those before the change: half old.
    local picks = { before = 100, untracked = 0.5 }
    for _, mode in ipairs(boss.modes) do
        local chances = luck.ItemChances(stats.Rolls(mode, picks))
        assert.are.near(0.5 / 230 + 0.5 / 130, chances[51082], 1e-12)
        assert.are.near(0.5 / 575 + 0.5 / 325, chances[51086], 1e-12)
    end
    assert.are.same({ "Kills prior to July 2025 drop table change: 100%" }, choices.Assumptions(boss, { before = 100 }))
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
        return boss.killEvent.mode(values)
    end

    it("mixes chests without Boss RNG by the player's shares", function()
        local chances = luck.ItemChances(stats.Rolls(boss.modes[1], { akrisae = 0, linza = 0, linzaBefore = 0 }))
        assert.are.near(7 / 102 / 6 / 4, chances[4716], 1e-12) -- six brothers: 7 rolls at 1/102
        assert.is_nil(chances[21744]) -- no Akrisae
        assert.is_nil(chances[37449]) -- no Linza
    end)

    it("rolls Linza at 1/192 for the share of chests before July 2026", function()
        local function linza(before)
            local picks = { akrisae = 100, linza = 100, linzaBefore = before }
            return luck.ItemChances(stats.Rolls(boss.modes[1], picks))[37449]
        end
        assert.are.near(1 / 96 / 5, linza(0), 1e-12)
        assert.are.near(1 / 192 / 5, linza(100), 1e-12)
        assert.are.near((1 / 192 + 1 / 96) / 2 / 5, linza(50), 1e-12)
    end)

    it("names a tracked chest by the brothers killed, Akrisae from the count", function()
        assert.are.equal("Chest: Ahrim, Dharok, Guthan, Karil, Torag, Verac, Akrisae, Linza", opened(SIX, true, true))
        assert.are.equal("Chest: Ahrim, Dharok, Guthan, Karil, Torag, Verac, Linza", opened(SIX, false, true))
        assert.are.equal("Chest: Ahrim, Dharok, Guthan, Karil, Torag, Verac, Akrisae", opened(SIX, true, false))
        assert.are.equal("Chest: Ahrim, Dharok, Guthan", opened({ "Ahrim", "Dharok", "Guthan" }, false, false))
    end)

    it("gives a full chest the kill count and a partial one only its brothers' items", function()
        local full = boss.modeFor(opened(SIX, true, true))
        assert.are.equal("BSLAY_KILLS_BARROWS", full.kc)
        local chances = luck.ItemChances(full.rolls)
        assert.are.near(7 / 73 / 7 / 4, chances[4716], 1e-12)
        assert.are.near(1 / 96 / 5, chances[37449], 1e-12)

        -- Five originals and Akrisae make six: in the kill count too.
        local fiveAndAkrisae = opened({ "Dharok", "Guthan", "Karil", "Torag", "Verac" }, true, false)
        assert.are.equal("BSLAY_KILLS_BARROWS", boss.modeFor(fiveAndAkrisae).kc)

        local partial = boss.modeFor(opened({ "Ahrim", "Dharok", "Guthan" }, false, false))
        assert.is_nil(partial.kc)
        chances = luck.ItemChances(partial.rolls)
        assert.are.near(4 / 276 / 3 / 4, chances[4716], 1e-12) -- 3 brothers: 4 rolls at 1/276
        assert.is_nil(chances[4732]) -- no Karil
        assert.is_nil(chances[37449]) -- no Linza
    end)

    it("only assumes old partial chests aren't counted when there are chests without Boss RNG", function()
        assert.are.equal(3, #choices.Assumptions(boss, { akrisae = 100, linza = 100, linzaBefore = 0 }))
        local notes = choices.Assumptions(boss, { akrisae = 70, linza = 100, linzaBefore = 0, untrackedKills = 280 })
        assert.are.equal("Untracked partial chests not counted", notes[1])
        assert.are.equal("Chests with Akrisae killed: 70%", notes[2])
        assert.are.equal("Chests prior to July 2026 Linza drop rate change: 0%", notes[4])
    end)
end)

-- Nakatra's rolls, normal then hard mode.
describe("sanctum's Nakatra", function()
    local modes = require("src/bosses/sanctum").modes
    it("has the wiki rates", function()
        local normal, hard = luck.ItemChances(modes[5].rolls), luck.ItemChances(modes[6].rolls)
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
    local rolls = require("src/bosses/zilyana").modes[1].rolls
    assert.are.near(1 / 64 + HILT, luck.ChanceOfAny(rolls), 1e-12)
end)

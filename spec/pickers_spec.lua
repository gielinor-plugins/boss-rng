-- Run from the project root with: busted

local pickers = require("src/pickers")

local function entry(file, picks, kills)
    return { boss = require("src/bosses/" .. file), picks = picks, stats = { kills = kills or 0 } }
end

local function noop() end

describe("pickers", function()
    it("puts picks of kills without Boss RNG on the settings page", function()
        local barrows = entry("barrows", { akrisae = 100, linza = 100 })
        assert.are.equal(2, #pickers.ForSettings(barrows, noop))
        assert.are.equal(0, #pickers.ForDetails(barrows, {}, noop, noop))
    end)

    it("says what a boss's picks are used for, with the count once the game is read", function()
        assert.are.equal("Used to calculate luck for your 280 kills without Boss RNG",
            pickers.Purpose(entry("barrows", { untrackedKills = 280 })))
        assert.are.equal("Used to calculate luck for your 1 kill without Boss RNG",
            pickers.Purpose(entry("barrows", { untrackedKills = 1 })))
        assert.are.equal("Used to calculate luck for your kills without Boss RNG",
            pickers.Purpose(entry("barrows", {})))
    end)

    it("keeps the other picks in the Details window", function()
        local kerapac = entry("kerapac", { normalTeam = "solo", hardTeam = "duo" })
        assert.are.equal(0, #pickers.ForSettings(kerapac, noop))
        local list = pickers.ForDetails(kerapac, {}, noop, noop)
        assert.are.equal(2, #list)
        assert.are.equal("duo", list[2].current)
        assert.is_nil(pickers.WhereToChange(kerapac))
    end)

    it("saves a pick through onChoose", function()
        local saved = nil
        local barrows = entry("barrows", { akrisae = 100, linza = 100 })
        pickers.ForSettings(barrows, function(boss, choice, value)
            saved = { boss.key, choice.key, value }
        end)[1].onPick(70)
        assert.are.same({ "barrows", "akrisae", 70 }, saved)
    end)

    it("says where to change settings page picks", function()
        assert.are.equal("Change these in Plugin Hub > Manage > Boss RNG settings",
            pickers.WhereToChange(entry("barrows", { akrisae = 100, linza = 100 })))
    end)

    describe("splits of pooled uniques", function()
        local a = { key = "a", name = "Boss A", items = { [9] = { log = "LOG", kind = "unique", short = "Shard" } } }
        local b = { key = "b", name = "Boss B", items = a.items }
        local function pool(split)
            return { [9] = { sharers = { a, b }, untracked = 8, ask = true, split = split } }
        end

        it("lists each count, then Not set, in the Details window", function()
            local list = pickers.ForDetails({ boss = a, picks = {} }, pool({ a = 3, b = 5 }), noop, noop)
            assert.are.equal("Shard drops without Boss RNG (of 8)", list[1].label)
            assert.are.equal(10, #list[1].options)
            assert.are.equal("Not set", list[1].options[10].label)
            assert.are.equal(3, list[1].current)
        end)

        it("clears a split when Not set is picked", function()
            local got = "unset"
            local list = pickers.ForDetails({ boss = a, picks = {} }, pool(nil), noop, function(_, _, _, count)
                got = count
            end)
            assert.is_false(list[1].current)
            list[1].onPick(false)
            assert.is_nil(got)
        end)
    end)

end)

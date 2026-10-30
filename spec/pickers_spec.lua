-- Run from the project root with: busted

local pickers = require("src/pickers")

local function entry(file, picks, kills)
    return { boss = require("src/bosses/" .. file), picks = picks, stats = { kills = kills or 0 } }
end

local function noop() end

describe("pickers", function()
    it("puts picks of kills without Boss RNG on the settings page", function()
        local barrows = entry("barrows", { akrisae = 100, linza = 100, linzaBefore = 0 })
        assert.are.equal(3, #pickers.ForSettings(barrows, {}, noop, noop))
        assert.are.equal(0, #pickers.ForDetails(barrows, noop))
    end)

    it("counts a boss's untracked kills once the game is read", function()
        assert.are.equal("5,000 untracked kills", pickers.UntrackedKills(entry("corp", { untrackedKills = 5000 })))
        assert.are.equal("1 untracked kill", pickers.UntrackedKills(entry("corp", { untrackedKills = 1 })))
        assert.are.equal("Untracked kills not read yet", pickers.UntrackedKills(entry("corp", {})))
    end)

    it("moves Amascut's enrage and Corp's July 2026 share to the settings page", function()
        assert.are.equal(1, #pickers.ForSettings(entry("amascut", { enrage = 100 }), {}, noop, noop))
        assert.are.equal(0, #pickers.ForDetails(entry("amascut", { enrage = 100 }), noop))
        assert.are.equal(1, #pickers.ForSettings(entry("corp", { before = 100 }), {}, noop, noop))
        assert.are.equal(1, #pickers.ForSettings(entry("raksha", { before = 0 }), {}, noop, noop))
    end)

    it("keeps the other picks in the Details window", function()
        local kerapac = entry("kerapac", { normalTeam = "solo", hardTeam = "duo" })
        assert.are.equal(0, #pickers.ForSettings(kerapac, {}, noop, noop))
        local list = pickers.ForDetails(kerapac, noop)
        assert.are.equal(2, #list)
        assert.are.equal("duo", list[2].current)
        assert.is_nil(pickers.WhereToChange(kerapac, {}))
    end)

    it("saves a pick through onChoose", function()
        local saved = nil
        local barrows = entry("barrows", { akrisae = 100, linza = 100, linzaBefore = 0 })
        pickers.ForSettings(barrows, {}, function(boss, choice, value)
            saved = { boss.key, choice.key, value }
        end, noop)[1].onPick(70)
        assert.are.same({ "barrows", "akrisae", 70 }, saved)
    end)

    it("says where to change settings page picks", function()
        assert.are.equal("Change these in Plugin Hub > Manage > Boss RNG settings",
            pickers.WhereToChange(entry("barrows", { akrisae = 100, linza = 100, linzaBefore = 0 }), {}))
    end)

    describe("splits of pooled uniques", function()
        local a = { key = "a", name = "Boss A", items = { [9] = { log = "LOG", kind = "unique", short = "Shard" } } }
        local b = { key = "b", name = "Boss B", items = a.items }
        local function pool(split)
            return { [9] = { sharers = { a, b }, untracked = 8, ask = true, split = split } }
        end

        it("lists each count, then Not set, on the settings page", function()
            local list = pickers.ForSettings({ boss = a, picks = {} }, pool({ a = 3, b = 5 }), noop, noop)
            assert.are.equal("Shard drops from this boss (of 8)", list[1].label)
            assert.are.equal(10, #list[1].options)
            assert.are.equal("Not set", list[1].options[10].label)
            assert.are.equal(3, list[1].current)
        end)

        it("clears a split when Not set is picked", function()
            local got = "unset"
            local list = pickers.ForSettings({ boss = a, picks = {} }, pool(nil), noop, function(_, _, _, count)
                got = count
            end)
            assert.is_false(list[1].current)
            list[1].onPick(false)
            assert.is_nil(got)
        end)
    end)

end)

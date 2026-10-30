-- Run from the project root with: busted

local pickers = require("src/pickers")

local function entry(file, picks)
    return { boss = require("src/bosses/" .. file), picks = picks }
end

local function noop() end

describe("pickers", function()
    it("lists a dropdown per choice, showing the current pick", function()
        local list = pickers.For(entry("kerapac", { normalTeam = "solo", hardTeam = "duo" }), noop)
        assert.are.equal(2, #list)
        assert.are.equal("Normal mode kills done", list[1].label)
        assert.are.equal("duo", list[2].current)
    end)

    it("lists none for a boss without choices", function()
        assert.are.same({}, pickers.For(entry("corp", {}), noop))
    end)

    it("saves a pick through onChoose", function()
        local saved = nil
        pickers.For(entry("kerapac", { normalTeam = "solo", hardTeam = "solo" }), function(boss, choice, value)
            saved = { boss.key, choice.key, value }
        end)[2].onPick("trio")
        assert.are.same({ "kerapac", "hardTeam", "trio" }, saved)
    end)
end)

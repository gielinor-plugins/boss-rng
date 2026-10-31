-- Run from the project root with: busted

local pickers = require("src/pickers")

local KERAPAC = require("src/bosses/kerapac")

local function noop() end

describe("pickers", function()
    it("lists a slider per choice, showing the current pick", function()
        local list = pickers.For(KERAPAC, { normalPiles = 1.5, hardPiles = 2 }, noop)
        assert.are.equal(2, #list)
        assert.are.equal("Normal Mode", list[1].label)
        assert.are.same({ 1, 3, 0.25, 2 }, { list[2].min, list[2].max, list[2].step, list[2].current })
    end)

    it("says where to change picks only for a boss with choices", function()
        assert.are.equal("Change these in Plugin Hub > Manage > Boss RNG settings", pickers.WhereToChange(KERAPAC))
        assert.is_nil(pickers.WhereToChange(require("src/bosses/corp")))
    end)

    it("lists none for a boss without choices", function()
        assert.are.same({}, pickers.For(require("src/bosses/corp"), {}, noop))
    end)

    it("saves a pick through onChoose", function()
        local saved = nil
        pickers.For(KERAPAC, { normalPiles = 3, hardPiles = 3 }, function(boss, choice, value)
            saved = { boss.key, choice.key, value }
        end)[2].onPick(2.75)
        assert.are.same({ "kerapac", "hardPiles", 2.75 }, saved)
    end)
end)

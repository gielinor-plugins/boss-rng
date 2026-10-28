-- Run from the project root with: busted

local mock = require("spec/mock_api")

local ENRAGE = {
    key = "enrage",
    label = "Enrage of kills without Boss RNG",
    default = 100,
    options = { { value = 100, label = "100%" }, { value = 500, label = "500%" } },
}
local BOSS = { key = "testboss", choices = { ENRAGE } }

describe("choices", function()
    local choices

    -- Loads a fresh copy, like a plugin reload.
    local function reload()
        package.loaded["src/choices"] = nil
        choices = require("src/choices")
    end

    before_each(function()
        mock.Reset()
        mock.inGame = true
        reload()
    end)

    it("finds a choice, and the option a game value falls in", function()
        assert.are.equal(ENRAGE, choices.Find(BOSS, "enrage"))
        assert.is_nil(choices.Find(BOSS, "other"))
        assert.are.equal(100, choices.Snap(ENRAGE, 50))
        assert.are.equal(100, choices.Snap(ENRAGE, 499))
        assert.are.equal(500, choices.Snap(ENRAGE, 500))
        assert.are.equal(500, choices.Snap(ENRAGE, 4000))
    end)

    it("uses each choice's default until the player picks", function()
        assert.are.same({ enrage = 100 }, choices.For(BOSS))
        assert.are.same({}, choices.For({ key = "plain" }))
    end)

    it("saves picks per character, apart from the tallies", function()
        choices.Set(BOSS, ENRAGE, 500)
        assert.are.same({ enrage = 500 }, mock.Saved("choices:Tester").bosses.testboss)
        mock.Reset(true)
        mock.inGame = true
        reload()
        assert.are.same({ enrage = 500 }, choices.For(BOSS))
        mock.characterName = "Other"
        assert.are.same({ enrage = 100 }, choices.For(BOSS))
    end)

    it("ignores a saved pick that's no longer an option", function()
        choices.Set(BOSS, ENRAGE, 750)
        assert.are.same({ enrage = 100 }, choices.For(BOSS))
    end)

    it("saves and clears splits of pooled uniques", function()
        assert.are.same({}, choices.Splits())
        choices.SetSplit(57128, { amascut = 6, sanctum = 2 })
        assert.are.same({ ["57128"] = { amascut = 6, sanctum = 2 } }, mock.Saved("choices:Tester").splits)
        choices.SetSplit(57128, nil)
        assert.are.same({}, choices.Splits())
    end)

    it("uses defaults and saves nothing while logged out", function()
        mock.inGame = false
        choices.Set(BOSS, ENRAGE, 500)
        assert.are.same({ enrage = 100 }, choices.For(BOSS))
        assert.is_nil(mock.Saved("choices:Tester"))
    end)
end)

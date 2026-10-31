-- Run from the project root with: busted

local mock = require("spec/mock_api")

local PILES = { key = "piles", label = "Normal Mode", unit = " loot piles per kill", default = 1.5, min = 1, max = 3, step = 0.1 }
local BOSS = { key = "testboss", assumptions = { "One drop per kill" }, choices = { PILES } }

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

    it("uses each choice's default until the player picks", function()
        assert.are.same({ piles = 1.5 }, choices.For(BOSS))
        assert.are.same({}, choices.For({ key = "plain" }))
    end)

    it("saves picks per character, apart from the tallies", function()
        choices.Set(BOSS, PILES, 2.4)
        assert.are.same({ piles = 2.4 }, mock.Saved("choices:Tester").bosses.testboss)
        mock.Reset(true)
        mock.inGame = true
        reload()
        assert.are.same({ piles = 2.4 }, choices.For(BOSS))
        mock.characterName = "Other"
        assert.are.same({ piles = 1.5 }, choices.For(BOSS))
    end)

    it("ignores a saved pick the slider can't show", function()
        for _, value in ipairs({ 0.5, 3.5, 2.45, "solo" }) do
            choices.Set(BOSS, PILES, value)
            assert.are.same({ piles = 1.5 }, choices.For(BOSS))
        end
        choices.Set(BOSS, PILES, 3)
        assert.are.same({ piles = 3 }, choices.For(BOSS))
    end)

    it("states the boss's assumptions, then each pick, in full", function()
        choices.Set(BOSS, PILES, 2.4)
        assert.are.same({ "One drop per kill", "Normal Mode loot piles per kill: 2.4" },
            choices.Assumptions(BOSS, choices.For(BOSS)))
    end)

    it("uses defaults and saves nothing while logged out", function()
        mock.inGame = false
        choices.Set(BOSS, PILES, 2.4)
        assert.are.same({ piles = 1.5 }, choices.For(BOSS))
        assert.is_nil(mock.Saved("choices:Tester"))
    end)
end)

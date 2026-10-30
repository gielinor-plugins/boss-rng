-- Run from the project root with: busted

local mock = require("spec/mock_api")

local TEAM = {
    key = "team",
    label = "Kills done",
    default = "solo",
    options = { { value = "solo", label = "Solo" }, { value = "soloDuo", label = "Solo/duo", note = "Half solo, half duo" } },
}
local BOSS = { key = "testboss", assumptions = { "One pile per kill" }, choices = { TEAM } }

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
        assert.are.same({ team = "solo" }, choices.For(BOSS))
        assert.are.same({}, choices.For({ key = "plain" }))
    end)

    it("saves picks per character, apart from the tallies", function()
        choices.Set(BOSS, TEAM, "soloDuo")
        assert.are.same({ team = "soloDuo" }, mock.Saved("choices:Tester").bosses.testboss)
        mock.Reset(true)
        mock.inGame = true
        reload()
        assert.are.same({ team = "soloDuo" }, choices.For(BOSS))
        mock.characterName = "Other"
        assert.are.same({ team = "solo" }, choices.For(BOSS))
    end)

    it("ignores a saved pick that's no longer an option", function()
        choices.Set(BOSS, TEAM, "trio")
        assert.are.same({ team = "solo" }, choices.For(BOSS))
    end)

    it("states the boss's assumptions, then each pick, in full", function()
        choices.Set(BOSS, TEAM, "soloDuo")
        assert.are.same({ "One pile per kill", "Kills done: Half solo, half duo" },
            choices.Assumptions(BOSS, choices.For(BOSS)))
    end)

    it("uses defaults and saves nothing while logged out", function()
        mock.inGame = false
        choices.Set(BOSS, TEAM, "soloDuo")
        assert.are.same({ team = "solo" }, choices.For(BOSS))
        assert.is_nil(mock.Saved("choices:Tester"))
    end)
end)

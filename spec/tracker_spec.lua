-- Run from the project root with: busted

local mock = require("spec/mock_api")

local NORMAL, HARD = { name = "Normal", kc = "KC_NORMAL" }, { name = "Hard mode", kc = "KC_HARD" }
local BOSS = {
    key = "testboss",
    modes = { NORMAL, HARD },
    items = { [101] = { kind = "unique" }, [102] = { kind = "unique", pooledBy = {} }, [103] = { kind = "pet" } },
}
local DAY, NEXT_DAY = 20756, 20757

describe("tracker", function()
    local tracker

    -- Loads a fresh copy of the tracker, like a plugin reload.
    local function reload()
        package.loaded["src/tracker"] = nil
        tracker = require("src/tracker")
    end

    before_each(function()
        mock.Reset()
        mock.inGame = true
        reload()
    end)

    it("adds kills per mode and day, and saves them for the character", function()
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        tracker.AddKills(BOSS, NORMAL, 1, NEXT_DAY)
        tracker.AddKills(BOSS, HARD, 2, DAY)
        local tallies = mock.Saved("char:Tester").bosses.testboss
        assert.are.same({ Normal = { ["20756"] = 1, ["20757"] = 1 }, ["Hard mode"] = { ["20756"] = 2 } }, tallies.kills)
        assert.are.equal(4, tracker.Total(tallies.kills))
    end)

    it("counts a dry streak for the boss and for each unique", function()
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        local dry = tracker.Tallies(BOSS).dry
        assert.are.same({ any = true, ["101"] = true, ["102"] = true }, tracker.DryKeys(BOSS))
        for key in pairs(tracker.DryKeys(BOSS)) do
            assert.are.same({ Normal = { ["20756"] = 1 } }, dry[key])
        end
        assert.is_nil(dry["103"]) -- pets aren't counted
    end)

    it("ends the boss's dry streak and the item's at a drop", function()
        tracker.AddKills(BOSS, NORMAL, 2, DAY)
        tracker.AddDrops(BOSS, 101, 1)
        tracker.AddKills(BOSS, HARD, 1, NEXT_DAY)
        local tallies = tracker.Tallies(BOSS)
        assert.are.equal(1, tallies.items["101"])
        assert.are.same({ ["Hard mode"] = { ["20757"] = 1 } }, tallies.dry.any)
        assert.are.same({ ["Hard mode"] = { ["20757"] = 1 } }, tallies.dry["101"])
        assert.are.equal(3, tracker.Total(tallies.dry["102"])) -- still dry
    end)

    it("tracks a pooled unique only for the boss killed last", function()
        local other = { key = "other", modes = { NORMAL }, items = BOSS.items }
        tracker.AddKills(other, NORMAL, 1, DAY)
        tracker.AddDrops(BOSS, 102, 1)
        assert.is_nil(tracker.Tallies(BOSS).items["102"])
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        tracker.AddDrops(BOSS, 102, 1)
        assert.are.equal(1, tracker.Tallies(BOSS).items["102"])
        assert.are.same({}, tracker.Tallies(BOSS).dry.any)
    end)

    it("remembers the last boss killed", function()
        assert.is_nil(tracker.LastBossKey())
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        assert.are.equal("testboss", tracker.LastBossKey())
    end)

    it("keeps its data after a reload", function()
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        mock.Reset(true)
        mock.inGame = true
        reload()
        assert.are.equal(1, tracker.Total(tracker.Tallies(BOSS).kills))
    end)

    it("keeps characters separate", function()
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        mock.characterName = "Other"
        assert.are.same({ kills = {}, dry = {}, items = {} }, tracker.Tallies(BOSS))
        tracker.AddKills(BOSS, NORMAL, 5, DAY)
        mock.characterName = "Tester"
        assert.are.equal(1, tracker.Total(tracker.Tallies(BOSS).kills))
    end)

    it("ignores reports while nobody is logged in", function()
        mock.inGame = false
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        assert.is_nil(mock.Saved("char:Tester"))
    end)

    it("keeps saving and telling other listeners when one fails", function()
        local calls = 0
        tracker.OnChange(function() error("broken listener") end)
        tracker.OnChange(function() calls = calls + 1 end)
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        assert.are.equal(1, calls)
        assert.are.equal(1, mock.Saved("char:Tester").bosses.testboss.kills.Normal["20756"])
    end)

    it("tells listeners about each change", function()
        local calls = 0
        tracker.OnChange(function() calls = calls + 1 end)
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        tracker.AddDrops(BOSS, 101, 1)
        assert.are.equal(2, calls)
    end)
end)

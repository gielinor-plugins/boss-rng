-- Run from the project root with: busted

local mock = require("spec/mock_api")

local NORMAL, HARD = { name = "Normal", kc = "KC_NORMAL" }, { name = "Hard mode", kc = "KC_HARD" }
local BOSS = {
    key = "testboss",
    modes = { NORMAL, HARD },
    items = { [101] = { kind = "unique" }, [102] = { kind = "unique", pooledBy = {} } },
}

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

    it("adds kills per mode and saves them for the character", function()
        tracker.AddKills(BOSS, NORMAL, 1)
        tracker.AddKills(BOSS, NORMAL, 1)
        tracker.AddKills(BOSS, HARD, 1)
        local tallies = mock.Saved("char:Tester").bosses.testboss
        assert.are.same({ Normal = 2, ["Hard mode"] = 1 }, tallies.kills)
        assert.are.equal(3, tracker.Total(tallies.kills))
    end)

    it("records each drop at the current kill count", function()
        tracker.AddKills(BOSS, NORMAL, 1)
        tracker.AddKills(BOSS, NORMAL, 1)
        tracker.AddDrops(BOSS, 101, 1)
        tracker.AddKills(BOSS, NORMAL, 1)
        assert.are.same({ count = 1, atKills = { Normal = 2 } }, tracker.Tallies(BOSS).items["101"])
    end)

    it("counts dry kills per mode until a unique drops", function()
        tracker.AddKills(BOSS, NORMAL, 1)
        tracker.AddKills(BOSS, HARD, 1)
        assert.are.same({ Normal = 1, ["Hard mode"] = 1 }, tracker.Tallies(BOSS).dry)
        tracker.AddDrops(BOSS, 101, 1)
        tracker.AddKills(BOSS, HARD, 1)
        assert.are.same({ ["Hard mode"] = 1 }, tracker.Tallies(BOSS).dry)
    end)

    it("tracks a pooled unique only for the boss killed last", function()
        local other = { key = "other", modes = { NORMAL }, items = BOSS.items }
        tracker.AddKills(other, NORMAL, 1)
        tracker.AddDrops(BOSS, 102, 1)
        assert.is_nil(tracker.Tallies(BOSS).items["102"])
        tracker.AddKills(BOSS, NORMAL, 1)
        tracker.AddDrops(BOSS, 102, 1)
        assert.are.equal(1, tracker.Tallies(BOSS).items["102"].count)
        assert.are.same({}, tracker.Tallies(BOSS).dry)
    end)

    it("remembers the last boss killed", function()
        assert.is_nil(tracker.LastBossKey())
        tracker.AddKills(BOSS, NORMAL, 1)
        assert.are.equal("testboss", tracker.LastBossKey())
    end)

    it("keeps its data after a reload", function()
        tracker.AddKills(BOSS, NORMAL, 1)
        mock.Reset(true)
        mock.inGame = true
        reload()
        assert.are.equal(1, tracker.Total(tracker.Tallies(BOSS).kills))
    end)

    it("keeps characters separate", function()
        tracker.AddKills(BOSS, NORMAL, 1)
        mock.characterName = "Other"
        assert.are.same({ kills = {}, dry = {}, items = {} }, tracker.Tallies(BOSS))
        tracker.AddKills(BOSS, NORMAL, 5)
        mock.characterName = "Tester"
        assert.are.equal(1, tracker.Total(tracker.Tallies(BOSS).kills))
    end)

    it("ignores reports while nobody is logged in", function()
        mock.inGame = false
        tracker.AddKills(BOSS, NORMAL, 1)
        assert.is_nil(mock.Saved("char:Tester"))
    end)

    it("keeps saving and telling other listeners when one fails", function()
        local calls = 0
        tracker.OnChange(function() error("broken listener") end)
        tracker.OnChange(function() calls = calls + 1 end)
        tracker.AddKills(BOSS, NORMAL, 1)
        assert.are.equal(1, calls)
        assert.are.equal(1, mock.Saved("char:Tester").bosses.testboss.kills.Normal)
    end)

    it("tells listeners about each change", function()
        local calls = 0
        tracker.OnChange(function() calls = calls + 1 end)
        tracker.AddKills(BOSS, NORMAL, 1)
        tracker.AddDrops(BOSS, 101, 1)
        assert.are.equal(2, calls)
    end)
end)

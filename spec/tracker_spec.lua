-- Run from the project root with: busted

local mock = require("spec/mock_api")

local BOSS = { key = "testboss" }
local NORMAL, HARD = { name = "Normal" }, { name = "Hard mode" }

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
        assert.are.same({ count = 1, atKill = 2 }, tracker.Tallies(BOSS).items["101"])
    end)

    it("counts dry kills per mode until a unique drops", function()
        tracker.AddKills(BOSS, NORMAL, 1)
        tracker.AddKills(BOSS, HARD, 1)
        assert.are.same({ Normal = 1, ["Hard mode"] = 1 }, tracker.Tallies(BOSS).dry)
        tracker.AddDrops(BOSS, 101, 1)
        tracker.AddKills(BOSS, HARD, 1)
        assert.are.same({ ["Hard mode"] = 1 }, tracker.Tallies(BOSS).dry)
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
        assert.is_nil(tracker.Tallies(BOSS))
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
    describe("all-time totals", function()
        local KILLS, ITEMS = { Normal = 40, ["Hard mode"] = 2 }, { [101] = 3 }

        local function allTime()
            return tracker.AllTime(tracker.Tallies(BOSS))
        end

        it("are known once kills and log counts are both seen", function()
            tracker.SetAllTimeKills(BOSS, KILLS)
            assert.is_nil(allTime())
            tracker.SetAllTimeItems(BOSS, ITEMS)
            assert.are.same({ kills = KILLS, items = { ["101"] = 3 } },
                mock.Saved("char:Tester").bosses.testboss.allTime)
        end)

        it("need both seen in the same session", function()
            tracker.SetAllTimeKills(BOSS, KILLS)
            reload()
            tracker.SetAllTimeItems(BOSS, ITEMS)
            assert.is_nil(allTime())
        end)

        it("treat logging out as a new session", function()
            tracker.Start()
            tracker.SetAllTimeKills(BOSS, KILLS)
            mock.Fire("GameStateChanged", { newState = GameState.LOGINSCREEN })
            tracker.SetAllTimeItems(BOSS, ITEMS)
            assert.is_nil(allTime())
            tracker.Stop()
        end)

        it("go up with tracked kills and drops", function()
            tracker.SetAllTimeKills(BOSS, KILLS)
            tracker.AddKills(BOSS, NORMAL, 1)
            tracker.SetAllTimeItems(BOSS, ITEMS)
            tracker.AddDrops(BOSS, 101, 1)
            tracker.AddKills(BOSS, HARD, 1)
            assert.are.same({ kills = { Normal = 41, ["Hard mode"] = 3 }, items = { ["101"] = 4 } }, allTime())
        end)

        it("stay known while new counts match them", function()
            tracker.SetAllTimeKills(BOSS, KILLS)
            tracker.SetAllTimeItems(BOSS, ITEMS)
            reload()
            tracker.SetAllTimeKills(BOSS, KILLS)
            assert.are.same(KILLS, allTime().kills)
        end)

        it("drop the other kind when counts changed unseen", function()
            tracker.SetAllTimeKills(BOSS, KILLS)
            tracker.SetAllTimeItems(BOSS, ITEMS)
            reload()
            tracker.SetAllTimeKills(BOSS, { Normal = 45, ["Hard mode"] = 2 })
            assert.is_nil(allTime())
            tracker.SetAllTimeItems(BOSS, { [101] = 4 })
            assert.are.same({ kills = { Normal = 45, ["Hard mode"] = 2 }, items = { ["101"] = 4 } }, allTime())
        end)

        it("keep the other kind if it was seen this session", function()
            tracker.SetAllTimeKills(BOSS, KILLS)
            tracker.SetAllTimeItems(BOSS, ITEMS)
            reload()
            tracker.SetAllTimeItems(BOSS, ITEMS) -- still matches
            tracker.SetAllTimeKills(BOSS, { Normal = 45, ["Hard mode"] = 2 }) -- kills while away, no drops
            assert.are.same({ kills = { Normal = 45, ["Hard mode"] = 2 }, items = { ["101"] = 3 } }, allTime())
        end)

        it("save only when something changes", function()
            local calls = 0
            tracker.OnChange(function() calls = calls + 1 end)
            tracker.SetAllTimeKills(BOSS, KILLS)
            tracker.SetAllTimeItems(BOSS, ITEMS)
            tracker.SetAllTimeKills(BOSS, KILLS)
            tracker.SetAllTimeItems(BOSS, ITEMS)
            assert.are.equal(2, calls)
        end)
    end)
end)

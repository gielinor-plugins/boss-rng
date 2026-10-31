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
        local tallies = tracker.Tallies(BOSS)
        assert.are.same({ Normal = { ["20756"] = 1, ["20757"] = 1 }, ["Hard mode"] = { ["20756"] = 2 } }, tallies.kills)
        assert.are.equal(4, tracker.Total(tallies.kills))
        -- Saved as text per mode, days in order.
        local saved = mock.Saved("char:Tester")
        assert.is_nil(saved.bosses.testboss.dryFromFirst)
        assert.are.equal(5, saved.version)
        assert.are.same({ Normal = "20756:1,20757:1", ["Hard mode"] = "20756:2" }, saved.bosses.testboss.kills)
    end)

    it("counts a dry streak for the boss and for each unique", function()
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        local tallies = tracker.Tallies(BOSS)
        assert.are.same({ any = true, ["101"] = true, ["102"] = true }, tracker.DryKeys(BOSS))
        for key in pairs(tracker.DryKeys(BOSS)) do
            assert.are.same({ Normal = { ["20756"] = 1 } }, tracker.Dry(tallies, key))
        end
        assert.is_nil(tallies.dryFrom["103"]) -- pets aren't counted
    end)

    it("ends the boss's dry streak and the item's at a drop", function()
        tracker.AddKills(BOSS, NORMAL, 2, DAY)
        tracker.AddDrops(BOSS, 101, 1)
        tracker.AddKills(BOSS, HARD, 1, NEXT_DAY)
        local tallies = tracker.Tallies(BOSS)
        assert.are.equal(1, tallies.items["101"])
        assert.are.same({ ["Hard mode"] = { ["20757"] = 1 } }, tracker.Dry(tallies, "any"))
        assert.are.same({ ["Hard mode"] = { ["20757"] = 1 } }, tracker.Dry(tallies, "101"))
        assert.are.equal(3, tracker.Total(tracker.Dry(tallies, "102"))) -- still dry
    end)

    it("tracks a pooled unique only for the boss killed last", function()
        local other = { key = "other", modes = { NORMAL }, items = BOSS.items }
        tracker.AddKills(other, NORMAL, 1, DAY)
        tracker.AddDrops(BOSS, 102, 1)
        assert.is_nil(tracker.Tallies(BOSS).items["102"])
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        tracker.AddDrops(BOSS, 102, 1)
        assert.are.equal(1, tracker.Tallies(BOSS).items["102"])
        assert.are.same({}, tracker.Dry(tracker.Tallies(BOSS), "any"))
    end)

    it("remembers the last boss killed", function()
        assert.is_nil(tracker.LastBossKey())
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        assert.are.equal("testboss", tracker.LastBossKey())
    end)

    it("counts a unique added later from the first tracked kill, like its expected drops", function()
        local before = { key = "testboss", modes = BOSS.modes, items = { [101] = { kind = "unique" } } }
        tracker.AddKills(before, NORMAL, 3, DAY)
        tracker.AddKills(BOSS, NORMAL, 2, DAY) -- 102 is new here
        local tallies = tracker.Tallies(BOSS)
        assert.are.equal(5, tracker.Total(tracker.Dry(tallies, "102")))
        assert.are.same({}, tallies.dryFrom) -- nothing saved for streaks from the first kill
    end)

    -- The dry streaks as version 4 counted them, kill by kill, next to the
    -- tracker's, through kills, drops and unreadable days (0).
    it("keeps the same dry streaks as counting every kill", function()
        local counted = {} -- [key] = { [mode] = { [day] = kills } }
        local function count(mode, day, n)
            for key in pairs(tracker.DryKeys(BOSS)) do
                counted[key] = counted[key] or {}
                local byDay = counted[key][mode.name] or {}
                byDay[tostring(day)] = (byDay[tostring(day)] or 0) + n
                counted[key][mode.name] = byDay
            end
        end
        local seed, day = 7, DAY
        local function random(n) -- a small fixed sequence, the same every run
            seed = (seed * 1103515245 + 12345) % 2147483648
            return seed % n
        end
        for _ = 1, 400 do
            local roll = random(20)
            if roll == 0 then
                day = day + 1 + random(3)
            elseif roll == 1 then
                local itemID = random(2) == 0 and 101 or 102
                tracker.AddKills(BOSS, NORMAL, 1, day) -- 102 is pooled: only after a kill of this boss
                count(NORMAL, day, 1)
                tracker.AddDrops(BOSS, itemID, 1)
                counted[tostring(itemID)], counted.any = {}, {}
            else
                local mode = random(2) == 0 and NORMAL or HARD
                local d = random(15) == 0 and 0 or day -- now and then the day can't be read
                local n = 1 + random(2)
                tracker.AddKills(BOSS, mode, n, d)
                count(mode, d, n)
            end
            if random(10) == 0 then -- reload, to go through saving
                mock.Reset(true)
                mock.inGame = true
                reload()
            end
            local tallies = tracker.Tallies(BOSS)
            for key in pairs(tracker.DryKeys(BOSS)) do
                assert.are.same(counted[key] or {}, tracker.Dry(tallies, key))
            end
        end
    end)

    describe("with version 4 data", function()
        local function v4(dry)
            mock.SetSaved("char:Tester", { version = 4, lastBoss = "testboss", bosses = { testboss = {
                kills = { Normal = { ["20756"] = 5, ["20757"] = 4, ["0"] = 2 }, ["Hard mode"] = { ["20757"] = 3 } },
                dry = dry,
                items = { ["101"] = 1 },
            } } })
            reload()
            return tracker.Tallies(BOSS)
        end

        it("keeps every dry streak exactly", function()
            local dry = {
                any = { Normal = { ["20756"] = 5, ["20757"] = 4, ["0"] = 2 }, ["Hard mode"] = { ["20757"] = 3 } }, -- every kill
                ["101"] = { Normal = { ["20757"] = 1, ["0"] = 1 }, ["Hard mode"] = { ["20757"] = 2 } }, -- mid day
                ["102"] = {}, -- a drop after the last kill
            }
            local tallies = v4(dry)
            for key, kills in pairs(dry) do
                assert.are.same(kills, tracker.Dry(tallies, key))
            end
            assert.is_nil(tallies.dryFrom.any) -- every kill: from the first
            assert.is_nil(tallies.dryFrom["101"].dry) -- turned into a start
            assert.are.equal(1, tallies.items["101"])
            assert.are.equal("testboss", tracker.LastBossKey())
        end)

        it("keeps a streak no start can give as counted, and goes on counting it", function()
            local odd = { Normal = { ["20756"] = 1 } } -- kills on a day with none after it
            local tallies = v4({ ["101"] = odd })
            assert.are.same(odd, tracker.Dry(tallies, "101"))
            tracker.AddKills(BOSS, NORMAL, 1, 20758)
            assert.are.same({ Normal = { ["20756"] = 1, ["20758"] = 1 } }, tracker.Dry(tracker.Tallies(BOSS), "101"))
        end)
    end)

    it("starts again from a version older than 4", function()
        mock.SetSaved("char:Tester", { version = 3, bosses = { testboss = { kills = { Normal = 4 } } } })
        reload()
        assert.are.same({ kills = {}, dryFrom = {}, items = {} }, tracker.Tallies(BOSS))
    end)

    it("tells when tallies may have changed: a kill, a drop or another character", function()
        local before = tracker.Changes()
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        local afterKill = tracker.Changes()
        assert.is_true(afterKill ~= before)
        assert.are.equal(afterKill, tracker.Changes()) -- nothing new
        mock.characterName = "Other"
        assert.is_true(tracker.Changes() ~= afterKill)
    end)

    it("saves each boss's latest kills, re-encoding only the one that changed", function()
        local other = { key = "other", modes = { NORMAL }, items = {} }
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        tracker.AddKills(other, NORMAL, 2, DAY)
        tracker.AddKills(BOSS, NORMAL, 1, NEXT_DAY)
        local saved = mock.Saved("char:Tester").bosses
        assert.are.equal("20756:1,20757:1", saved.testboss.kills.Normal)
        assert.are.equal("20756:2", saved.other.kills.Normal)
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
        assert.are.same({ kills = {}, dryFrom = {}, items = {} }, tracker.Tallies(BOSS))
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
        assert.are.equal("20756:1", mock.Saved("char:Tester").bosses.testboss.kills.Normal)
    end)

    it("tells listeners about each change", function()
        local calls = 0
        tracker.OnChange(function() calls = calls + 1 end)
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        tracker.AddDrops(BOSS, 101, 1)
        assert.are.equal(2, calls)
    end)
end)

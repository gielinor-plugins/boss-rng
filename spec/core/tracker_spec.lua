local mock = require("spec/mock_api")

local NORMAL, HARD = { key = "n", kc = "KC_NORMAL" }, { key = "h", kc = "KC_HARD" }
local BOSS = {
    key = "testboss",
    modes = { NORMAL, HARD },
    items = {
        [101] = {},
        [102] = { pooledBy = {} },
    },
}
local DAY, NEXT_DAY = 20756, 20757
local DRY_KEYS = { "any", "101", "102" } -- the boss's streak and each unique's
local EMPTY = require("src/core/tallies").Empty()

describe("tracker", function()
    local tracker

    -- Loads a fresh copy of the tracker, like a plugin reload.
    local function reload()
        package.loaded["src/core/tracker"] = nil
        tracker = require("src/core/tracker")
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
        assert.are.same(
            { n = { ["20756"] = 1, ["20757"] = 1 }, h = { ["20756"] = 2 } },
            tallies.kills
        )
        assert.are.equal(4, tracker.Total(tallies.kills))
        -- Saved as text per mode, days in order.
        local saved = mock.Saved("char:Tester")
        assert.are.equal(6, saved.version)
        assert.are.same({ n = "20756:1,20757:1", h = "20756:2" }, saved.bosses.testboss.kills)
    end)

    it("adds up a kill's sums per mode and day, and averages them", function()
        tracker.AddKills(BOSS, HARD, 1, DAY, { enrage = 0, streak = 1 })
        tracker.AddKills(BOSS, HARD, 1, DAY, { enrage = 10, streak = 2 })
        reload() -- through saving
        local tallies = tracker.Tallies(BOSS)
        assert.are.same({ enrage = 5, streak = 1.5 }, tracker.Means(tallies, "h", DAY))
        assert.is_nil(tracker.Means(tallies, "n", DAY))
        assert.are.same({ h = "20756:10" }, mock.Saved("char:Tester").bosses.testboss.sums.enrage)
    end)

    it("counts a dry streak for the boss and for each unique", function()
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        local tallies = tracker.Tallies(BOSS)
        for _, key in ipairs(DRY_KEYS) do
            assert.are.same({ n = { ["20756"] = 1 } }, tracker.Dry(tallies, key))
        end
    end)

    it("ends the boss's dry streak and the item's at a drop", function()
        tracker.AddKills(BOSS, NORMAL, 2, DAY)
        tracker.AddDrops(BOSS, 101, 1)
        tracker.AddKills(BOSS, HARD, 1, NEXT_DAY)
        local tallies = tracker.Tallies(BOSS)
        assert.are.equal(1, tallies.items["101"])
        assert.are.same({ h = { ["20757"] = 1 } }, tracker.Dry(tallies, "any"))
        assert.are.same({ h = { ["20757"] = 1 } }, tracker.Dry(tallies, "101"))
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

    it(
        "counts a unique added later from the first tracked kill, like its expected drops",
        function()
            local before = { key = "testboss", modes = BOSS.modes, items = { [101] = {} } }
            tracker.AddKills(before, NORMAL, 3, DAY)
            tracker.AddKills(BOSS, NORMAL, 2, DAY) -- 102 is new here
            local tallies = tracker.Tallies(BOSS)
            assert.are.equal(5, tracker.Total(tracker.Dry(tallies, "102")))
            assert.are.same({}, tallies.dryFrom) -- nothing saved for streaks from the first kill
        end
    )

    -- The dry streaks counted kill by kill, next to the tracker's, through kills,
    -- drops and unreadable days (0).
    it("keeps the same dry streaks as counting every kill", function()
        local counted = {} -- [key] = { [mode] = { [day] = kills } }
        local function count(mode, day, n)
            for _, key in ipairs(DRY_KEYS) do
                counted[key] = counted[key] or {}
                local byDay = counted[key][mode.key] or {}
                byDay[tostring(day)] = (byDay[tostring(day)] or 0) + n
                counted[key][mode.key] = byDay
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
            for _, key in ipairs(DRY_KEYS) do
                assert.are.same(counted[key] or {}, tracker.Dry(tallies, key))
            end
        end
    end)

    it("starts again from another version", function()
        mock.SetSaved("char:Tester", { version = 3, bosses = { testboss = { kills = { n = 4 } } } })
        reload()
        assert.are.same(EMPTY, tracker.Tallies(BOSS))
    end)

    it(
        "tells when a boss's tallies may have changed: its kills, drops or reset, or another character",
        function()
            local other = { key = "other", modes = { NORMAL }, items = {} }
            local function changesAfter(action)
                local before = tracker.Changes(BOSS)
                action()
                return tracker.Changes(BOSS) ~= before
            end
            assert.is_false(changesAfter(function()
                tracker.AddKills(other, NORMAL, 1, DAY)
            end))
            assert.is_true(changesAfter(function()
                tracker.AddKills(BOSS, NORMAL, 1, DAY)
            end))
            assert.is_true(changesAfter(function()
                tracker.AddDrops(BOSS, 101, 1)
            end))
            assert.is_true(changesAfter(function()
                tracker.Reset(BOSS)
            end))
            assert.is_true(changesAfter(tracker.ResetAll))
            assert.is_true(changesAfter(function()
                mock.characterName = "Other"
            end))
            assert.is_false(changesAfter(function() end))
        end
    )

    it("saves each boss's latest kills, re-encoding only the one that changed", function()
        local other = { key = "other", modes = { NORMAL }, items = {} }
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        tracker.AddKills(other, NORMAL, 2, DAY)
        tracker.AddKills(BOSS, NORMAL, 1, NEXT_DAY)
        local saved = mock.Saved("char:Tester").bosses
        assert.are.equal("20756:1,20757:1", saved.testboss.kills.n)
        assert.are.equal("20756:2", saved.other.kills.n)
    end)

    it("resets one boss, keeping the others, and starts it fresh", function()
        local other = { key = "other", modes = { NORMAL }, items = {} }
        tracker.AddKills(other, NORMAL, 2, DAY)
        tracker.AddKills(BOSS, NORMAL, 3, DAY)
        tracker.AddDrops(BOSS, 101, 1)
        tracker.Reset(BOSS)
        tracker.AddKills(BOSS, NORMAL, 1, NEXT_DAY)
        mock.Reset(true) -- reload, to go through saving
        mock.inGame = true
        reload()
        local tallies = tracker.Tallies(BOSS)
        assert.are.equal(1, tracker.Total(tallies.kills))
        assert.are.same({}, tallies.items)
        assert.are.equal(1, tracker.Total(tracker.Dry(tallies, "101")))
        assert.are.equal(2, tracker.Total(tracker.Tallies(other).kills))
    end)

    it("resets every boss and tells listeners", function()
        local calls = 0
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        tracker.OnChange(function()
            calls = calls + 1
        end)
        tracker.ResetAll()
        assert.are.equal(1, calls)
        mock.Reset(true)
        mock.inGame = true
        reload()
        assert.are.same(EMPTY, tracker.Tallies(BOSS))
        assert.is_nil(tracker.LastBossKey())
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
        assert.are.same(EMPTY, tracker.Tallies(BOSS))
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
        tracker.OnChange(function()
            error("broken listener")
        end)
        tracker.OnChange(function()
            calls = calls + 1
        end)
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        assert.are.equal(1, calls)
        assert.are.equal("20756:1", mock.Saved("char:Tester").bosses.testboss.kills.n)
    end)

    it("tells listeners about each change", function()
        local calls = 0
        tracker.OnChange(function()
            calls = calls + 1
        end)
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        tracker.AddDrops(BOSS, 101, 1)
        assert.are.equal(2, calls)
    end)
end)

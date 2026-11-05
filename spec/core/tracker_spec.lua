local mock = require("spec/mock_api")

local NORMAL, HARD = { key = "n" }, { key = "h" }
local BOSS = {
    key = "testboss",
    modes = { n = NORMAL, h = HARD },
    items = {
        [101] = {},
        [102] = { pooledBy = {} },
    },
}
local DAY, NEXT_DAY = 20756, 20757
local DRY_KEYS = { "any", "101", "102" } -- the boss's streak and each unique's
local tallies = require("src/core/tallies")
local EMPTY = tallies.Empty()

describe("tracker", function()
    local tracker

    -- Loads a fresh copy of the tracker, like a plugin reload.
    local function reload()
        package.loaded["src/core/tracker"] = nil
        tracker = require("src/core/tracker")
    end

    -- Like restarting the client: only the saved data is kept.
    local function restart()
        mock.Reset(true)
        mock.inGame = true
        reload()
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
        local t = tracker.Tallies(BOSS)
        assert.are.same({ n = { ["20756"] = 1, ["20757"] = 1 }, h = { ["20756"] = 2 } }, t.kills)
        assert.are.equal(4, tallies.Total(t.kills))
        -- Saved in the boss's own entry, as text per mode, days in order.
        local saved = mock.Saved("char:Tester:testboss")
        assert.are.equal(1, saved.version)
        assert.are.same({ n = "20756:1,20757:1", h = "20756:2" }, saved.kills)
    end)

    it("adds up a kill's sums per mode and day, and averages them", function()
        tracker.AddKills(BOSS, HARD, 1, DAY, { enrage = 0, streak = 1 })
        tracker.AddKills(BOSS, HARD, 1, DAY, { enrage = 10, streak = 2 })
        reload() -- through saving
        local t = tracker.Tallies(BOSS)
        assert.are.same({ enrage = 5, streak = 1.5 }, tallies.Means(t, "h", DAY))
        assert.is_nil(tallies.Means(t, "n", DAY))
        assert.are.same({ h = "20756:10" }, mock.Saved("char:Tester:testboss").sums.enrage)
    end)

    it("counts a dry streak for the boss and for each unique", function()
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        local t = tracker.Tallies(BOSS)
        for _, key in ipairs(DRY_KEYS) do
            assert.are.same({ n = { ["20756"] = 1 } }, tallies.Dry(t, key))
        end
    end)

    it("ends the boss's dry streak and the item's at a drop", function()
        tracker.AddKills(BOSS, NORMAL, 2, DAY)
        tracker.AddDrops(BOSS, 101, 1)
        tracker.AddKills(BOSS, HARD, 1, NEXT_DAY)
        local t = tracker.Tallies(BOSS)
        assert.are.equal(1, t.items["101"])
        assert.are.same({ h = { ["20757"] = 1 } }, tallies.Dry(t, "any"))
        assert.are.same({ h = { ["20757"] = 1 } }, tallies.Dry(t, "101"))
        assert.are.equal(3, tallies.Total(tallies.Dry(t, "102"))) -- still dry
    end)

    it("tracks a pooled unique only for the boss killed last", function()
        local other = { key = "other", modes = { n = NORMAL }, items = BOSS.items }
        tracker.AddKills(other, NORMAL, 1, DAY)
        tracker.AddDrops(BOSS, 102, 1)
        assert.is_nil(tracker.Tallies(BOSS).items["102"])
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        tracker.AddDrops(BOSS, 102, 1)
        assert.are.equal(1, tracker.Tallies(BOSS).items["102"])
        assert.are.same({}, tallies.Dry(tracker.Tallies(BOSS), "any"))
    end)

    it("remembers the last boss killed", function()
        assert.is_nil(tracker.LastBossKey())
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        assert.are.equal("testboss", tracker.LastBossKey())
    end)

    it("forgets the last boss killed, and its entry, when that boss is reset", function()
        local other = { key = "other", modes = { n = NORMAL }, items = {} }
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        tracker.Reset(other) -- another boss: still remembered
        assert.are.equal("testboss", tracker.LastBossKey())
        assert.are.equal("testboss", mock.Saved("char:Tester").lastBoss)
        tracker.Reset(BOSS)
        assert.is_nil(tracker.LastBossKey())
        assert.is_nil(mock.Saved("char:Tester")) -- nothing else to keep
        restart()
        assert.is_nil(tracker.LastBossKey())
    end)

    it(
        "counts a unique added later from the first tracked kill, like its expected drops",
        function()
            local before = { key = "testboss", modes = BOSS.modes, items = { [101] = {} } }
            tracker.AddKills(before, NORMAL, 3, DAY)
            tracker.AddKills(BOSS, NORMAL, 2, DAY) -- 102 is new here
            local t = tracker.Tallies(BOSS)
            assert.are.equal(5, tallies.Total(tallies.Dry(t, "102")))
            assert.are.same({}, t.dryFrom) -- nothing saved for streaks from the first kill
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
                -- 102 is pooled: only after a kill of this boss
                tracker.AddKills(BOSS, NORMAL, 1, day)
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
                restart()
            end
            local t = tracker.Tallies(BOSS)
            for _, key in ipairs(DRY_KEYS) do
                assert.are.same(counted[key] or {}, tallies.Dry(t, key))
            end
        end
    end)

    it("reads entries saved in the documented format", function()
        -- From docs/data/saved-data.example.json, as the game gives them back: every
        -- number as a decimal.
        local function startAt(day, n)
            return { day = day, at = { h = { [tostring(math.tointeger(day))] = n } } }
        end
        mock.SetSaved("char:Tester", { version = 1.0, lastBoss = "barrows" })
        mock.SetSaved("char:Tester:vorkath", {
            version = 1.0,
            kills = { h = "20760:7" },
            dryFrom = { ["56079"] = startAt(20760.0, 3.0), any = startAt(20760.0, 3.0) },
            items = { ["56079"] = 2.0 },
        })
        mock.SetSaved("char:Tester:archglacor", {
            version = 1.0,
            kills = { h = "20760:9" },
            sums = { enrage = { h = "20760:23712" }, streak = { h = "20760:61" } },
            dryFrom = { ["52115"] = startAt(20760.0, 9.0), any = startAt(20760.0, 9.0) },
            items = { ["52115"] = 1.0 },
        })
        reload()
        assert.are.equal("barrows", tracker.LastBossKey())
        -- Vorkath: 7 chests, a spike at the 3rd, no codex yet.
        local vorkath = tracker.Tallies({ key = "vorkath" })
        assert.are.equal(7, tallies.Total(vorkath.kills))
        assert.are.equal(2, vorkath.items["56079"])
        assert.are.equal(4, tallies.Total(tallies.Dry(vorkath, "56079")))
        assert.are.equal(4, tallies.Total(tallies.Dry(vorkath, "any")))
        assert.are.equal(7, tallies.Total(tallies.Dry(vorkath, "56068")))
        -- Arch-Glacor: its sums read back as that day's averages.
        local means = tallies.Means(tracker.Tallies({ key = "archglacor" }), "h", 20760)
        assert.are.near(23712 / 9, means.enrage, 1e-9)
        assert.are.near(61 / 9, means.streak, 1e-9)
    end)

    it("reads an entry of another version as empty", function()
        mock.SetSaved("char:Tester", { version = 3, lastBoss = "testboss" })
        mock.SetSaved("char:Tester:testboss", { version = 3, kills = { n = "20756:4" } })
        reload()
        assert.are.same(EMPTY, tracker.Tallies(BOSS))
        assert.is_nil(tracker.LastBossKey())
    end)

    it("tells when a boss's tallies may have changed, or another character loaded", function()
        local other = { key = "other", modes = { n = NORMAL }, items = {} }
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
    end)

    it("saves each boss in its own entry, writing only the boss that changed", function()
        local other = { key = "other", modes = { n = NORMAL }, items = {} }
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        tracker.AddKills(other, NORMAL, 2, DAY)
        assert.are.equal("20756:2", mock.Saved("char:Tester:other").kills.n)
        mock.SetSaved("char:Tester:other", { version = 1, kills = { n = "marked" } })
        tracker.AddKills(BOSS, NORMAL, 1, NEXT_DAY)
        assert.are.equal("20756:1,20757:1", mock.Saved("char:Tester:testboss").kills.n)
        assert.are.equal("marked", mock.Saved("char:Tester:other").kills.n) -- not rewritten
        assert.are.same({ version = 1, lastBoss = "testboss" }, mock.Saved("char:Tester"))
    end)

    it("resets one boss, keeping the others, and starts it fresh", function()
        local other = { key = "other", modes = { n = NORMAL }, items = {} }
        tracker.AddKills(other, NORMAL, 2, DAY)
        tracker.AddKills(BOSS, NORMAL, 3, DAY)
        tracker.AddDrops(BOSS, 101, 1)
        tracker.Reset(BOSS)
        assert.is_nil(mock.Saved("char:Tester:testboss"))
        tracker.AddKills(BOSS, NORMAL, 1, NEXT_DAY)
        restart() -- reload, to go through saving
        local t = tracker.Tallies(BOSS)
        assert.are.equal(1, tallies.Total(t.kills))
        assert.are.same({}, t.items)
        assert.are.equal(1, tallies.Total(tallies.Dry(t, "101")))
        assert.are.equal(2, tallies.Total(tracker.Tallies(other).kills))
    end)

    it("deletes all of the character's saved data and tells listeners", function()
        local calls = 0
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        -- A boss the plugin no longer has, and other characters' entries.
        mock.SetSaved("char:Tester:gone", { version = 1, kills = { n = "20756:1" } })
        mock.SetSaved("char:Other:testboss", { version = 1, kills = { n = "20756:1" } })
        mock.SetSaved("char:Tester2:testboss", { version = 1, kills = { n = "20756:1" } })
        mock.SetSaved("char:Tester2", { version = 1, lastBoss = "testboss" })
        tracker.OnChange(function()
            calls = calls + 1
        end)
        tracker.ResetAll()
        assert.are.equal(1, calls)
        assert.is_nil(mock.Saved("char:Tester"))
        assert.is_nil(mock.Saved("char:Tester:testboss"))
        restart()
        assert.are.same(EMPTY, tracker.Tallies(BOSS))
        assert.is_nil(tracker.LastBossKey())
        assert.is_nil(mock.Saved("char:Tester:gone"))
        assert.are.equal("20756:1", mock.Saved("char:Other:testboss").kills.n)
        assert.are.equal("20756:1", mock.Saved("char:Tester2:testboss").kills.n)
        assert.are.equal("testboss", mock.Saved("char:Tester2").lastBoss)
    end)

    it("keeps characters separate", function()
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        mock.characterName = "Other"
        assert.are.same(EMPTY, tracker.Tallies(BOSS))
        tracker.AddKills(BOSS, NORMAL, 5, DAY)
        mock.characterName = "Tester"
        assert.are.equal(1, tallies.Total(tracker.Tallies(BOSS).kills))
    end)

    it("ignores reports while nobody is logged in", function()
        mock.inGame = false
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        assert.is_nil(mock.Saved("char:Tester"))
        assert.is_nil(mock.Saved("char:Tester:testboss"))
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
        assert.are.equal("20756:1", mock.Saved("char:Tester:testboss").kills.n)
    end)

    it("tells listeners about each change", function()
        local calls = 0
        tracker.OnChange(function()
            calls = calls + 1
        end)
        tracker.AddKills(BOSS, NORMAL, 1, DAY)
        tracker.AddDrops(BOSS, 101, 1)
        assert.are.equal(2, calls)
        local other = { key = "other", modes = { n = NORMAL }, items = BOSS.items }
        tracker.AddKills(other, NORMAL, 1, DAY)
        tracker.AddDrops(BOSS, 102, 1) -- pooled, and the other boss was killed last
        assert.are.equal(3, calls) -- nothing changed, so nothing to tell
    end)
end)

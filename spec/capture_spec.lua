-- Run from the project root with: busted

local mock = require("spec/mock_api")

local BOSS = {
    key = "testboss",
    name = "Test Boss",
    logPage = "COLLECTION_BOSS_TEST",
    modes = {
        { name = "Normal", kc = "KC_NORMAL" },
        { name = "Hard mode", kc = "KC_HARD" },
    },
    items = {
        [101] = { log = "LOG_WEAPON", kind = "unique" },
        [103] = { log = "LOG_SHARED", kind = "shared" },
    },
}

describe("capture", function()
    local capture, kills, logCounts, tick

    -- Lets a second pass, so capture checks once.
    local function advance()
        tick = tick + 50
        mock.Fire("Logic", { logicTick = tick })
    end

    -- Opens the boss log on a page, by its config name.
    local function openLog(page)
        local pages = { { configName = "COLLECTION_BOSS_OTHER" }, { configName = page } }
        mock.SetValue("COLLECTION_LOG_DATA", { GetColumnValues = function(_, column)
            return column == 8 and pages or {}
        end })
        mock.SetValue("COLLECTION_LOG_SELECTED", 1)
        mock.OpenInterface("COLLECTION_LOG")
    end

    before_each(function()
        mock.Reset()
        mock.SetValue("KC_NORMAL", 40)
        mock.SetValue("KC_HARD", 2)
        mock.SetValue("LOG_WEAPON", 3)
        mock.SetValue("LOG_SHARED", 9)
        for _, name in ipairs({ "src/capture", "src/gamevars" }) do
            package.loaded[name] = nil
        end
        capture = require("src/capture")
        kills, logCounts, tick = {}, {}, 0
        capture.Start({ BOSS },
            function(boss, counts) table.insert(kills, { boss = boss, counts = counts }) end,
            function(boss, counts) table.insert(logCounts, { boss = boss, counts = counts }) end)
    end)

    it("reads nothing while neither is open", function()
        advance()
        assert.are.equal(0, #kills + #logCounts)
    end)

    it("reads kill counts while the Beasts tab shows the boss", function()
        mock.OpenInterface("BSLAY_BOSS_INFO", { [11] = mock.Label("<col=ffffff>Test Boss</col>") })
        advance()
        assert.are.equal(BOSS, kills[1].boss)
        assert.are.same({ Normal = 40, ["Hard mode"] = 2 }, kills[1].counts)
    end)

    it("ignores bosses it doesn't know, and a hidden name", function()
        mock.OpenInterface("BSLAY_BOSS_INFO", { [11] = mock.Label("Someone Else") })
        advance()
        local hidden = mock.Label("Test Boss")
        hidden.hidden = true
        mock.OpenInterface("BSLAY_BOSS_INFO", { [11] = hidden })
        advance()
        assert.are.equal(0, #kills)
    end)

    it("reads unique log counts while the boss log shows the boss", function()
        openLog("COLLECTION_BOSS_TEST")
        advance()
        assert.are.equal(BOSS, logCounts[1].boss)
        assert.are.same({ [101] = 3 }, logCounts[1].counts)
    end)

    it("ignores other boss log pages", function()
        openLog("COLLECTION_BOSS_ELSE")
        advance()
        assert.are.equal(0, #logCounts)
    end)

    it("doesn't read kill counts from the Beasts tab behind the boss log", function()
        mock.OpenInterface("BSLAY_BOSS_INFO", { [11] = mock.Label("Test Boss") })
        openLog("COLLECTION_BOSS_ELSE")
        advance()
        assert.are.equal(0, #kills)
    end)

    it("checks once a second", function()
        mock.OpenInterface("BSLAY_BOSS_INFO", { [11] = mock.Label("Test Boss") })
        advance()
        mock.Fire("Logic", { logicTick = tick + 10 })
        assert.are.equal(1, #kills)
    end)

    it("waits while a kill is still to be reported", function()
        package.loaded["src/gamevars"].HasPending = function() return true end
        mock.OpenInterface("BSLAY_BOSS_INFO", { [11] = mock.Label("Test Boss") })
        advance()
        assert.are.equal(0, #kills)
    end)

    it("unsubscribes on stop", function()
        capture.Stop()
        assert.are.equal(0, mock.SubscriptionCount())
    end)
end)

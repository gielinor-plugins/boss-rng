local state = require("src/ui/state")

describe("state", function()
    it("sorts rows unluckiest first, then by name, with untracked luck as 1", function()
        local rows = state.Rows({
            items = {
                [1] = { luck = 0.9 },
                [2] = { luck = 0.2 },
                [3] = {},
                [4] = { luck = 0.9, group = { name = "A group" } },
            },
        })
        local names = {}
        for i, row in ipairs(rows) do
            names[i] = row.name
        end
        assert.are.same({ "Item 2", "A group", "Item 1", "Item 3" }, names)
    end)

    it("notes a boss's assumptions, for the values read, and its tip", function()
        local notes = state.Notes({
            boss = {
                assumptions = function(readings)
                    return { "Solo kills", "Stones: " .. readings.stones }
                end,
                tip = "A tip",
            },
            readings = { stones = 3 },
        })
        assert.are.same({
            { title = "Luck Assumptions", lines = { "Solo kills", "Stones: 3" } },
            { title = "Tips", lines = { "A tip" } },
        }, notes)
    end)

    it("has no notes for a boss without assumptions or a tip", function()
        assert.are.same({}, state.Notes({ boss = { assumptions = {} }, readings = {} }))
    end)
end)

describe("state.Current", function()
    local mock = require("spec/mock_api")
    local DAY = 20761
    local tracker, current, byKey

    before_each(function()
        mock.Reset()
        mock.inGame = true
        -- Fresh copies, sharing one tracker, like a plugin reload.
        package.loaded["src/core/tracker"] = nil
        package.loaded["src/ui/state"] = nil
        tracker = require("src/core/tracker")
        current = require("src/ui/state")
        byKey = {}
        for _, boss in ipairs(require("src/bosses")) do
            byKey[boss.key] = boss
        end
    end)

    local function kill(key)
        local boss = byKey[key]
        local mode = boss.modes.n or boss.modes.h
        tracker.AddKills(boss, mode, 1, DAY)
    end

    local function shown()
        local list, selected = current.Current()
        return list[selected].boss.key, list[selected]
    end

    it("shows the last boss killed, or the one picked until another boss is killed", function()
        kill("vorkath")
        kill("rasial")
        assert.are.equal("rasial", shown())
        current.Pick("vorkath")
        assert.are.equal("vorkath", shown())
        kill("rasial") -- the same boss as before: the pick stays
        assert.are.equal("vorkath", shown())
        kill("graardor")
        assert.are.equal("graardor", shown())
    end)

    it("works out the shown boss's stats again only when they may have changed", function()
        kill("rasial")
        local _, first = shown()
        local _, again = shown()
        assert.are.equal(first.stats, again.stats) -- reused
        kill("rasial")
        local _, after = shown()
        assert.are.equal(2, after.stats.kills)
    end)
end)

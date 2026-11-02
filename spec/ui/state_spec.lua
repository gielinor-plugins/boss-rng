local state = require("src/ui/state")

describe("state", function()
    it("sorts rows unluckiest first, then by name, with untracked luck as 1", function()
        local rows = state.Rows({ items = {
            [1] = { luck = 0.9 },
            [2] = { luck = 0.2 },
            [3] = {},
            [4] = { luck = 0.9, group = { name = "A group" } },
        } })
        local names = {}
        for i, row in ipairs(rows) do
            names[i] = row.name
        end
        assert.are.same({ "Item 2", "A group", "Item 1", "Item 3" }, names)
    end)

    it("notes a boss's assumptions, for the values read, and its tip", function()
        local notes = state.Notes({
            boss = {
                assumptions = function(readings) return { "Solo kills", "Stones: " .. readings.stones } end,
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

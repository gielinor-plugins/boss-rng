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

    it("notes a boss's assumptions and tips, with where to change its settings", function()
        local notes = state.Notes({
            boss = {
                assumptions = { "Solo kills" }, tip = "A tip",
                choices = { { key = "piles", label = "Piles" } },
            },
            picks = { piles = 3 },
        })
        assert.are.same({
            { title = "Luck Assumptions", lines = { "Solo kills", "Piles: 3" } },
            { title = "Tips", lines = { "A tip", "Adjust settings in Plugin Hub > Manage > Boss RNG" } },
        }, notes)
    end)

    it("has no notes for a boss without assumptions, tips or settings", function()
        assert.are.same({}, state.Notes({ boss = { assumptions = {} }, picks = {} }))
    end)
end)

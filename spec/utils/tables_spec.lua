local tables = require("src/utils/tables")

describe("tables", function()
    it("merges tables into a new one, later ones winning and nil ones skipped", function()
        local first = { a = 1, b = 1 }
        local merged = tables.Merge(first, nil, { b = 2, c = 2 })
        assert.are.same({ a = 1, b = 2, c = 2 }, merged)
        assert.are.same({ a = 1, b = 1 }, first)
    end)
end)

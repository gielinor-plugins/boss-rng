local days = require("src/utils/days")

describe("days", function()
    it("counts a date's days since 1 January 1970, as the game clock does", function()
        -- Known dates, from a standard calendar.
        local DATES = {
            { 1970, 1, 1, 0 },
            { 2024, 2, 29, 19782 }, -- a leap day
            { 2024, 3, 1, 19783 },
            { 2000, 2, 29, 11016 }, -- 2000 is a leap year: divisible by 400
            { 2100, 3, 1, 47541 }, -- 2100 isn't: divisible by 100, not 400
            { 2026, 10, 30, 20756 },
        }
        for _, date in ipairs(DATES) do
            local year, month, day, expected = table.unpack(date)
            assert.are.equal(expected, days.FromDate(year, month, day))
        end
    end)

    it("turns the game clock's minutes into whole days", function()
        assert.are.equal(0, days.FromMinutes(0))
        assert.are.equal(0, days.FromMinutes(24 * 60 - 1)) -- the last minute of day 0
        assert.are.equal(1, days.FromMinutes(24 * 60))
        assert.are.equal(20756, days.FromMinutes(29888748)) -- 30 October 2026, 01:48 UTC
    end)
end)

-- Checks every boss file follows the data format. Run from the project root: busted

local bosses = require("src/bosses")
local luck = require("src/luck")

local KINDS = { unique = true, shared = true, lore = true, pet = true, excluded = true }

local function startsWith(text, prefix)
    return type(text) == "string" and text:sub(1, #prefix) == prefix
end

describe("boss data", function()
    it("gives every boss a different key", function()
        local seen = {}
        for _, boss in ipairs(bosses) do
            assert.is_nil(seen[boss.key])
            seen[boss.key] = true
        end
    end)

    for _, boss in ipairs(bosses) do
        describe(boss.name, function()
            it("names its log page and a KC varbit for each mode", function()
                assert.is_true(startsWith(boss.logPage, "COLLECTION_BOSS_"))
                assert.is_true(#boss.modes > 0)
                for _, mode in ipairs(boss.modes) do
                    assert.is_true(startsWith(mode.kc, "BSLAY_KILLS_"))
                end
            end)

            it("gives every item a known kind, and counted items a log varbit", function()
                for _, item in pairs(boss.items) do
                    assert.is_true(KINDS[item.kind] == true)
                    if item.kind == "unique" or item.kind == "shared" then
                        assert.is_true(startsWith(item.log, "ITEMLOG_ITEM_"))
                    end
                end
            end)

            it("states its assumptions in plain words", function()
                assert.is_true(#boss.assumptions > 0)
                for _, note in ipairs(boss.assumptions) do
                    assert.are.equal("string", type(note))
                    assert.is_nil(note:find("<", 1, true)) -- the game would read it as a tag
                end
            end)

            it("only rolls unique items", function()
                for _, mode in ipairs(boss.modes) do
                    for itemID in pairs(luck.ItemChances(mode.rolls)) do
                        assert.are.equal("unique", boss.items[itemID].kind)
                    end
                end
            end)
        end)
    end
end)

-- Each boss's boss log item count, and its wiki rates per kill for a few items.
local HILT = 63 / 64 / 512 -- a general's hilt: only rolled when the unique table misses
local NEX = 1 / 384
local CASES = {
    { file = "graardor", items = 18, rates = { [25022] = 1 / 384, [11704] = HILT } },
    { file = "kreearra", items = 18, rates = { [11718] = 1 / 384, [11702] = HILT } },
    { file = "zilyana", items = 19, rates = { [11730] = 1 / 320, [25037] = 1 / 640, [25034] = 1 / 320, [11706] = HILT } },
    { file = "kril", items = 20, rates = { [24992] = 1 / 512, [11716] = 1 / 512, [11708] = HILT } },
    { file = "nex", items = 21, rates = { [20135] = NEX, [25664] = NEX, [20171] = NEX } },
}

for _, case in ipairs(CASES) do
    describe(case.file, function()
        local boss = require("src/bosses/" .. case.file)

        it("lists all " .. case.items .. " boss log items", function()
            local count = 0
            for _ in pairs(boss.items) do
                count = count + 1
            end
            assert.are.equal(case.items, count)
        end)

        it("has the wiki rates", function()
            local chances = luck.ItemChances(boss.modes[1].rolls)
            for itemID, rate in pairs(case.rates) do
                assert.are.near(rate, chances[itemID], 1e-12)
            end
        end)
    end)
end

-- The generals' uniques can't drop together, so their chances simply add up.
it("gives a general at most one unique per kill", function()
    local rolls = require("src/bosses/zilyana").modes[1].rolls
    assert.are.near(1 / 64 + HILT, luck.ChanceOfAny(rolls), 1e-12)
end)

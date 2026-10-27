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

-- The God Wars generals: 18 boss log items each, and the wiki rates (an armor
-- roll, and the hilt only when it misses).
for _, case in ipairs({
    { file = "kreearra", helmet = 11718, hilt = 11702 },
    { file = "graardor", helmet = 25022, hilt = 11704 },
}) do
    describe(case.file, function()
        local boss = require("src/bosses/" .. case.file)

        it("lists all 18 boss log items", function()
            local count = 0
            for _ in pairs(boss.items) do
                count = count + 1
            end
            assert.are.equal(18, count)
        end)

        it("has the wiki rates", function()
            local rolls = boss.modes[1].rolls
            local chances = luck.ItemChances(rolls)
            assert.are.near(1 / 384, chances[case.helmet], 1e-12)
            assert.are.near(63 / 64 / 512, chances[case.hilt], 1e-12)
            -- At most one unique per kill, so the chances simply add up.
            assert.are.near(1 / 64 + 63 / 64 / 512, luck.ChanceOfAny(rolls), 1e-12)
        end)
    end)
end

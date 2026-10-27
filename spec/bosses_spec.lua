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

describe("Kree'arra", function()
    local kreearra = require("src/bosses/kreearra")

    it("lists all 18 boss log items", function()
        local count = 0
        for _ in pairs(kreearra.items) do
            count = count + 1
        end
        assert.are.equal(18, count)
    end)

    it("has the wiki rates", function()
        local chances = luck.ItemChances(kreearra.modes[1].rolls)
        assert.are.near(1 / 384, chances[11718], 1e-12) -- Armadyl helmet
        assert.are.near(1 / 512, chances[11702], 1e-12) -- Armadyl hilt
    end)
end)

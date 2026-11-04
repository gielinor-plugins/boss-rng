-- Players' saved data is keyed by boss key and mode key (docs/data/compatibility.md).
-- This list is every key that can be saved, so renaming or dropping one fails here
-- instead of losing players' kills. Only add to it.

local bosses = require("src/bosses")

local function range(prefix, from, to)
    local keys = {}
    for i = from, to do
        table.insert(keys, prefix .. i)
    end
    return keys
end

local function join(...)
    local keys = {}
    for _, list in ipairs({ ... }) do
        for _, key in ipairs(list) do
            table.insert(keys, key)
        end
    end
    return keys
end

local NORMAL_HARD = { "n", "h" }
local TEAMS = { "s", "1", "2", "3" } -- an elite dungeon boss's solo kill count, then by players

local function dungeonBoss(id)
    local keys = {}
    for _, team in ipairs(TEAMS) do
        table.insert(keys, id .. team)
    end
    return keys
end

local SAVED = {
    amascut = { "n", "e100", "e500", "e750", "e1000", "e2000" },
    araxxi = { "s", "d" },
    archglacor = { "h" },
    -- Every chest's key is "c" and its brothers' hex bits; a sample of them.
    barrows = { "c0", "c1", "c7", "c3f", "c7f", "cbf", "cff" },
    corp = { "n" },
    croesus = range("r", 0, 12),
    dragonkin = join(dungeonBoss("a"), dungeonBoss("v"), dungeonBoss("b")),
    elidinis = { "n" },
    furies = NORMAL_HARD,
    graardor = NORMAL_HARD,
    gregorovic = NORMAL_HARD,
    helwyr = NORMAL_HARD,
    kerapac = join(range("n", 1, 3), range("h", 1, 3)),
    kreearra = NORMAL_HARD,
    kril = NORMAL_HARD,
    magister = { "n" },
    nex = { "n" },
    raksha = { "s", "d" },
    rasial = { "n" },
    rots = { "n" },
    sanctum = { "v", "vh", "k", "kh", "n", "nh" },
    shadow_reef = dungeonBoss("a"),
    solak = { "n" },
    vindicta = NORMAL_HARD,
    vorkath = NORMAL_HARD,
    zilyana = NORMAL_HARD,
    zuk = { "n", "h", "hc" },
}

describe("saved keys", function()
    it("keeps every boss key, and lists every boss", function()
        local keys = {}
        for _, boss in ipairs(bosses) do
            keys[boss.key] = true
            assert(SAVED[boss.key] ~= nil, boss.key .. " is missing from SAVED")
        end
        for key in pairs(SAVED) do
            assert(keys[key], "no boss loads saved key " .. key)
        end
    end)

    for _, boss in ipairs(bosses) do
        it("reads back every saved mode of " .. boss.name, function()
            for _, key in ipairs(SAVED[boss.key] or {}) do
                local mode = boss.modes[key]
                assert(mode ~= nil and mode.rolls ~= nil, boss.key .. " mode " .. key)
                assert.are.equal(key, mode.key)
            end
        end)
    end
end)

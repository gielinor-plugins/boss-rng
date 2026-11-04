-- Barrows Brothers. Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28. With n
-- brothers killed (Linza not counted), a chest makes min(n + 1, 7) rolls for a killed
-- brother's item, and Linza adds her own roll. The amulet's rate is from Jagex's
-- Late-Game Rebalance design preview, which doesn't say whether partial chests roll it,
-- so they're assumed to. Each looted chest is counted, under a mode for the brothers
-- killed. Only chests with 6 or more brothers are in the game's kill count.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_BARROWS", -- chests with 6 or more brothers, Akrisae counting (Linza not)
    run = "BARROWS", -- the run's tunnels and chest
    killed = "BARROWS_KILLED_", -- 1 if that original brother was killed this run, by name
    killedCount = "BARROWS_KILLED_COUNT", -- brothers killed this run, Akrisae and Linza included
    linzaKilled = "SISTER_KILLED_LINZA", -- 1 if Linza was killed this run
    log = "ITEMLOG_ITEM_BARROWS_", -- each item's collection log count, by brother and piece
}
local LOOTED = 0x4000000 -- the bit of VARS.run set when the chest is looted (no varbit name)

local function pieceChance(n, r)
    return 1 / math.max(r.pieceBase - r.piecePerBrother * n, r.pieceBest)
end

local FULL_CHEST = 6 -- the fewest brothers (Linza not counted) for the kill count

local AMULET = 39061 -- Amulet of the forsaken

-- A brother: name, name in game vars, items { [item id] = log var }.
local function brother(name, varName, pieces)
    local items, size = {}, 0
    for itemID, piece in pairs(pieces) do
        items[itemID] = VARS.log .. varName .. "_" .. piece
        size = size + 1
    end
    return { name = name, varName = varName, items = items, size = size }
end

local ORIGINALS = {
    brother("Ahrim", "AHRIM", { -- hood, top, skirt, staff, wand, book
        [4708] = "HEAD",
        [4712] = "BODY",
        [4714] = "LEGS",
        [4710] = "STAFF",
        [25652] = "WAND",
        [25672] = "OFFHAND",
    }),
    brother(
        "Dharok",
        "DHAROK",
        { [4716] = "HEAD", [4720] = "BODY", [4722] = "LEGS", [4718] = "AXE" }
    ),
    brother(
        "Guthan",
        "GUTHAN",
        { [4724] = "HEAD", [4728] = "BODY", [4730] = "LEGS", [4726] = "SPEAR" }
    ),
    brother("Karil", "KARIL", { -- coif, top, skirt, crossbow, pistol crossbows
        [4732] = "HEAD",
        [4736] = "BODY",
        [4738] = "LEGS",
        [4734] = "CROSSBOW",
        [25918] = "PISTOL",
        [25895] = "PISTOL_OFFHAND",
    }),
    brother(
        "Torag",
        "TORAG",
        { [4745] = "HEAD", [4749] = "BODY", [4751] = "LEGS", [4747] = "HAMMER" }
    ),
    brother(
        "Verac",
        "VERAC",
        { [4753] = "HEAD", [4757] = "BODY", [4759] = "LEGS", [4755] = "FLAIL" }
    ),
}
local AKRISAE = brother(
    "Akrisae",
    "AKRISAE",
    { [21736] = "HEAD", [21752] = "BODY", [21760] = "LEGS", [21744] = "MACE" }
)
local LINZA = brother("Linza", "SISTER", { -- helm, cuirass, greaves, hammer, shield
    [37433] = "HEAD",
    [37437] = "BODY",
    [37441] = "LEGS",
    [37445] = "HAMMER",
    [37449] = "SHIELD",
})

-- The brothers sharing the equipment rolls; each one's bit in a chest's key is 1 << (i - 1).
local BROTHERS = { table.unpack(ORIGINALS) }
table.insert(BROTHERS, AKRISAE)
local LINZA_BIT = 1 << #BROTHERS

-- Weights picking one brother evenly, then one of their items evenly.
local function weights(brothers)
    local result = {}
    for _, b in ipairs(brothers) do
        for itemID in pairs(b.items) do
            result[itemID] = 1 / b.size
        end
    end
    return result
end

local function chestRolls(brothers, linza, r)
    local rolls = { { chance = r.amulet, items = { [AMULET] = 1 } } }
    local n = #brothers
    if n > 0 then
        local roll = { chance = pieceChance(n, r), items = weights(brothers) }
        common.Repeat(rolls, math.min(n + 1, r.maxRolls), roll)
    end
    if linza then
        table.insert(rolls, { chance = r.linza, items = weights({ LINZA }) })
    end
    return rolls
end

-- A chest's mode key: "c" and the hex bits of the brothers killed ("cff": all eight).
-- Saved, so never change the format.
local function chestKey(bits)
    return string.format("c%x", bits)
end

-- A mode for every set of brothers a chest can have. Chests with fewer than
-- FULL_CHEST brothers aren't in the kill count.
local MODES = {}
for bits = 0, LINZA_BIT * 2 - 1 do
    local brothers = {}
    for i, b in ipairs(BROTHERS) do
        if bits & (1 << (i - 1)) ~= 0 then
            table.insert(brothers, b)
        end
    end
    local linza = bits & LINZA_BIT ~= 0
    MODES[chestKey(bits)] = {
        rolls = function(r)
            return chestRolls(brothers, linza, r)
        end,
        partial = #brothers < FULL_CHEST or nil,
    }
end

-- Read as the chest is looted, not as it opens: the first search brings out the tunnel
-- brother, who isn't dead yet. Akrisae has no var of his own: he's the brothers killed
-- less the six originals and Linza.
local function chestLooted(values)
    local bits, originals = 0, 0
    for i, b in ipairs(ORIGINALS) do
        if values[b.name] == 1 then
            bits, originals = bits | (1 << (i - 1)), originals + 1
        end
    end
    if values.killedCount - originals - values.linzaKilled > 0 then
        bits = bits | (1 << #ORIGINALS) -- Akrisae
    end
    if values.linzaKilled == 1 then
        bits = bits | LINZA_BIT
    end
    return chestKey(bits)
end

local function lootReads()
    local reads = { killedCount = VARS.killedCount, linzaKilled = VARS.linzaKilled }
    for _, b in ipairs(ORIGINALS) do
        reads[b.name] = VARS.killed .. b.varName
    end
    return reads
end

local function logItems()
    local items = {
        [AMULET] = { log = VARS.log .. "AMULET" },
    }
    for _, b in ipairs({ AKRISAE, LINZA, table.unpack(ORIGINALS) }) do
        for itemID, log in pairs(b.items) do
            items[itemID] = { log = log }
        end
    end
    return items
end

return {
    key = "barrows",
    name = "Barrows Brothers",
    assumptions = { "Amulet of the forsaken chance from complete and partial runs" },

    killCounts = { { var = VARS.kc } }, -- counted per chest looted, through its kill event
    modes = MODES,
    killEvents = { { var = VARS.run, mask = LOOTED, reads = lootReads(), mode = chestLooted } },
    unit = "chest", -- luck counts chests looted, not kills
    extraKills = "partial", -- what tracked chests outside the kill count are called

    items = logItems(),
}

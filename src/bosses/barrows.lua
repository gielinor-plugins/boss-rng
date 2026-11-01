-- Barrows brothers. Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28. With n
-- brothers killed (Linza not counted), a chest rolls min(n + 1, 7) times for a killed
-- brother's item; Linza adds her own roll. The amulet's rate is from Jagex's Late-Game
-- Rebalance design preview, which doesn't say whether partial chests roll it, so they're
-- assumed to. Each chest counts as looted, for a mode
-- named by the brothers killed. The kill count only counts chests with 6+ brothers.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_BARROWS", -- chests with 6 or more brothers, Akrisae counting (Linza not)
    run = "BARROWS", -- the run's tunnels and chest
    killed = "BARROWS_KILLED_", -- 1 if that original brother was killed this run, by name
    killedCount = "BARROWS_KILLED_COUNT", -- brothers killed this run, Akrisae and Linza included
    linzaKilled = "SISTER_KILLED_LINZA", -- 1 if Linza was killed this run
    log = "ITEMLOG_ITEM_BARROWS_", -- each item's log count, by brother and piece
}
local LOOTED = 0x4000000 -- the bit of VARS.run set when the chest is looted (no varbit name)

local function pieceChance(n, r)
    return 1 / math.max(r.pieceBase - r.piecePerBrother * n, r.pieceBest)
end

local FULL_CHEST = 6 -- the fewest brothers (Linza not counted) for the kill count
local CHEST = "Chest: " -- tracked chests' mode names start with this

local AMULET = 39061 -- Amulet of the forsaken
local SIGIL = 36156 -- Corruption sigil

-- A brother: name (as in mode names), name in game vars, items { [item id] = log var }.
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
        [4708] = "HEAD", [4712] = "BODY", [4714] = "LEGS", [4710] = "STAFF", [25652] = "WAND", [25672] = "OFFHAND" }),
    brother("Dharok", "DHAROK", { [4716] = "HEAD", [4720] = "BODY", [4722] = "LEGS", [4718] = "AXE" }),
    brother("Guthan", "GUTHAN", { [4724] = "HEAD", [4728] = "BODY", [4730] = "LEGS", [4726] = "SPEAR" }),
    brother("Karil", "KARIL", { -- coif, top, skirt, crossbow, pistol crossbows
        [4732] = "HEAD", [4736] = "BODY", [4738] = "LEGS", [4734] = "CROSSBOW", [25918] = "PISTOL",
        [25895] = "PISTOL_OFFHAND" }),
    brother("Torag", "TORAG", { [4745] = "HEAD", [4749] = "BODY", [4751] = "LEGS", [4747] = "HAMMER" }),
    brother("Verac", "VERAC", { [4753] = "HEAD", [4757] = "BODY", [4759] = "LEGS", [4755] = "FLAIL" }),
}
local AKRISAE = brother("Akrisae", "AKRISAE", { [21736] = "HEAD", [21752] = "BODY", [21760] = "LEGS", [21744] = "MACE" })
local LINZA = brother("Linza", "SISTER", { -- helm, cuirass, greaves, hammer, shield
    [37433] = "HEAD", [37437] = "BODY", [37441] = "LEGS", [37445] = "HAMMER", [37449] = "SHIELD" })

-- The brothers sharing the equipment rolls, in mode name order.
local BROTHERS = { table.unpack(ORIGINALS) }
table.insert(BROTHERS, AKRISAE)

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

-- CHEST, then the brothers in BROTHERS' order, then Linza. Saved: never change the format.
local function chestName(brothers, linza)
    local names = {}
    for _, b in ipairs(brothers) do
        table.insert(names, b.name)
    end
    if linza then
        table.insert(names, LINZA.name)
    end
    return CHEST .. table.concat(names, ", ")
end

local function chestMode(name)
    local killed = {}
    for b in name:sub(#CHEST + 1):gmatch("[^, ]+") do
        killed[b] = true
    end
    local brothers = {}
    for _, b in ipairs(BROTHERS) do
        if killed[b.name] then
            table.insert(brothers, b)
        end
    end
    local kc = #brothers >= FULL_CHEST and VARS.kc or nil
    local linza = killed[LINZA.name]
    local function rolls(r)
        return chestRolls(brothers, linza, r)
    end
    return { name = name, kc = kc, rolls = rolls }
end

-- Read as the chest is looted, not as it opens: the first search brings out the tunnel
-- brother, who isn't dead yet. Akrisae is the count less the others.
local function chestLooted(values)
    local brothers = {}
    for _, b in ipairs(ORIGINALS) do
        if values[b.name] == 1 then
            table.insert(brothers, b)
        end
    end
    if values.killedCount - #brothers - values.linzaKilled > 0 then
        table.insert(brothers, AKRISAE)
    end
    return chestName(brothers, values.linzaKilled == 1)
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
        [AMULET] = { log = VARS.log .. "AMULET", kind = "unique" },
        [SIGIL] = { kind = "excluded" }, -- only with a dragon defender or better
    }
    for _, b in ipairs({ AKRISAE, LINZA, table.unpack(ORIGINALS) }) do
        for itemID, log in pairs(b.items) do
            items[itemID] = { log = log, kind = "unique" }
        end
    end
    return items
end

return {
    key = "barrows", -- saved data key: never change it
    name = "Barrows brothers",
    assumptions = { "Amulet of the forsaken from partial chests too" },

    -- Counted only through its kill event: each chest gets its own mode.
    modes = {
        { name = "Normal", kc = VARS.kc, byEvent = true },
    },
    killEvents = { { var = VARS.run, mask = LOOTED, reads = lootReads(), mode = chestLooted } },
    modeFor = chestMode,
    extraKills = "partial", -- tracked chests outside the kill count

    items = logItems(),
}

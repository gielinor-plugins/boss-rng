-- The Barrows brothers (a chest is a kill: the kill count only counts chests
-- with all six original brothers killed).
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28: with N brothers
-- killed (Linza not counted), a chest makes min(N + 1, 7) rolls, each a
-- 1/max(450 - 58N, 73) chance of Barrows equipment. A hit picks one of the killed
-- brothers evenly, then one of their items evenly, so a brother with more items
-- (Ahrim, Karil) gives each one a smaller share. Linza, if killed, adds one roll at
-- 1/96 for one of her five items.
--
-- The kill count can't tell which chests had Akrisae or Linza, or count chests
-- with fewer brothers (whose pieces still count in the boss log), so the player
-- picks each share. Partial chests are assumed to have 3 of the 6 original
-- brothers, any 3 equally likely.

local common = require("src/bosses/common")

-- A brother's items, { [item id] = log count varbit }, from the part of each
-- varbit's name after the brother's.
local function brother(name, pieces)
    local items = {}
    for itemID, piece in pairs(pieces) do
        items[itemID] = "ITEMLOG_ITEM_BARROWS_" .. name .. "_" .. piece
    end
    return items
end

local AHRIM = brother("AHRIM", { -- hood, top, skirt, staff, wand, book
    [4708] = "HEAD", [4712] = "BODY", [4714] = "LEGS", [4710] = "STAFF", [25652] = "WAND", [25672] = "OFFHAND" })
local DHAROK = brother("DHAROK", { [4716] = "HEAD", [4720] = "BODY", [4722] = "LEGS", [4718] = "AXE" })
local GUTHAN = brother("GUTHAN", { [4724] = "HEAD", [4728] = "BODY", [4730] = "LEGS", [4726] = "SPEAR" })
local KARIL = brother("KARIL", { -- coif, top, skirt, crossbow, pistol crossbow, off-hand pistol crossbow
    [4732] = "HEAD", [4736] = "BODY", [4738] = "LEGS", [4734] = "CROSSBOW", [25918] = "PISTOL",
    [25895] = "PISTOL_OFFHAND" })
local TORAG = brother("TORAG", { [4745] = "HEAD", [4749] = "BODY", [4751] = "LEGS", [4747] = "HAMMER" })
local VERAC = brother("VERAC", { [4753] = "HEAD", [4757] = "BODY", [4759] = "LEGS", [4755] = "FLAIL" })
local AKRISAE = brother("AKRISAE", { [21736] = "HEAD", [21752] = "BODY", [21760] = "LEGS", [21744] = "MACE" })
local LINZA = brother("SISTER", { -- helm, cuirass, greaves, hammer, shield
    [37433] = "HEAD", [37437] = "BODY", [37441] = "LEGS", [37445] = "HAMMER", [37449] = "SHIELD" })

local ORIGINALS = { AHRIM, DHAROK, GUTHAN, KARIL, TORAG, VERAC }
local WITH_AKRISAE = { AHRIM, DHAROK, GUTHAN, KARIL, TORAG, VERAC, AKRISAE }

-- A roll's item weights when it picks one of brothers evenly, then one of that
-- brother's items evenly.
local function pieces(brothers)
    local weights = {}
    for _, items in ipairs(brothers) do
        local count = 0
        for _ in pairs(items) do
            count = count + 1
        end
        for itemID in pairs(items) do
            weights[itemID] = 1 / count
        end
    end
    return weights
end

-- A chest with n brothers killed (not counting Linza), from brothers: its rolls,
-- each happening share of the time, added to rolls (none at a share of 0, so
-- items it can't give aren't listed).
local function chest(rolls, n, brothers, share)
    if share > 0 then
        local roll = { chance = share / math.max(450 - 58 * n, 73), items = pieces(brothers) }
        common.Repeat(rolls, math.min(n + 1, 7), roll)
    end
end

-- The choices, each a percentage of the kill count's chests (partial chests come
-- on top). Their keys are saved data keys: never change them.
local function share(key, label, default, values)
    return { key = key, label = label, default = default, options = common.Percentages(values) }
end
local SHARES = { 0, 5, 10, 25, 50, 75, 100 }
local AKRISAE_SHARE = share("akrisae", "Chests with Akrisae killed", 100, SHARES)
local LINZA_SHARE = share("linza", "Chests with Linza killed", 100, SHARES)
local PARTIAL_SHARE = share("partial", "Partial chests, % of kill count", 0, { 0, 1, 5, 10, 25, 50, 100 })

-- Every item on the boss log page, with its log count varbit and kind (see
-- src/bosses/kreearra.lua for what each kind means).
local items = {
    [36156] = { kind = "excluded" }, -- Corruption sigil: only with a dragon defender or better
    [39061] = { log = "ITEMLOG_ITEM_BARROWS_AMULET", kind = "excluded" }, -- Amulet of the forsaken: no published rate
}
for _, brotherItems in ipairs({ AHRIM, DHAROK, GUTHAN, KARIL, TORAG, VERAC, AKRISAE, LINZA }) do
    for itemID, log in pairs(brotherItems) do
        items[itemID] = { log = log, kind = "unique" }
    end
end

return {
    key = "barrows", -- saved data key: never change it
    name = "Barrows brothers",
    logPage = "COLLECTION_BOSS_BARROWS", -- the boss log page's database row
    assumptions = { "Partial chests: 3 of 6 brothers" },
    choices = { AKRISAE_SHARE, LINZA_SHARE, PARTIAL_SHARE },

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = "BSLAY_KILLS_BARROWS", rolls = function(picks)
            local akrisae, linza, partial = picks.akrisae / 100, picks.linza / 100, picks.partial / 100
            local rolls = {}
            chest(rolls, 7, WITH_AKRISAE, akrisae)
            chest(rolls, 6, ORIGINALS, 1 - akrisae)
            chest(rolls, 3, ORIGINALS, partial)
            if linza > 0 then
                table.insert(rolls, { chance = linza / 96, items = pieces({ LINZA }) })
            end
            return rolls
        end },
    },

    items = items,
}

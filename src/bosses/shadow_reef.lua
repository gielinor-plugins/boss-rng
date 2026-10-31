-- The Shadow Reef (elite dungeon 3): only the Ambassador's Eldritch crossbow
-- pieces are tracked, so only its kills are counted.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-31: each kill rolls
-- for a crossbow piece, per player, at 1/55 solo, 1/111 duo and 1/166 trio. The
-- first piece is random and each next one is a piece not yet received, so they're
-- shown as one group. Solo and group kills are counted as in
-- src/bosses/elite_dungeon.lua.

local common = require("src/bosses/common")
local eliteDungeon = require("src/bosses/elite_dungeon")

local VARS = {
    kc = "BSLAY_KILLS_DUNGEON_ULTHVEN3", -- the Ambassador (Ulthven is the Shadow Reef)
    log = "ITEMLOG_ITEM_DUNGEON_2H_RANGED_", -- each piece's log count, by its name
}

local LIMB, MECHANISM, STOCK = 47490, 47494, 47492
local PIECES = common.Even({ LIMB, MECHANISM, STOCK })
local CROSSBOW = { name = "Crossbow pieces" }

-- A kill's piece roll at rate values r, for a team's rate name.
local function pieces(team)
    return function(r)
        return { { chance = r[team], items = PIECES } }
    end
end

local dungeon = eliteDungeon.New()
dungeon.Add("The Ambassador", VARS.kc, pieces)

return {
    key = "shadow_reef", -- saved data key: never change it
    name = "The Shadow Reef",
    logPage = "COLLECTION_BOSS_DUNGEON_ULTHVEN", -- the boss log page's database row
    assumptions = { eliteDungeon.ASSUMPTION },
    modes = dungeon.modes, -- the group kill count's mode is counted only through its kill event
    killEvents = dungeon.killEvents,
    modeFor = dungeon.ModeFor,

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [LIMB] = { log = VARS.log .. "LIMB", kind = "unique", group = CROSSBOW },
        [MECHANISM] = { log = VARS.log .. "MECHANISM", kind = "unique", group = CROSSBOW },
        [STOCK] = { log = VARS.log .. "STOCK", kind = "unique", group = CROSSBOW },
        [47506] = { kind = "excluded" }, -- Black stone heart: a common drop
        [47468] = { kind = "lore" }, -- The Last Offering
        [47469] = { kind = "lore" }, -- Kranon's Ancient Journal
        [47537] = { kind = "pet" }, -- Ambi
    },
}

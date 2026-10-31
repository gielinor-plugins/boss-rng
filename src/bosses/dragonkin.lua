-- The Dragonkin Laboratory (elite dungeon 2): Astellarn, Verak Lith and the
-- Black stone dragon, as one entry with modes for each boss's solo and group kills.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28: each boss drops
-- its own codex, per player, at 1/83 solo, 1/166 duo and 1/250 trio. Solo and
-- group kills are counted as in src/bosses/elite_dungeon.lua.

local eliteDungeon = require("src/bosses/elite_dungeon")

local VARS = {
    kc = "BSLAY_KILLS_DUNGEON_DRAGONFORT", -- then the boss's number
    log = "ITEMLOG_ITEM_DUNGEON_MELEE_CODEX_", -- each codex's log count, by its name
}

local FLURRY, FURY, BARGE = 43391, 43389, 43393

-- A kill's codex roll at rate values r, for a team's rate name.
local function codex(item)
    return function(team)
        return function(r)
            return { { chance = r[team], items = { [item] = 1 } } }
        end
    end
end

local dungeon = eliteDungeon.New()
dungeon.Add("Astellarn", VARS.kc .. 1, codex(FLURRY))
dungeon.Add("Verak Lith", VARS.kc .. 2, codex(FURY))
dungeon.Add("Black stone dragon", VARS.kc .. 3, codex(BARGE))

return {
    key = "dragonkin", -- saved data key: never change it
    name = "Dragonkin Laboratory",
    logPage = "COLLECTION_BOSS_DUNGEON_DRAGONFORT", -- the boss log page's database row
    assumptions = { eliteDungeon.ASSUMPTION },
    modes = dungeon.modes, -- each group kill count's mode is counted only through its kill event
    killEvents = dungeon.killEvents,
    modeFor = dungeon.ModeFor,

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [FLURRY] = { log = VARS.log .. "FLURRY", kind = "unique" },
        [FURY] = { log = VARS.log .. "FURY", kind = "unique" },
        [BARGE] = { log = VARS.log .. "BARGE", kind = "unique" },
        [43373] = { kind = "lore" }, -- Redacted Dragonkin Research
        [43374] = { kind = "lore" }, -- Diary of an Overzealous Gnome
        [43165] = { kind = "excluded" }, -- Draconic energy: a common drop
        [47548] = { kind = "pet" }, -- Bisdi
    },
}

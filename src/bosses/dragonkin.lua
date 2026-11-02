-- Dragonkin Laboratory: three bosses, each dropping its own codex. Rates: RuneScape Wiki
-- (CC BY-NC-SA 3.0), checked 2026-10-28. Kills count as in src/bosses/elite_dungeon.lua.

local eliteDungeon = require("src/bosses/elite_dungeon")

local VARS = {
    kc = "BSLAY_KILLS_DUNGEON_DRAGONFORT", -- then the boss's number
    log = "ITEMLOG_ITEM_DUNGEON_MELEE_CODEX_", -- each codex's log count, by its name
}

local FLURRY, FURY, BARGE = 43391, 43389, 43393

-- codex(item)(team)(r): one roll at the team's rate.
local function codex(item)
    return function(team)
        return function(r)
            return { { chance = r[team], items = { [item] = 1 } } }
        end
    end
end

local dungeon = eliteDungeon.New()
dungeon.Add("a", VARS.kc .. 1, codex(FLURRY)) -- Astellarn
dungeon.Add("v", VARS.kc .. 2, codex(FURY)) -- Verak Lith
dungeon.Add("b", VARS.kc .. 3, codex(BARGE)) -- the Black stone dragon

return {
    key = "dragonkin", -- saved data key: never change it
    name = "Dragonkin Laboratory",
    assumptions = { eliteDungeon.ASSUMPTION },
    modes = dungeon.modes, -- each group kill count's mode is counted only through its kill event
    killEvents = dungeon.killEvents,
    modeFor = dungeon.ModeFor,

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

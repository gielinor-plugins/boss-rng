-- The Dragonkin Laboratory (elite dungeon 2): Astellarn, Verak Lith and the
-- Black stone dragon, as one entry with a mode for each boss's solo and group kills.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28: each boss drops
-- its own codex, per player, at 1/83 solo, 1/166 duo and 1/250 trio. The game
-- counts each boss's solo and group kills apart, but not a group's size, so the
-- player picks it.

local common = require("src/bosses/common")

local FLURRY, FURY, BARGE = 43391, 43389, 43393

local GROUP = common.Team("group", "Group kills done", { "duo", "trio", "duoTrio" }) -- saved data key: never change it

-- A boss's solo and group modes, for its kill count vars and codex.
-- Mode names are saved with the player's data: never change them.
local function boss(name, kc, codex)
    return {
        { name = name .. ", solo", kc = kc .. "_SOLO", rolls = { { chance = 1 / 83, items = { [codex] = 1 } } } },
        { name = name .. ", group", kc = kc, rolls = function(picks)
            return { { chance = common.TeamMix(picks.group, 0, 1 / 166, 1 / 250), items = { [codex] = 1 } } }
        end },
    }
end

local modes = {}
for _, pair in ipairs({
    boss("Astellarn", "BSLAY_KILLS_DUNGEON_DRAGONFORT1", FLURRY),
    boss("Verak Lith", "BSLAY_KILLS_DUNGEON_DRAGONFORT2", FURY),
    boss("Black stone dragon", "BSLAY_KILLS_DUNGEON_DRAGONFORT3", BARGE),
}) do
    table.move(pair, 1, #pair, #modes + 1, modes)
end

return {
    key = "dragonkin", -- saved data key: never change it
    name = "Dragonkin Laboratory",
    logPage = "COLLECTION_BOSS_DUNGEON_DRAGONFORT", -- the boss log page's database row
    assumptions = {},
    choices = { GROUP },
    modes = modes,

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [FLURRY] = { log = "ITEMLOG_ITEM_DUNGEON_MELEE_CODEX_FLURRY", kind = "unique" },
        [FURY] = { log = "ITEMLOG_ITEM_DUNGEON_MELEE_CODEX_FURY", kind = "unique" },
        [BARGE] = { log = "ITEMLOG_ITEM_DUNGEON_MELEE_CODEX_BARGE", kind = "unique" },
        [43373] = { kind = "lore" }, -- Redacted Dragonkin Research
        [43374] = { kind = "lore" }, -- Diary of an Overzealous Gnome
        [43165] = { kind = "excluded" }, -- Draconic energy: a common drop
        [47548] = { kind = "pet" }, -- Bisdi
    },
}

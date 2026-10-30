-- The Dragonkin Laboratory (elite dungeon 2): Astellarn, Verak Lith and the
-- Black stone dragon, as one entry with modes for each boss's solo and group kills.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28: each boss drops
-- its own codex, per player, at 1/83 solo, 1/166 duo and 1/250 trio (teams are
-- at most three). The game counts each boss's solo and group kills apart, and
-- each tracked group kill counts for a mode by the players at the kill.

local VARS = {
    kc = "BSLAY_KILLS_DUNGEON_DRAGONFORT", -- then the boss's number; _SOLO for solo kills
    players = "DUNGEON_PLAYERS_AT_BOSS_KILL", -- players in the room at the kill
    log = "ITEMLOG_ITEM_DUNGEON_MELEE_CODEX_", -- each codex's log count, by its name
}

local FLURRY, FURY, BARGE = 43391, 43389, 43393

-- The codex's rate names by players at the kill (see src/rates/base.lua).
local TEAMS = { "solo", "duo", "trio" }

-- A kill's codex roll at rate values r, for its team's rate name.
local function codex(team, item)
    return function(r)
        return { { chance = r[team], items = { [item] = 1 } } }
    end
end

-- Tracked group kills' modes, by name ("Astellarn, 2 players"). Mode names are
-- saved with the player's data: never change them.
local tracked = {}

-- A tracked group kill's mode name: 0 players (not read yet) leaves the kill
-- uncounted, and more than 3 count as 3.
local function playersMode(name, players)
    if players < 1 then
        return nil
    end
    players = math.min(players, #TEAMS)
    return name .. ", " .. players .. (players == 1 and " player" or " players")
end

local modes, killEvents = {}, {}

-- Adds a boss's solo and group modes, for its number and codex.
local function boss(name, number, item)
    local kc = VARS.kc .. number
    table.insert(modes, { name = name .. ", solo", kc = kc .. "_SOLO", rolls = codex(TEAMS[1], item) })
    table.insert(modes, { name = name .. ", group", kc = kc, byEvent = true })
    for players, team in ipairs(TEAMS) do
        local modeName = playersMode(name, players)
        tracked[modeName] = { name = modeName, kc = kc, rolls = codex(team, item) }
    end
    table.insert(killEvents, { var = kc, reads = { players = VARS.players }, mode = function(values)
        return playersMode(name, values.players)
    end })
end

boss("Astellarn", 1, FLURRY)
boss("Verak Lith", 2, FURY)
boss("Black stone dragon", 3, BARGE)

return {
    key = "dragonkin", -- saved data key: never change it
    name = "Dragonkin Laboratory",
    logPage = "COLLECTION_BOSS_DUNGEON_DRAGONFORT", -- the boss log page's database row
    assumptions = {},
    modes = modes, -- each group kill count's mode is counted only through its kill event
    killEvents = killEvents,
    modeFor = function(name) return tracked[name] end,

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

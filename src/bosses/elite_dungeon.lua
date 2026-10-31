-- What the elite dungeons share. Not a boss file: the Dragonkin Laboratory and
-- the Shadow Reef use it for their bosses' kill counts and team sizes.
--
-- The game counts each boss's solo and group kills apart. A tracked group kill
-- counts for a mode by the players in the dungeon at the kill (teams are at most
-- three), read as its group kill count goes up. A teammate who sits out a boss
-- but stays in the dungeon still counts, so that's an assumption.

local eliteDungeon = {}

eliteDungeon.ASSUMPTION = "Group rates use everyone in the dungeon"

local PLAYERS = "DUNGEON_PLAYERS_AT_BOSS_KILL" -- players in the dungeon at the kill
local TEAMS = { "solo", "duo", "trio" } -- rate names by players (see src/rates/base.lua)

-- A tracked group kill's mode name ("Astellarn, 2 players"): 0 players (not read
-- yet) leaves the kill uncounted, and more than 3 count as 3. Mode names are
-- saved with the player's data: never change them.
local function playersMode(name, players)
    if players < 1 then
        return nil
    end
    players = math.min(players, #TEAMS)
    return name .. ", " .. players .. (players == 1 and " player" or " players")
end

-- A dungeon's modes, kill events and tracked group kills' modes, filled by Add.
function eliteDungeon.New()
    local dungeon = { modes = {}, killEvents = {}, tracked = {} }

    -- Adds a boss's solo and group modes, for its kill count var (the solo one
    -- has "_SOLO" after it) and its rolls for a team's rate name, rolls(team)(r).
    function dungeon.Add(name, kc, rolls)
        table.insert(dungeon.modes, { name = name .. ", solo", kc = kc .. "_SOLO", rolls = rolls(TEAMS[1]) })
        table.insert(dungeon.modes, { name = name .. ", group", kc = kc, byEvent = true })
        for players, team in ipairs(TEAMS) do
            local modeName = playersMode(name, players)
            dungeon.tracked[modeName] = { name = modeName, kc = kc, rolls = rolls(team) }
        end
        table.insert(dungeon.killEvents, { var = kc, reads = { players = PLAYERS }, mode = function(values)
            return playersMode(name, values.players)
        end })
    end

    function dungeon.ModeFor(name)
        return dungeon.tracked[name]
    end

    return dungeon
end

return eliteDungeon

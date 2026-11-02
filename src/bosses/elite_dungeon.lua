-- Shared by the elite dungeons. Not a boss file. The game counts solo and group kills
-- apart; a group kill counts by the players in the dungeon at the kill, so a teammate
-- who sits out a boss still counts (an assumption).

local eliteDungeon = {}

eliteDungeon.ASSUMPTION = "Teammates who sit out a boss still affect its drop rate"

local PLAYERS = "DUNGEON_PLAYERS_AT_BOSS_KILL" -- players in the dungeon at the kill
local TEAMS = { "solo", "duo", "trio" } -- rate names by players (see src/core/rates/base.lua)

-- "Astellarn, 2 players": 0 (not read yet) skips the kill, over 3 counts as 3.
-- Mode names are saved: never change them.
local function playersMode(name, players)
    if players < 1 then
        return nil
    end
    players = math.min(players, #TEAMS)
    return name .. ", " .. players .. (players == 1 and " player" or " players")
end

function eliteDungeon.New()
    local dungeon = { modes = {}, killEvents = {}, tracked = {} }

    -- The solo kill count is kc .. "_SOLO"; rolls(team)(r) gives a team's rolls.
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

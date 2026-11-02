-- Shared by the elite dungeons. Not a boss file. The game counts solo and group kills
-- apart; a group kill counts by the players in the dungeon at the kill, so a teammate
-- who sits out a boss still counts (an assumption).

local eliteDungeon = {}

eliteDungeon.ASSUMPTION = "Teammates who sit out a boss still affect its drop rate"

local PLAYERS = "DUNGEON_PLAYERS_AT_BOSS_KILL" -- players in the dungeon at the kill
local TEAMS = { "solo", "duo", "trio" } -- rate names by players (see src/core/rates/base.lua)

-- A boss's group mode by players ("a2" for 2 at boss a): 0 (not read yet) skips the
-- kill, over 3 counts as 3. Mode keys are saved: never change them.
local function playersMode(id, players)
    if players < 1 then
        return nil
    end
    return id .. math.min(players, #TEAMS)
end

function eliteDungeon.New()
    local dungeon = { modes = {}, killEvents = {}, tracked = {} }

    -- A boss by id (a short saved key: never change it). Its solo kill count is
    -- kc .. "_SOLO"; rolls(team)(r) gives a team's rolls.
    function dungeon.Add(id, kc, rolls)
        table.insert(dungeon.modes, { key = id .. "s", kc = kc .. "_SOLO", rolls = rolls(TEAMS[1]) })
        table.insert(dungeon.modes, { key = id .. "g", kc = kc, byEvent = true })
        for players, team in ipairs(TEAMS) do
            local key = playersMode(id, players)
            dungeon.tracked[key] = { key = key, kc = kc, rolls = rolls(team) }
        end
        table.insert(dungeon.killEvents, { var = kc, reads = { players = PLAYERS }, mode = function(values)
            return playersMode(id, values.players)
        end })
    end

    function dungeon.ModeFor(key)
        return dungeon.tracked[key]
    end

    return dungeon
end

return eliteDungeon

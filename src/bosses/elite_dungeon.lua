-- Shared by the elite dungeons. Not a boss file. The game counts solo and group kills
-- apart; a group kill counts by the players in the dungeon at the kill, so a teammate
-- who sits out a boss still counts (an assumption).

local eliteDungeon = {}

eliteDungeon.ASSUMPTION = "Teammates who sit out a boss still affect its drop rate"

local PLAYERS = "DUNGEON_PLAYERS_AT_BOSS_KILL" -- players in the dungeon at the kill
local TEAMS = { "solo", "duo", "trio" } -- rate names by players (see src/core/rates/base.lua)

-- A boss's group mode key for the players at the kill, such as "a2" for 2 at boss a. 0
-- players (not read yet) leaves the kill uncounted, and more than 3 count as 3.
local function playersMode(id, players)
    if players < 1 then
        return nil
    end
    return id .. math.min(players, #TEAMS)
end

-- A dungeon's killCounts, modes and killEvents, filled in by Add.
function eliteDungeon.New()
    local dungeon = { killCounts = {}, modes = {}, killEvents = {} }

    -- Adds a boss. id starts its mode keys: its solo kill count is kc .. "_SOLO",
    -- saved as mode id .. "s"; its group kills are counted by the players at the kill.
    -- rolls(team)(r) gives a team's rolls.
    function dungeon.Add(id, kc, rolls)
        table.insert(dungeon.killCounts, { var = kc .. "_SOLO", mode = id .. "s" })
        table.insert(dungeon.killCounts, { var = kc })
        dungeon.modes[id .. "s"] = { rolls = rolls(TEAMS[1]) }
        for players, team in ipairs(TEAMS) do
            dungeon.modes[playersMode(id, players)] = { rolls = rolls(team) }
        end
        table.insert(dungeon.killEvents, {
            var = kc,
            reads = { players = PLAYERS },
            mode = function(values)
                return playersMode(id, values.players)
            end,
        })
    end

    return dungeon
end

return eliteDungeon

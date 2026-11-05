-- The player's loot piles at a kill (killEvents' pileItems in src/bosses.lua): each tile
-- where a ground stack the player owns gained a watched item this batch is one pile.
-- The game marks who owns each stack, so a teammate's piles are never counted.
-- A batch is what game_vars reports at once (QUIET_TICKS in src/core/game_vars.lua).

local piles = {}

local watched = {} -- [item id] = true
local tiles = {} -- [tile as text] = true, this batch's

function piles.Watch(itemIDs)
    for _, itemID in ipairs(itemIDs) do
        watched[itemID] = true
    end
end

local function gained(event, count)
    if event.isOwner and count > 0 and watched[event.objType.id] then
        tiles[tostring(event.objStackEntity.coordGrid)] = true
    end
end

function piles.OnAdded(event)
    gained(event, event.count)
end

function piles.OnChanged(event)
    gained(event, event.newCount - event.oldCount)
end

-- The piles seen this batch.
function piles.Count()
    local count = 0
    for _ in pairs(tiles) do
        count = count + 1
    end
    return count
end

function piles.EndBatch()
    tiles = {}
end

function piles.Clear()
    watched, tiles = {}, {}
end

return piles

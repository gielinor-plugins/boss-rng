-- Loot kept in an item to open later (see containers in src/bosses.lua): each
-- one opened counts as a kill, seen as the backpack's count of it falling in
-- the tick a reward window opens. Banking one lowers the count too, but opens
-- no reward window.

local containers = {}

local byItem = {} -- [item id] = { window, report }
local held = {} -- the backpack's count of each, as last read
local opening = { windows = {}, fell = {} } -- this tick's windows opened (by inventory name) and counts that fell (by item id)

-- Watches itemID, opened with reward window (an inventory name). report(count)
-- is called for each tick's openings.
function containers.Add(itemID, window, report)
    byItem[itemID] = { window = window, report = report }
end

-- The backpack's count of each container, or nil if it can't be read.
local function readHeld()
    local backpack = Inventory.Find(config.Inv.INV)
    if backpack == nil or not backpack.isValid then
        return nil
    end
    local counts = {}
    for itemID in pairs(byItem) do
        counts[itemID] = backpack:GetTotal(itemID)
    end
    return counts
end

-- Notes containers leaving the backpack, and any other inventory opening.
function containers.OnInventory(event)
    if event.inv.id == config.Inv.INV.id then
        for itemID, count in pairs(readHeld() or {}) do
            local fell = (held[itemID] or count) - count
            if fell > 0 then
                opening.fell[itemID] = (opening.fell[itemID] or 0) + fell
            end
            held[itemID] = count
        end
    else
        local name = event.inv.configName
        opening.windows[name] = (opening.windows[name] or 0) + 1
    end
end

-- Passes this tick's openings to queue(report, count): each container that left
-- the backpack in the tick its reward window opened, one per window.
function containers.EndTick(queue)
    for itemID, fell in pairs(opening.fell) do
        local container = byItem[itemID]
        local opened = math.min(fell, opening.windows[container.window] or 0)
        if opened > 0 then
            queue(container.report, opened)
            opening.windows[container.window] = opening.windows[container.window] - opened
        end
    end
    opening = { windows = {}, fell = {} }
end

-- Once vars can be trusted: reads the backpack's counts afresh.
function containers.Ready()
    held = readHeld() or {}
end

-- On leaving the game: forgets the counts, maybe of another character.
function containers.Forget()
    held = {}
end

function containers.Clear()
    byItem, held, opening = {}, {}, { windows = {}, fell = {} }
end

return containers

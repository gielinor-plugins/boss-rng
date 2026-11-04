-- Loot kept in an item to open later (containers in src/bosses.lua). Each one opened is
-- a kill, seen as its backpack count falling in the tick a reward window opens.
-- Banking one lowers the count too, but opens no reward window.

local containers = {}

local byItem = {} -- [item id] = { window, report }
local held = {} -- the backpack's count of each, as last read
-- This tick's windows opened (by inventory name) and counts that fell (by item id)
local opening = { windows = {}, fell = {} }

-- Watches itemID, opened with window (an inventory name); report(count) per tick.
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

-- Notes a container's backpack count falling, or any other inventory opening (a reward
-- window).
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

-- Passes this tick's openings to queue(report, count), one per window.
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

function containers.Ready()
    held = readHeld() or {}
end

-- On leaving the game: the next login may be another character.
function containers.Forget()
    held = {}
end

function containers.Clear()
    byItem, held, opening = {}, {}, { windows = {}, fell = {} }
end

return containers

-- The dropdowns for a boss's picks (see src/choices.lua), as plain data, for
-- the views to draw: { label, options, current, onPick } each. Plain Lua, so it
-- can be tested offline.
--
-- Picks that only change kills without Boss RNG (choices with untrackedOnly,
-- and splits of pooled uniques' drops without Boss RNG) go on the settings
-- page. The rest stay in the Details window until they're moved boss by boss.

local format = require("src/format")

local pickers = {}

local SETTINGS_PATH = "Plugin Hub > Manage > Boss RNG settings"

-- The game's name for an item, or its id if that can't be read.
function pickers.ItemName(itemID)
    local ok, name = pcall(function() return config.Obj.FromID(math.tointeger(itemID)).name end)
    return ok and name or ("Item " .. tostring(itemID))
end

-- A pooled unique's drops: "Shard drops".
function pickers.Drops(itemID, item)
    return (item.short or pickers.ItemName(itemID)) .. " drops"
end

-- A boss's kills without Boss RNG, for its settings page section: "280
-- untracked kills", or a note until the game is read.
function pickers.UntrackedKills(entry)
    local count = entry.picks.untrackedKills
    if count == nil then
        return "Untracked kills not read yet"
    end
    return format.Number(count) .. (count == 1 and " untracked kill" or " untracked kills")
end

-- The dropdown for one of a boss's choices.
local function choicePicker(entry, choice, onChoose)
    return {
        label = choice.label,
        options = choice.options,
        current = entry.picks[choice.key],
        onPick = function(value) onChoose(entry.boss, choice, value) end,
    }
end

-- A dropdown per pooled unique (pools, see stats.Pools) whose drops without
-- Boss RNG the player can split, listing each count from 0, then "Not set".
-- onSplit(pool, itemID, boss, count or nil) saves a split.
local function splitPickers(entry, pools, onSplit)
    local list = {}
    for itemID, item in pairs(entry.boss.items) do
        local pool = pools[itemID]
        if pool and pool.ask then
            local options = {}
            for count = 0, pool.untracked do
                table.insert(options, { value = count, label = tostring(count) })
            end
            table.insert(options, { value = false, label = "Not set" })
            table.insert(list, {
                label = pickers.Drops(itemID, item) .. " from this boss (of " .. pool.untracked .. ")",
                options = options,
                current = pool.split and pool.split[entry.boss.key] or false,
                onPick = function(value) onSplit(pool, itemID, entry.boss, value or nil) end,
            })
        end
    end
    return list
end

-- The settings page's dropdowns for a boss (entry, see src/ui.lua): its
-- choices with untrackedOnly, then its pooled unique splits (see splitPickers).
-- onChoose(boss, choice, value) saves a pick.
function pickers.ForSettings(entry, pools, onChoose, onSplit)
    local list = {}
    for _, choice in ipairs(entry.boss.choices or {}) do
        if choice.untrackedOnly then
            table.insert(list, choicePicker(entry, choice, onChoose))
        end
    end
    for _, picker in ipairs(splitPickers(entry, pools, onSplit)) do
        table.insert(list, picker)
    end
    return list
end

-- The Details window's dropdowns for a boss: its other choices.
function pickers.ForDetails(entry, onChoose)
    local list = {}
    for _, choice in ipairs(entry.boss.choices or {}) do
        if not choice.untrackedOnly then
            table.insert(list, choicePicker(entry, choice, onChoose))
        end
    end
    return list
end

-- The assumptions' last line for a boss with picks on the settings page: where
-- to change them. Nil for a boss without.
function pickers.WhereToChange(entry, pools)
    local function noop() end
    if #pickers.ForSettings(entry, pools, noop, noop) == 0 then
        return nil
    end
    return "Change these in " .. SETTINGS_PATH
end

return pickers

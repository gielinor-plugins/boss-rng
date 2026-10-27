-- Boss RNG's ribbon panel: pick a boss and see its luck and dry streak.
-- All UI code lives in this file, using Jagex's native components only.

local bosses = require("src/bosses")
local format = require("src/format")
local safe = require("src/safe")
local stats = require("src/stats")
local tracker = require("src/tracker")

local bossUi = {}

local REF = "bossrng_ui"
local FONT = id.Font.MUSEO_SANS_15PT_REGULAR
local MARGIN = 5
local LINE_HEIGHT = 25

local layer = nil -- the ribbon panel, once the player has opened it
local drawn = {} -- components we created, removed before each redraw
local selectedKey = nil -- the boss picked in the dropdown
local lastKillKey = nil -- the last boss killed when the panel was drawn

-- Bosses with kills, each with its stats, the boss killed most recently first.
local function bossesWithKills()
    local list = {}
    for _, boss in ipairs(bosses) do
        local result = stats.ForBoss(boss, tracker.Tallies(boss))
        if result and result.kills > 0 then
            table.insert(list, { boss = boss, stats = result })
        end
    end
    local last = tracker.LastBossKey()
    table.sort(list, function(a, b)
        if (a.boss.key == last) ~= (b.boss.key == last) then
            return a.boss.key == last
        end
        return a.boss.name < b.boss.name
    end)
    return list
end

local function addText(content, y)
    local text = ui.Text.new(layer)
    text.font = FONT
    text.content = content
    text:SetPos(MARGIN, y)
    text:SetSize(0, 20, 1.0, 0.0) -- full width
    table.insert(drawn, text)
    return text
end

local function clear()
    for _, component in ipairs(drawn) do
        pcall(function() component:Destroy() end)
    end
    drawn = {}
end

local function draw()
    clear()
    -- A kill at another boss switches the panel to that boss.
    local last = tracker.LastBossKey()
    if last ~= lastKillKey then
        lastKillKey = last
        selectedKey = nil
    end
    local list = bossesWithKills()
    if #list == 0 then
        addText("No boss kills yet.", MARGIN)
        addText("Kill a supported boss to start.", MARGIN + LINE_HEIGHT)
        return
    end

    local selected = 1
    for i, entry in ipairs(list) do
        if entry.boss.key == selectedKey then
            selected = i
        end
    end

    -- Below the dropdown: the selected boss's dry streak and totals.
    local dry = addText(format.Dry(list[selected].stats), MARGIN + 35)
    local totals = addText(format.Totals(list[selected].stats), MARGIN + 35 + LINE_HEIGHT)

    -- Each entry carries its boss's luck, so bosses can be compared at a glance.
    local combo = ui.ComboField.new(layer)
    combo.stylesheetID = id.StyleSheet.COMBO_DEFAULT
    combo:SetPos(MARGIN, MARGIN)
    combo:SetSize(0, 25, 1.0, 0.0) -- full width
    for i, entry in ipairs(list) do
        combo:Add(entry.boss.name .. " · " .. format.Luck(entry.stats), i)
    end
    combo:Select(selected)
    -- A change fires twice: the old entry with 0, then the new one with 1.
    combo:Subscribe(ui.Hook.ONSELECTIONCHANGED, function(_, entryID, status)
        local entry = list[entryID]
        if status == 1 and entry then
            safe.Call("showing a boss", function()
                selectedKey = entry.boss.key
                dry.content = format.Dry(entry.stats)
                totals.content = format.Totals(entry.stats)
            end)
        end
    end)
    table.insert(drawn, combo)
end

-- Draws the panel if it has been opened. If drawing fails, shows one plain line
-- instead of half a panel.
local function redraw()
    if layer == nil then
        return
    end
    if not safe.Call("drawing the panel", draw) then
        clear()
        safe.Call("drawing the panel error", function()
            addText("Boss RNG couldn't draw this panel.", MARGIN)
        end)
    end
end

-- The game clears the panel and fires this each time it opens or is resized.
local function onContentLayerReady(event)
    layer = event.component
    drawn = {}
    redraw()
end

function bossUi.Start()
    tracker.OnChange(redraw)
    Event.ContentLayerReady.Subscribe(REF, onContentLayerReady)
end

function bossUi.Stop()
    Event.ContentLayerReady.Unsubscribe(REF)
    clear()
    layer = nil
end

return bossUi

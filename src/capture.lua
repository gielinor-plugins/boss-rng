-- Captures a boss's all-time totals while the game is showing them: its kill
-- counts while a Beasts tab page shows them (a boss with several fights may
-- have several pages), and its boss log counts while the boss log is open on
-- its page. Jagex's rule is that a var may only be used once
-- the game has shown that information to the player, so these are only read
-- while they're on screen. Checked once a second.

local gamevars = require("src/gamevars")
local safe = require("src/safe")

local capture = {}

local REF = "bossrng_capture"
local CHECK_EVERY_TICKS = 50 -- one second

local BEASTS_PANEL = "BSLAY_BOSS_INFO" -- the Beasts tab's boss panel
local BEASTS_NAME = 11 -- its boss name text
local BOSS_LOG = "COLLECTION_LOG"
local LOG_BOOK_VAR = "COLLECTION_LOG_DATA" -- the boss log's row in the game database
local LOG_PAGE_VAR = "COLLECTION_LOG_SELECTED" -- the open page's 0-based index
local PAGES_COLUMN = 8 -- the book row's list of page rows

local byName, byLogPage = {}, {} -- [Beasts tab name] = { boss, modes }; [page] = boss
local onKills, onLogCounts
local lastCheckTick = -math.huge

local function isOpen(interfaceName)
    return ui.Interfaces:GetInterface(id.Interface[interfaceName]) ~= nil
end

local function value(varName)
    return var.VarPlayer[varName].value
end

-- The page the Beasts tab panel shows, { boss, modes }, or nil. Its name may
-- carry color tags.
local function beastsPage()
    local text = ui.Interfaces:GetComponent(id.Interface[BEASTS_PANEL], BEASTS_NAME)
    if text == nil or text.type ~= ui.ComponentType.LABEL or text.hidden then
        return nil
    end
    return byName[(text.content:gsub("<[^>]*>", ""))]
end

-- The boss whose boss log page is open, or nil.
local function logBoss()
    local pages = value(LOG_BOOK_VAR):GetColumnValues(PAGES_COLUMN)
    local page = pages[value(LOG_PAGE_VAR) + 1]
    return page and byLogPage[page.configName]
end

-- The kill counts a Beasts tab page shows: { [kill count var] = kills }.
local function readKills(page)
    local kills = {}
    for _, mode in ipairs(page.modes) do
        kills[mode.kc] = value(mode.kc)
    end
    return kills
end

-- A boss's boss log count per unique: { [item id] = count }.
local function readLogCounts(boss)
    local counts = {}
    for itemID, item in pairs(boss.items) do
        if item.kind == "unique" then
            counts[itemID] = value(item.log)
        end
    end
    return counts
end

local function check()
    -- A kill or drop the game just sent is reported on the next tick. Reading now
    -- would count it twice: once here and once when it's reported.
    if gamevars.HasPending() then
        return
    end
    -- The boss log can open over the Beasts tab, which stays loaded behind it, so
    -- kill counts are only read while the boss log is closed.
    if isOpen(BOSS_LOG) then
        local boss = logBoss()
        if boss then
            onLogCounts(boss, readLogCounts(boss))
        end
    elseif isOpen(BEASTS_PANEL) then
        local page = beastsPage()
        if page then
            onKills(page.boss, readKills(page))
        end
    end
end

local function onLogic(event)
    if event.logicTick - lastCheckTick >= CHECK_EVERY_TICKS then
        lastCheckTick = event.logicTick
        safe.Call("capturing totals", check)
    end
end

-- Starts capturing for every boss in bosses (the list from src/bosses.lua):
--   kills(boss, { [kill count var] = kills })   while a Beasts tab page shows them
--   logCounts(boss, { [item id] = log count })   while its boss log page is open
-- Only unique items are captured. Modes are matched to Beasts tab pages by name:
-- the mode's beasts, else its boss's name.
function capture.Start(bosses, kills, logCounts)
    for _, boss in ipairs(bosses) do
        for _, mode in ipairs(boss.modes) do
            local name = mode.beasts or boss.name
            byName[name] = byName[name] or { boss = boss, modes = {} }
            table.insert(byName[name].modes, mode)
        end
        byLogPage[boss.logPage] = boss
    end
    onKills, onLogCounts = kills, logCounts
    Event.Logic.Subscribe(REF, onLogic)
end

function capture.Stop()
    Event.Logic.Unsubscribe(REF)
    byName, byLogPage = {}, {}
    lastCheckTick = -math.huge
end

return capture

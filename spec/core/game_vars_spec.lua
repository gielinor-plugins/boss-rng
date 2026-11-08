local mock = require("spec/mock_api")

-- A test boss, written as loaded (with each mode's key set): two kill count varbits
-- sharing one base var, and two unique items sharing another, like Rasial's separate
-- armor and weapon rolls.
local BOSS = {
    killCounts = { { var = "KC_NORMAL", mode = "n" }, { var = "KC_HARD", mode = "h" } },
    modes = { n = { key = "n" }, h = { key = "h" } },
    items = {
        [101] = { log = "LOG_WEAPON" },
        [102] = { log = "LOG_ARMOR" },
    },
}

local KC_VAR, LOG_VAR = 1, 2

-- Logic ticks (50 a second): the wait after entering the game before vars are trusted
-- (src/core/var_watch.lua), how long after a claim its drops count, and the quiet
-- before a batch is reported (game_vars).
local SETTLE_TICKS, CLAIM_TICKS, QUIET_TICKS = 5 * 50, 10 * 50, 2

-- Modes for any key a test's kill event or claim gives.
local function anyModes()
    return setmetatable({}, {
        __index = function(modes, key)
            modes[key] = { key = key }
            return modes[key]
        end,
    })
end

local realPrint = print

describe("gameVars", function()
    local gameVars, reports, tick
    local printed -- what the code printed this test; any line fails it, unless expected

    -- Starts watching bosses; a test that doesn't need drops or refreshes leaves them out.
    local function start(bosses, kills, drops, refresh)
        local function ignore() end
        gameVars.Start(bosses, kills, drops or ignore, refresh or ignore)
    end

    -- Runs that many logic ticks, one Logic event each, as the client does.
    local function advance(ticks)
        for _ = 1, ticks do
            tick = tick + 1
            mock.Fire("Logic", { logicTick = tick })
        end
    end

    -- Fires a VarTransmit for a base var going from old to new.
    local function send(id, old, new)
        mock.Fire("VarTransmit", { var = { id = id }, oldValue = old, newValue = new })
    end

    -- Lets the quiet ticks pass, so what was sent is reported.
    local function report()
        advance(QUIET_TICKS)
    end

    -- Sends a change, then lets it be reported.
    local function change(id, old, new)
        send(id, old, new)
        report()
    end

    before_each(function()
        printed = {}
        _G.print = function(...)
            table.insert(printed, table.concat({ ... }, " "))
        end
        mock.Reset()
        local kcVar = mock.AddVar("KC_BASE", KC_VAR)
        mock.AddVarbit("KC_NORMAL", -1, kcVar, 0xFFFF)
        mock.AddVarbit("KC_HARD", -2, kcVar, 0xFFFF0000)
        local logVar = mock.AddVar("LOG_BASE", LOG_VAR)
        mock.AddVarbit("LOG_WEAPON", -3, logVar, 0xFF)
        mock.AddVarbit("LOG_ARMOR", -4, logVar, 0xFF00)
        mock.AddVarbit("LOG_SHARED", -5, logVar, 0xFF0000)

        -- Fresh copies of gameVars and the modules that keep game state for it, and of
        -- safe, which prints each error only once.
        local stateful =
            { "game_vars", "var_watch", "kill_events", "claims", "containers", "piles" }
        for _, name in ipairs(stateful) do
            package.loaded["src/core/" .. name] = nil
        end
        package.loaded["src/utils/safe"] = nil
        gameVars = require("src/core/game_vars")
        reports, tick = {}, 1000
        mock.inGame = true
        start({ BOSS }, function(_, mode, count)
            table.insert(reports, "kill " .. mode.key .. " +" .. count)
        end, function(_, itemID, count)
            table.insert(reports, "drop " .. itemID .. " +" .. count)
        end)
    end)

    after_each(function()
        _G.print = realPrint
        assert.are.same({}, printed)
    end)

    it("reports a kill for the slice that went up", function()
        change(KC_VAR, 25 * 65536 + 575, 25 * 65536 + 576)
        assert.are.same({ "kill n +1" }, reports)
        change(KC_VAR, 25 * 65536 + 576, 26 * 65536 + 576)
        assert.are.same({ "kill n +1", "kill h +1" }, reports)
    end)

    it("reports each unique item that went up in one change", function()
        change(KC_VAR, 1, 2)
        reports = {}
        change(LOG_VAR, 0x020101, 0x030202) -- weapon, armor and an unlisted item all +1
        table.sort(reports)
        assert.are.same({ "drop 101 +1", "drop 102 +1" }, reports)
    end)

    it("reports kills before the drops sent with them", function()
        send(LOG_VAR, 0x01, 0x02) -- the drop arrives first, as seen in game
        send(KC_VAR, 575, 576)
        assert.are.same({}, reports) -- nothing until it's quiet
        report()
        assert.are.same({ "kill n +1", "drop 101 +1" }, reports)
    end)

    it("waits for quiet ticks, so an update split across logic ticks is reported whole", function()
        send(LOG_VAR, 0x01, 0x02) -- the drop, then a logic tick
        advance(1)
        send(KC_VAR, 575, 576) -- then the kill
        advance(1)
        assert.are.same({}, reports) -- not quiet for long enough yet
        advance(1)
        assert.are.same({ "kill n +1", "drop 101 +1" }, reports)
    end)

    it("isn't held back by vars it doesn't watch", function()
        send(KC_VAR, 1, 2)
        for _ = 1, QUIET_TICKS do
            send(99, 1, 2) -- one changing every tick
            advance(1)
        end
        assert.are.same({ "kill n +1" }, reports)
    end)

    it("keeps reporting when one report fails", function()
        gameVars.Stop()
        start({ BOSS }, function()
            error("broken kill report")
        end, function(_, itemID)
            table.insert(reports, "drop " .. itemID)
        end)
        send(KC_VAR, 1, 2)
        send(LOG_VAR, 0x01, 0x02)
        report()
        assert.are.same({ "drop 101" }, reports)
        assert.is_true(printed[1]:find("broken kill report", 1, true) ~= nil)
        printed = {} -- the one error expected
    end)

    it("prints an event handler's error instead of passing it to the game", function()
        mock.Fire("InventoryAdded", {}) -- no inventory: reading it fails
        advance(1)
        change(KC_VAR, 1, 2)
        assert.are.same({ "kill n +1" }, reports) -- still reporting
        assert.is_true(printed[1]:find("handling InventoryAdded", 1, true) ~= nil)
        printed = {} -- the one error expected
    end)

    it(
        "reports a kill event's kill for the mode its values say, not its kill count's own mode",
        function()
            gameVars.Stop()
            local evented = {
                killCounts = { { var = "KC_NORMAL" } },
                modes = anyModes(),
                items = {},
                killEvents = {
                    {
                        var = "LOG_SHARED",
                        reads = { who = "WHO" },
                        mode = function(values)
                            return values.who > 0 and "Chest " .. values.who or nil
                        end,
                    },
                },
            }
            start({ evented }, function(_, mode, count)
                table.insert(reports, mode.key .. " +" .. count)
            end, function() end)
            mock.SetValue("WHO", 3)
            change(KC_VAR, 1, 2) -- the kill count alone: not watched
            change(LOG_VAR, 0, 0x010000) -- the event var goes up
            assert.are.same({ "Chest 3 +1" }, reports)
            mock.SetValue("WHO", 0)
            change(LOG_VAR, 0x010000, 0x020000) -- no mode for it: left uncounted
            assert.are.same({ "Chest 3 +1" }, reports)
        end
    )

    it("gives a kill event the last value above 0 of a varbit reset at the kill", function()
        gameVars.Stop()
        local evented = {
            killCounts = { { var = "KC_NORMAL" } },
            modes = anyModes(),
            items = {},
            killEvents = {
                {
                    var = "KC_NORMAL",
                    lasts = { score = "LOG_SHARED" },
                    mode = function(values)
                        return values.score and "Score " .. values.score or nil
                    end,
                },
            },
        }
        start({ evented }, function(_, mode)
            table.insert(reports, mode.key)
        end, function() end)
        advance(1)
        mock.SetValue("LOG_SHARED", 7)
        send(LOG_VAR, 0, 0x070000) -- the score rises through the fight
        mock.SetValue("LOG_SHARED", 0)
        send(LOG_VAR, 0x070000, 0) -- and resets with the kill
        change(KC_VAR, 1, 2)
        assert.are.same({ "Score 7" }, reports)
        change(KC_VAR, 2, 3) -- no score seen since: uncounted
        assert.are.same({ "Score 7" }, reports)
    end)

    it("tells a kill event whether a varbit rose with it", function()
        gameVars.Stop()
        local evented = {
            killCounts = { { var = "KC_NORMAL" } },
            modes = anyModes(),
            items = {},
            killEvents = {
                {
                    var = "KC_NORMAL",
                    rises = { stone = "LOG_SHARED" },
                    mode = function(values)
                        return values.stone and "Stone" or "None"
                    end,
                },
            },
        }
        start({ evented }, function(_, mode)
            table.insert(reports, mode.key)
        end, function() end)
        advance(1)
        send(KC_VAR, 1, 2)
        change(LOG_VAR, 0, 0x010000) -- with the kill, after it
        change(LOG_VAR, 0x010000, 0x020000) -- alone, as from another mode's kill
        change(KC_VAR, 2, 3)
        assert.are.same({ "Stone", "None" }, reports)
    end)

    it("gives a kill event the piles the player owns that gained a watched item with it", function()
        gameVars.Stop()
        local evented = {
            killCounts = { { var = "KC_NORMAL" } },
            modes = anyModes(),
            items = {},
            killEvents = {
                {
                    var = "KC_NORMAL",
                    pileItems = { 501, 502 },
                    mode = function(values)
                        return "Piles " .. values.piles
                    end,
                },
            },
        }
        start({ evented }, function(_, mode)
            table.insert(reports, mode.key)
        end, function() end)
        advance(1)
        local function stack(name, tile, itemID, owned, counts)
            counts.objStackEntity, counts.objType, counts.isOwner =
                { coordGrid = tile }, { id = itemID }, owned
            mock.Fire(name, counts)
        end
        stack("ObjStackEntityAdded", "a", 501, true, { count = 40 })
        stack("ObjStackEntityChanged", "b", 502, true, { oldCount = 0, newCount = 50 })
        -- The same pile
        stack("ObjStackEntityChanged", "b", 501, true, { oldCount = 0, newCount = 5 })
        -- Joins older loot
        stack("ObjStackEntityChanged", "c", 501, true, { oldCount = 10, newCount = 60 })
        stack("ObjStackEntityAdded", "d", 501, false, { count = 40 }) -- a teammate's
        stack("ObjStackEntityAdded", "e", 999, true, { count = 1 }) -- not a watched item
        -- Picked up
        stack("ObjStackEntityChanged", "f", 501, true, { oldCount = 10, newCount = 0 })
        change(KC_VAR, 1, 2)
        assert.are.same({ "Piles 3" }, reports)
        change(KC_VAR, 2, 3) -- none with this kill: away at the kill
        assert.are.same({ "Piles 3", "Piles 0" }, reports)
        -- A logic tick before the kill count, then after it: still the kill's.
        stack("ObjStackEntityAdded", "a", 501, true, { count = 40 })
        advance(1)
        change(KC_VAR, 3, 4)
        send(KC_VAR, 4, 5)
        advance(1)
        stack("ObjStackEntityAdded", "a", 501, true, { count = 40 })
        report()
        assert.are.same({ "Piles 3", "Piles 0", "Piles 1", "Piles 1" }, reports)
    end)

    it("passes a kill event's sums with its kill", function()
        gameVars.Stop()
        local evented = {
            killCounts = { { var = "KC_NORMAL" } },
            modes = anyModes(),
            items = {},
            killEvents = {
                {
                    var = "KC_NORMAL",
                    reads = { level = "LOG_SHARED" },
                    sums = { "level" },
                    mode = function()
                        return "n"
                    end,
                },
            },
        }
        local sums = {}
        start({ evented }, function(_, _, _, _, s)
            table.insert(sums, s)
        end, function() end)
        mock.SetValue("LOG_SHARED", 7)
        change(KC_VAR, 1, 2)
        assert.are.same({ { level = 7 } }, sums)
    end)

    it("counts drops of loot claimed later only just after the claim", function()
        gameVars.Stop()
        local claimed = {
            killCounts = { { var = "KC_NORMAL", mode = "n" } },
            modes = { n = { key = "n" } },
            items = { [101] = { log = "LOG_WEAPON" } },
            dropsAtClaim = { var = "LOG_SHARED", most = 200 }, -- the streak: 0 once claimed
        }
        start({ claimed }, function() end, function(_, itemID, count)
            table.insert(reports, "drop " .. itemID .. " +" .. count)
        end)
        advance(1)
        change(KC_VAR, 1, 2) -- a kill
        change(LOG_VAR, 0x010000, 0x010001) -- not claimed: a drop from elsewhere
        assert.are.same({}, reports)
        mock.SetValue("LOG_SHARED", 2)
        send(LOG_VAR, 0x010001, 0x020001) -- the streak goes on
        mock.SetValue("LOG_SHARED", 0)
        send(LOG_VAR, 0x020001, 0x000001) -- claimed
        change(LOG_VAR, 0x000001, 0x000005) -- with four from a long streak
        assert.are.same({ "drop 101 +4" }, reports)
        advance(CLAIM_TICKS)
        change(LOG_VAR, 0x000005, 0x000006) -- long after
        assert.are.same({ "drop 101 +4" }, reports)
    end)

    it("can watch bits of a var the game doesn't name as a varbit", function()
        gameVars.Stop()
        local evented = {
            killCounts = {},
            modes = anyModes(),
            items = {},
            killEvents = {
                {
                    var = "LOG_BASE",
                    mask = 0x1000000,
                    mode = function()
                        return "Chest"
                    end,
                },
            },
        }
        start({ evented }, function(_, mode)
            table.insert(reports, mode.key)
        end, function() end)
        change(LOG_VAR, 0x020000, 0x1020000)
        assert.are.same({ "Chest" }, reports)
    end)

    describe("with loot waiting in a chest until claimed", function()
        local LOOT_VAR = 3
        local loot -- the loot var, holding piles in 0x70000 and a difficulty in 0xF0000000
        local claimed = {
            killCounts = { { var = "KC_NORMAL" } },
            modes = anyModes(),
            items = { [101] = { log = "LOG_WEAPON" } },
            claims = {
                {
                    var = "LOOT_BASE",
                    mask = 0x70000,
                    kills = { "KC_NORMAL" },
                    mode = function(_, old)
                        return old & 0xF0000000 == 0 and "n" or "e"
                    end,
                    piles = true, -- the bits count loot piles
                },
            },
        }

        -- Starts watching with value waiting in the loot var.
        local function startWith(value)
            gameVars.Stop()
            loot = mock.AddVar("LOOT_BASE", LOOT_VAR)
            loot.value = value
            start({ claimed }, function(_, mode, count, _, sums)
                local text = "kill " .. mode.key .. " +" .. count
                table.insert(reports, sums and text .. " (" .. sums.piles .. " piles)" or text)
            end, function(_, itemID, count)
                table.insert(reports, "drop " .. itemID .. " +" .. count)
            end)
            advance(1) -- ready: the waiting loot is read
        end

        -- A kill raising the loot var from old to new (or not, if they're equal).
        local function kill(kills, old, new)
            send(KC_VAR, kills - 1, kills)
            if old ~= new then
                send(LOOT_VAR, old, new)
            end
            report()
        end

        it("counts every pile seen arriving at its claim, with its drops", function()
            startWith(0)
            kill(1, 0, 0x10000) -- one pile: not counted yet
            kill(2, 0x10000, 0x30000) -- two more
            assert.are.same({}, reports)
            send(LOOT_VAR, 0x30000, 0) -- claimed: three piles
            send(LOG_VAR, 0, 1) -- and a drop
            report()
            assert.are.same({ "kill n +2 (3 piles)", "drop 101 +1" }, reports)
            kill(3, 0, 0x50010000)
            change(LOOT_VAR, 0x50010000, 0)
            assert.are.same(
                { "kill n +2 (3 piles)", "drop 101 +1", "kill e +1 (1 piles)" },
                reports
            )
        end)

        it("doesn't count a skipped claim's drop, even after a counted claim", function()
            startWith(0)
            kill(1, 0, 0x10000)
            send(LOOT_VAR, 0x10000, 0) -- counted
            change(LOG_VAR, 0, 1) -- with its drop
            kill(2, 0, 0x10000)
            kill(3, 0x10000, 0x10000) -- stacked: the count didn't rise
            send(LOOT_VAR, 0x10000, 0) -- skipped
            change(LOG_VAR, 1, 2) -- its drop
            assert.are.same({ "kill n +1 (1 piles)", "drop 101 +1" }, reports)
        end)

        it("doesn't give a skipped claim's shared unique to another boss", function()
            local OTHER_VAR = 4
            local mine = {
                killCounts = claimed.killCounts,
                modes = claimed.modes,
                claims = claimed.claims,
                items = { [101] = { log = "LOG_WEAPON" } },
            }
            local other = {
                killCounts = { { var = "KC_HARD" } },
                modes = anyModes(),
                items = { [101] = { log = "LOG_WEAPON" } },
                claims = {
                    {
                        var = "OTHER_BASE",
                        mask = 0x1,
                        kills = { "KC_HARD" },
                        mode = function()
                            return "n"
                        end,
                    },
                },
            }
            -- They share 101, as loading would note.
            mine.items[101].pooledBy = { mine, other }
            other.items[101].pooledBy = mine.items[101].pooledBy
            gameVars.Stop()
            loot = mock.AddVar("LOOT_BASE", LOOT_VAR)
            loot.value = 0
            mock.AddVar("OTHER_BASE", OTHER_VAR).value = 0
            start({ mine, other }, function(boss, mode)
                table.insert(
                    reports,
                    (boss == other and "other" or "claimed") .. " kill " .. mode.key
                )
            end, function(boss, itemID)
                table.insert(
                    reports,
                    (boss == other and "other" or "claimed") .. " drop " .. itemID
                )
            end)
            advance(1)
            send(KC_VAR, 0, 65536) -- other's kill, raising its loot bit
            change(OTHER_VAR, 0, 1)
            change(OTHER_VAR, 1, 0) -- other's claim counts
            change(LOOT_VAR, 0x10000, 0) -- claimed's loot arrived unseen, so it's skipped
            change(LOG_VAR, 0, 1) -- the shared unique, from that claim
            assert.are.same({ "other kill n" }, reports)
        end)

        it("leaves a claim uncounted, drops and all, if a kill didn't raise it", function()
            startWith(0)
            kill(1, 0, 0x50000)
            kill(2, 0x50000, 0x50000) -- the count didn't change: its piles are unknown
            send(LOOT_VAR, 0x50000, 0)
            send(LOG_VAR, 0, 1)
            report()
            assert.are.same({}, reports)
            kill(3, 0, 0x30000) -- the next chest counts again
            change(LOOT_VAR, 0x30000, 0)
            assert.are.same({ "kill n +1 (3 piles)" }, reports)
        end)

        it("counts claims sharing one var by their own bits, like Sanctum's bosses", function()
            local function only(name)
                return function()
                    return name
                end
            end
            local two = {
                killCounts = { { var = "KC_NORMAL" }, { var = "KC_HARD" } },
                modes = anyModes(),
                items = {},
                claims = {
                    {
                        var = "LOOT_BASE",
                        mask = 0x1,
                        kills = { "KC_NORMAL" },
                        mode = only("a"),
                    },
                    {
                        var = "LOOT_BASE",
                        mask = 0x4,
                        kills = { "KC_HARD" },
                        mode = only("b"),
                    },
                },
            }
            gameVars.Stop()
            loot = mock.AddVar("LOOT_BASE", LOOT_VAR)
            loot.value = 0
            start({ two }, function(_, mode, count)
                table.insert(reports, "kill " .. mode.key .. " +" .. count)
            end, function() end, function() end)
            advance(1)
            send(KC_VAR, 0, 1) -- A's kill sets its bit
            send(LOOT_VAR, 0, 0x1)
            report()
            send(KC_VAR, 1, 0x10001) -- B's kill sets its own
            send(LOOT_VAR, 0x1, 0x5)
            report()
            assert.are.same({}, reports)
            change(LOOT_VAR, 0x5, 0x4)
            change(LOOT_VAR, 0x4, 0)
            assert.are.same({ "kill a +1", "kill b +1" }, reports)
        end)

        it("leaves a claim uncounted if part of the loot was taken first", function()
            startWith(0)
            kill(1, 0, 0x10000)
            kill(2, 0x10000, 0x30000)
            change(LOOT_VAR, 0x30000, 0x10000) -- part taken: no claim yet
            change(LOOT_VAR, 0x10000, 0) -- the rest: not all of what arrived
            assert.are.same({}, reports)
            kill(3, 0, 0x10000) -- the next chest counts again
            change(LOOT_VAR, 0x10000, 0)
            assert.are.same({ "kill n +1 (1 piles)" }, reports)
        end)

        it("leaves loot waiting from before it was watched uncounted", function()
            startWith(0x20000)
            kill(1, 0x20000, 0x30000)
            change(LOOT_VAR, 0x30000, 0)
            assert.are.same({}, reports)
        end)
    end)

    it("reports each kill with today, from the game clock", function()
        gameVars.Stop()
        local days = {}
        start({ BOSS }, function(_, _, _, day)
            table.insert(days, day)
        end, function() end)
        mock.SetValue("CLOCK_TIME_DATE_MINUTES", 29888748) -- 30 Oct 2026, 01:48 UTC
        change(KC_VAR, 1, 2)
        mock.SetValue("CLOCK_TIME_DATE_MINUTES", nil)
        change(KC_VAR, 2, 3)
        assert.are.same({ 20756, 0 }, days) -- 0 when the clock can't be read
    end)

    it("reads the vars a boss reads for its rolls", function()
        var.VarPlayer.LOG_SHARED.value = 9
        local reader =
            { killCounts = {}, modes = {}, items = {}, reads = { shared = "LOG_SHARED" } }
        assert.are.same({ shared = 9 }, gameVars.AllTime(reader).values)
    end)

    it("reads all-time totals once vars can be trusted", function()
        for name, value in pairs({ KC_NORMAL = 40, KC_HARD = 2, LOG_WEAPON = 3, LOG_ARMOR = 1 }) do
            var.VarPlayer[name].value = value
        end
        assert.are.same({
            kills = { KC_NORMAL = 40, KC_HARD = 2 },
            items = { ["101"] = 3, ["102"] = 1 },
            values = {},
        }, gameVars.AllTime(BOSS))
        mock.Fire("GameStateChanged", { newState = GameState.LOGINSCREEN })
        assert.is_nil(gameVars.AllTime(BOSS))
        mock.Fire("GameStateChanged", { newState = GameState.GAME })
        assert.is_nil(gameVars.AllTime(BOSS)) -- vars may still be arriving
        advance(SETTLE_TICKS)
        assert.are.equal(40, gameVars.AllTime(BOSS).kills.KC_NORMAL)
    end)

    it("says when vars can be trusted after entering the game", function()
        local ready = 0
        gameVars.Stop()
        start({ BOSS }, function() end, function() end, function()
            ready = ready + 1
        end)
        advance(1)
        assert.are.equal(1, ready)
        mock.Fire("GameStateChanged", { newState = GameState.GAME })
        advance(SETTLE_TICKS - 1)
        assert.are.equal(1, ready) -- one tick short of the wait
        advance(1)
        assert.are.equal(2, ready)
    end)

    it("ignores drops of a boss not killed since entering the game", function()
        change(LOG_VAR, 0x00, 0x02) -- collection log counts sent again, from 0
        assert.are.same({}, reports)
        change(KC_VAR, 1, 2)
        change(LOG_VAR, 0x02, 0x03)
        assert.are.same({ "kill n +1", "drop 101 +1" }, reports)

        -- Back in the game: a new session, with no kills yet.
        mock.Fire("GameStateChanged", { newState = GameState.GAME })
        advance(SETTLE_TICKS)
        change(LOG_VAR, 0x03, 0x04)
        assert.are.same({ "kill n +1", "drop 101 +1" }, reports)
    end)

    it("ignores counts sent again from 0, even for a boss just killed", function()
        change(KC_VAR, 1, 2)
        change(LOG_VAR, 0x02, 0x00) -- the collection log count drops to 0...
        change(LOG_VAR, 0x00, 0x02) -- ...and comes back: no drop
        change(LOG_VAR, 0x02, 0x03)
        assert.are.same({ "kill n +1", "drop 101 +1" }, reports)
    end)

    it("knows each count's value once the game is ready", function()
        var.VarPlayer.LOG_WEAPON.value = 2
        mock.Fire("GameStateChanged", { newState = GameState.GAME })
        advance(SETTLE_TICKS) -- ready: the weapon's count is 2
        change(KC_VAR, 1, 2)
        change(LOG_VAR, 0x00, 0x02) -- sent again from 0: no drop
        change(LOG_VAR, 0x02, 0x03)
        assert.are.same({ "kill n +1", "drop 101 +1" }, reports)
    end)

    it("counts the next character's kills from their own kill count", function()
        change(KC_VAR, 49, 50) -- one character
        mock.Fire("GameStateChanged", { newState = GameState.LOGINSCREEN })
        var.VarPlayer.KC_NORMAL.value = 3 -- another, with fewer kills
        mock.Fire("GameStateChanged", { newState = GameState.GAME })
        advance(SETTLE_TICKS)
        change(KC_VAR, 3, 4)
        assert.are.same({ "kill n +1", "kill n +1" }, reports)
    end)

    it("counts a rise of up to 3 as that many kills, and ignores more", function()
        change(KC_VAR, 1, 3)
        change(KC_VAR, 3, 7) -- 4 at once: not kills
        change(KC_VAR, 7, 8)
        assert.are.same({ "kill n +2", "kill n +1" }, reports)
    end)

    it("ignores big jumps and decreases", function()
        change(KC_VAR, 0, 554) -- like a login sync
        change(KC_VAR, 554, 553)
        assert.are.same({}, reports)
    end)

    it("ignores vars it doesn't watch", function()
        change(99, 1, 2)
        assert.are.same({}, reports)
    end)

    it("waits a few seconds after entering the game", function()
        mock.Fire("GameStateChanged", { newState = GameState.LOGINSCREEN })
        change(KC_VAR, 1, 2)
        mock.Fire("GameStateChanged", { newState = GameState.GAME })
        change(KC_VAR, 2, 3)
        advance(SETTLE_TICKS)
        change(KC_VAR, 3, 4)
        assert.are.same({ "kill n +1" }, reports)
    end)

    it("waits for the game if it starts on the login screen", function()
        gameVars.Stop()
        mock.inGame = false
        start({ BOSS }, function()
            table.insert(reports, "kill")
        end, function() end)
        change(KC_VAR, 1, 2)
        assert.are.same({}, reports)
    end)

    describe("with a container kept to open later", function()
        local CHEST = 500
        local WINDOW = "DROP_CASKET_REWARDINV"
        local chested = {
            killCounts = { { var = "KC_NORMAL" } },
            modes = anyModes(),
            containers = { [CHEST] = { mode = "n", window = WINDOW } },
            items = {
                [101] = {
                    log = "LOG_WEAPON",
                    stack = { most = 9, word = "spike" },
                },
            },
        }

        -- Sets the backpack's chest count, as an inventory update.
        local function backpack(count)
            mock.backpack[CHEST] = count
            mock.Fire("InventoryUpdated", { inv = config.Inv.INV })
        end

        local function rewardWindow(name)
            mock.Fire("InventoryAdded", { inv = { id = 952, configName = name or WINDOW } })
        end

        before_each(function()
            gameVars.Stop()
            mock.backpack[CHEST] = 3
            start({ chested }, function(_, mode, count)
                table.insert(reports, "kill " .. mode.key .. " +" .. count)
            end, function(_, itemID, count)
                table.insert(reports, "drop " .. itemID .. " +" .. count)
            end, function()
                table.insert(reports, "refresh")
            end)
            advance(1) -- ready: the backpack's chests are read
            reports = {}
        end)

        it("counts a chest opened, not the kill count, and its drop as one", function()
            change(KC_VAR, 1, 2) -- the kill: not counted, only redrawn
            rewardWindow()
            backpack(2)
            send(LOG_VAR, 10, 16) -- six spikes
            report()
            assert.are.same({ "refresh", "kill n +1", "drop 101 +1" }, reports)
        end)

        it("doesn't count a chest banked or claimed", function()
            backpack(2) -- banked
            report()
            backpack(4) -- withdrawn and claimed
            report()
            assert.are.same({}, reports)
        end)

        it("only counts its own reward window", function()
            rewardWindow("OTHER_REWARDINV")
            backpack(2)
            report()
            assert.are.same({}, reports)
        end)

        it("counts chests opened one per reward window", function()
            rewardWindow()
            backpack(1) -- two left at once, one window
            report()
            assert.are.same({ "kill n +1" }, reports)
        end)
    end)

    it("unsubscribes everything when stopped", function()
        assert.is_true(mock.SubscriptionCount() > 0)
        gameVars.Stop()
        assert.are.equal(0, mock.SubscriptionCount())
    end)
end)

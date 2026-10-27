-- Run from the project root with: busted

local mock = require("spec/mock_api")

-- A test boss: two KC varbits sharing one base var, and two unique items plus a
-- shared item sharing another, like Rasial's separate armor and weapon rolls.
local BOSS = {
    modes = {
        { name = "Normal", kc = "KC_NORMAL" },
        { name = "Hard mode", kc = "KC_HARD" },
    },
    items = {
        [101] = { log = "LOG_WEAPON", kind = "unique" },
        [102] = { log = "LOG_ARMOR", kind = "unique" },
        [103] = { log = "LOG_SHARED", kind = "shared" },
        [104] = { kind = "pet" },
    },
}

local KC_VAR, LOG_VAR = 1, 2

describe("gamevars", function()
    local gamevars, reports, tick

    local function advance(ticks)
        tick = tick + ticks
        mock.Fire("Logic", { logicTick = tick })
    end

    -- Fires a VarTransmit for a base var going from old to new.
    local function send(id, old, new)
        mock.Fire("VarTransmit", { var = { id = id }, oldValue = old, newValue = new })
    end

    -- Sends a change, then lets a tick pass so it is reported.
    local function change(id, old, new)
        send(id, old, new)
        advance(1)
    end

    before_each(function()
        mock.Reset()
        local kcVar = mock.AddVar("KC_BASE", KC_VAR)
        mock.AddVarbit("KC_NORMAL", -1, kcVar, 0xFFFF)
        mock.AddVarbit("KC_HARD", -2, kcVar, 0xFFFF0000)
        local logVar = mock.AddVar("LOG_BASE", LOG_VAR)
        mock.AddVarbit("LOG_WEAPON", -3, logVar, 0xFF)
        mock.AddVarbit("LOG_ARMOR", -4, logVar, 0xFF00)
        mock.AddVarbit("LOG_SHARED", -5, logVar, 0xFF0000)

        package.loaded["src/gamevars"] = nil
        gamevars = require("src/gamevars")
        reports, tick = {}, 1000
        mock.inGame = true
        gamevars.Start({ BOSS }, function(_, mode, count)
            table.insert(reports, "kill " .. mode.name .. " +" .. count)
        end, function(_, itemID, count)
            table.insert(reports, "drop " .. itemID .. " +" .. count)
        end)
    end)

    it("reports a kill for the slice that went up", function()
        change(KC_VAR, 25 * 65536 + 575, 25 * 65536 + 576)
        assert.are.same({ "kill Normal +1" }, reports)
        change(KC_VAR, 25 * 65536 + 576, 26 * 65536 + 576)
        assert.are.same({ "kill Normal +1", "kill Hard mode +1" }, reports)
    end)

    it("reports each unique item that went up in one change", function()
        change(LOG_VAR, 0x020101, 0x030202) -- weapon, armor and shared all +1
        table.sort(reports)
        assert.are.same({ "drop 101 +1", "drop 102 +1" }, reports)
    end)

    it("reports a tick's kills before its drops", function()
        send(LOG_VAR, 0x01, 0x02) -- the drop arrives first, as seen in game
        send(KC_VAR, 575, 576)
        assert.are.same({}, reports) -- nothing until the next tick
        advance(1)
        assert.are.same({ "kill Normal +1", "drop 101 +1" }, reports)
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
        advance(5 * 50)
        change(KC_VAR, 3, 4)
        assert.are.same({ "kill Normal +1" }, reports)
    end)

    it("waits for the game if it starts on the login screen", function()
        gamevars.Stop()
        mock.inGame = false
        gamevars.Start({ BOSS }, function() table.insert(reports, "kill") end, function() end)
        change(KC_VAR, 1, 2)
        assert.are.same({}, reports)
    end)

    it("unsubscribes everything when stopped", function()
        gamevars.Stop()
        assert.are.equal(0, mock.SubscriptionCount())
    end)
end)

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
    local gamevars, kills, drops

    -- Fires a VarTransmit for a base var going from old to new.
    local function change(id, old, new)
        mock.Fire("VarTransmit", { var = { id = id }, oldValue = old, newValue = new })
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
        kills, drops = {}, {}
        mock.inGame = true
        gamevars.Start({ BOSS }, function(_, mode, count)
            table.insert(kills, mode.name .. " +" .. count)
        end, function(_, itemID, count)
            table.insert(drops, itemID .. " +" .. count)
        end)
    end)

    it("reports a kill for the slice that went up", function()
        change(KC_VAR, 25 * 65536 + 575, 25 * 65536 + 576)
        assert.are.same({ "Normal +1" }, kills)
        change(KC_VAR, 25 * 65536 + 576, 26 * 65536 + 576)
        assert.are.same({ "Normal +1", "Hard mode +1" }, kills)
    end)

    it("reports each unique item that went up in one change", function()
        change(LOG_VAR, 0x020101, 0x030202) -- weapon, armor and shared all +1
        table.sort(drops)
        assert.are.same({ "101 +1", "102 +1" }, drops)
    end)

    it("ignores big jumps and decreases", function()
        change(KC_VAR, 0, 554) -- like a login sync
        change(KC_VAR, 554, 553)
        assert.are.same({}, kills)
    end)

    it("ignores vars it doesn't watch", function()
        change(99, 1, 2)
        assert.are.same({}, kills)
        assert.are.same({}, drops)
    end)

    it("waits a few seconds after entering the game", function()
        mock.Fire("Logic", { logicTick = 1000 })
        mock.Fire("GameStateChanged", { newState = GameState.LOGINSCREEN })
        change(KC_VAR, 1, 2)
        mock.Fire("GameStateChanged", { newState = GameState.GAME })
        change(KC_VAR, 2, 3)
        mock.Fire("Logic", { logicTick = 1000 + 5 * 50 })
        change(KC_VAR, 3, 4)
        assert.are.same({ "Normal +1" }, kills)
    end)

    it("waits for the game if it starts on the login screen", function()
        gamevars.Stop()
        mock.inGame = false
        gamevars.Start({ BOSS }, function() table.insert(kills, "kill") end, function() end)
        change(KC_VAR, 1, 2)
        assert.are.same({}, kills)
    end)

    it("unsubscribes everything when stopped", function()
        gamevars.Stop()
        assert.are.equal(0, mock.SubscriptionCount())
    end)
end)

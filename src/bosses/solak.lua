-- Solak, Guardian of the Grove.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28: each kill rolls
-- the unique table at 1/100, for Erethdor's grimoire (1/200) or a Blightbound
-- crossbow, main-hand or off-hand (1/400 each). Merethiel's stave and the purple
-- mushroom are 1/500 each, on their own rolls. Every player in the team gets
-- their own rolls, at the same rates for any team size. Jagex's Late-Game
-- Rebalance raises each crossbow to 1/200.

local rates = require("src/rates")
local updates = require("src/updates")
local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_SOLAK",
    log = "ITEMLOG_ITEM_SOLAK_", -- each item's log count, by its name
}

local GRIMOIRE, CROSSBOW, OFFHAND = 42785, 42770, 42774
local STAVE, MUSHROOM = 42767, 42782

-- Chances per kill, before and after the Late-Game Rebalance.
local RATES = rates.History({
    { grimoire = 1 / 200, crossbow = 1 / 400, stave = 1 / 500, mushroom = 1 / 500 },
    { since = updates.LATE_GAME_REBALANCE, crossbow = 1 / 200 },
})

local function rolls(_, r)
    return {
        common.OneOf(common.Each({ CROSSBOW, OFFHAND }, r.crossbow, { [GRIMOIRE] = r.grimoire })),
        { chance = r.stave, items = { [STAVE] = 1 } },
        { chance = r.mushroom, items = { [MUSHROOM] = 1 } },
    }
end

return {
    key = "solak", -- saved data key: never change it
    name = "Solak",
    logPage = "COLLECTION_BOSS_SOLAK", -- the boss log page's database row
    assumptions = {},
    rates = RATES,

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = VARS.kc, rolls = rolls },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [GRIMOIRE] = { log = VARS.log .. "PRAYER_BOOK", kind = "unique" },
        [CROSSBOW] = { log = VARS.log .. "CROSSBOW", kind = "unique" },
        [OFFHAND] = { log = VARS.log .. "OFFHAND_CROSSBOW", kind = "unique" },
        [STAVE] = { log = VARS.log .. "MERETHIELS_STAFF", kind = "unique" },
        -- Unlocks the Blightbound lasher pet, but it's an item with its own rate.
        [MUSHROOM] = { log = VARS.log .. "BLIGHTBOUND_PET", kind = "unique" },
        [43357] = { log = VARS.log .. "GRIMOIRE_PAGES2", kind = "excluded" }, -- Torn grimoire page: a common drop
        [42844] = { kind = "pet" }, -- Solly
    },
}

-- Solak, Guardian of the Grove.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28: each kill rolls
-- the unique table at 1/100, for Erethdor's grimoire (1/200) or a Blightbound
-- crossbow, main-hand or off-hand (1/400 each). Merethiel's stave and the purple
-- mushroom are 1/500 each, on their own rolls. Every player in the team gets
-- their own rolls, at the same rates for any team size.

local GRIMOIRE, CROSSBOW, OFFHAND = 42785, 42770, 42774
local STAVE, MUSHROOM = 42767, 42782

local LOG = "ITEMLOG_ITEM_SOLAK_"

return {
    key = "solak", -- saved data key: never change it
    name = "Solak",
    logPage = "COLLECTION_BOSS_SOLAK", -- the boss log page's database row
    assumptions = {},

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = "BSLAY_KILLS_SOLAK", rolls = {
            { chance = 1 / 100, items = { [GRIMOIRE] = 2, [CROSSBOW] = 1, [OFFHAND] = 1 } },
            { chance = 1 / 500, items = { [STAVE] = 1 } },
            { chance = 1 / 500, items = { [MUSHROOM] = 1 } },
        } },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [GRIMOIRE] = { log = LOG .. "PRAYER_BOOK", kind = "unique" },
        [CROSSBOW] = { log = LOG .. "CROSSBOW", kind = "unique" },
        [OFFHAND] = { log = LOG .. "OFFHAND_CROSSBOW", kind = "unique" },
        [STAVE] = { log = LOG .. "MERETHIELS_STAFF", kind = "unique" },
        -- Unlocks the Blightbound lasher pet, but it's an item with its own rate.
        [MUSHROOM] = { log = LOG .. "BLIGHTBOUND_PET", kind = "unique" },
        [43357] = { log = LOG .. "GRIMOIRE_PAGES2", kind = "excluded" }, -- Torn grimoire page: a common drop
        [42844] = { kind = "pet" }, -- Solly
    },
}

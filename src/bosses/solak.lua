-- Solak. Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28. Every player gets
-- their own rolls, at the same rates for any team size.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_SOLAK",
    log = "ITEMLOG_ITEM_SOLAK_", -- each item's log count, by its name
}

local GRIMOIRE, CROSSBOW, OFFHAND = 42785, 42770, 42774
local STAVE, MUSHROOM = 42767, 42782

local function rolls(r)
    return {
        common.OneOf(common.Each({ CROSSBOW, OFFHAND }, r.crossbow, { [GRIMOIRE] = r.grimoire })),
        { chance = r.stave, items = { [STAVE] = 1 } },
        { chance = r.mushroom, items = { [MUSHROOM] = 1 } },
    }
end

return {
    key = "solak", -- saved data key: never change it
    name = "Solak",
    assumptions = {},

    -- Mode names are saved: never change them.
    modes = {
        { name = "Normal", kc = VARS.kc, rolls = rolls },
    },

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

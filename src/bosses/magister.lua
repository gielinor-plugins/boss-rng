-- The Magister. A solo fight. Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked
-- 2026-10-31. A Phylactery is one item a drop, so its log count is its drops.

local VARS = {
    kc = "BSLAY_KILLS_MENAPHOS_SLAYER_BOSS",
    log = "ITEMLOG_ITEM_MAGISTER_", -- each unique's log count, by its name
}

local PHYLACTERY, GLOVES = 40650, 40320

local function rolls(r)
    return {
        { chance = r.phylactery, items = { [PHYLACTERY] = 1 } },
        { chance = r.gloves, items = { [GLOVES] = 1 } },
    }
end

return {
    key = "magister", -- saved data key: never change it
    name = "The Magister",
    assumptions = {},

    -- Mode keys are saved: never change them.
    modes = {
        { key = "n", kc = VARS.kc, rolls = rolls },
    },

    items = {
        [PHYLACTERY] = { log = VARS.log .. "PHYLACTERY", kind = "unique" },
        [GLOVES] = { log = VARS.log .. "HANDS", kind = "unique" },
        [40670] = { kind = "pet" }, -- The Minister
        [40663] = { kind = "lore" }, -- The Magister's Journal #1 to #5
        [40664] = { kind = "lore" },
        [40665] = { kind = "lore" },
        [40666] = { kind = "lore" },
        [40667] = { kind = "lore" },
    },
}

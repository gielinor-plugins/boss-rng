-- The Magister, a Slayer boss in the Sophanem Slayer Dungeon. A solo fight.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-31: on top of its
-- main drop, each kill rolls 1/18 for a Phylactery and 1/500 for the Gloves of
-- passage. Jagex's Late-Game Rebalance raises them to 1/10 and 1/128. A
-- Phylactery is one item a drop, so its log count is its drops.

local VARS = {
    kc = "BSLAY_KILLS_MENAPHOS_SLAYER_BOSS",
    log = "ITEMLOG_ITEM_MAGISTER_", -- each unique's log count, by its name
}

local PHYLACTERY, GLOVES = 40650, 40320

-- A kill's rolls at rate values r (see src/rates/base.lua).
local function rolls(r)
    return {
        { chance = r.phylactery, items = { [PHYLACTERY] = 1 } },
        { chance = r.gloves, items = { [GLOVES] = 1 } },
    }
end

return {
    key = "magister", -- saved data key: never change it
    name = "The Magister",
    logPage = "COLLECTION_BOSS_MAGISTER", -- the boss log page's database row
    assumptions = {},

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = VARS.kc, rolls = rolls },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
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

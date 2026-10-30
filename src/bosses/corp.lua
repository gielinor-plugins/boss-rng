-- The Corporeal Beast.
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28: the holy elixir
-- is 3/512, and since 20 July 2026 the sigil table is 1/256, for one of four
-- sigils evenly (1/1,024 each). Boss RNG came out after that change, so every
-- tracked kill has these rates. Each kill gives one drop, to one player.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_CORPBEAST",
    log = "ITEMLOG_ITEM_CORP_", -- each item's log count, by its name
}

local SPECTRAL, ARCANE, ELYSIAN, DIVINE = 13752, 13746, 13750, 13748
local ELIXIR = 13754

return {
    key = "corp", -- saved data key: never change it
    name = "Corporeal Beast",
    logPage = "COLLECTION_BOSS_CORP", -- the boss log page's database row
    assumptions = { common.SOLO_KILLS },

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = VARS.kc, rolls = {
            { chance = 1 / 256, items = common.Even({ SPECTRAL, ARCANE, ELYSIAN, DIVINE }) },
            { chance = 3 / 512, items = { [ELIXIR] = 1 } },
        } },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [SPECTRAL] = { log = VARS.log .. "SIGIL_SPECTRAL", kind = "unique" },
        [ARCANE] = { log = VARS.log .. "SIGIL_ARCANE", kind = "unique" },
        [ELYSIAN] = { log = VARS.log .. "SIGIL_ELYSIAN", kind = "unique" },
        [DIVINE] = { log = VARS.log .. "SIGIL_DIVINE", kind = "unique" },
        -- Other monsters drop it too, but players don't hunt it there.
        [ELIXIR] = { log = VARS.log .. "HOLY_ELIXIR", kind = "unique" },
        [13734] = { kind = "excluded" }, -- Spirit shield: common from other monsters
        [33812] = { kind = "pet" }, -- Corporeal puppy
    },
}

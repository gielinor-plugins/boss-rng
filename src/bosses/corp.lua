-- Corporeal Beast. Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28. Each
-- kill gives one drop, to one player.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_CORPBEAST",
    log = "ITEMLOG_ITEM_CORP_", -- each item's log count, by its name
}

local SPECTRAL, ARCANE, ELYSIAN, DIVINE = 13752, 13746, 13750, 13748
local ELIXIR = 13754
local SIGILS = common.Even({ SPECTRAL, ARCANE, ELYSIAN, DIVINE })

local function rolls(r)
    return {
        { chance = r.sigil, items = SIGILS },
        { chance = r.elixir, items = { [ELIXIR] = 1 } },
    }
end

return {
    key = "corp", -- saved data key: never change it
    name = "Corporeal Beast",
    assumptions = { common.SOLO_KILLS },

    -- Mode keys are saved: never change them.
    modes = {
        { key = "n", kc = VARS.kc, rolls = rolls },
    },

    items = {
        [SPECTRAL] = { log = VARS.log .. "SIGIL_SPECTRAL" },
        [ARCANE] = { log = VARS.log .. "SIGIL_ARCANE" },
        [ELYSIAN] = { log = VARS.log .. "SIGIL_ELYSIAN" },
        [DIVINE] = { log = VARS.log .. "SIGIL_DIVINE" },
        -- Other monsters drop it too, but players don't hunt it there.
        [ELIXIR] = { log = VARS.log .. "HOLY_ELIXIR" },
    },
}

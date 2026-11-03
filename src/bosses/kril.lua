-- K'ril Tsutsaroth, God Wars Dungeon. Rates: see src/bosses/godwars.lua. The wiki doesn't
-- say how his hilt rolls, so it's assumed to work as the other generals' do.

local common = require("src/bosses/common")
local godwars = require("src/bosses/godwars")

local VARS = {
    kc = "BSLAY_KILLS_GWD_KRIL",
    kcHard = "BSLAY_KILLS_GWD_KRIL_HARDMODE",
    log = "ITEMLOG_ITEM_GWD_ZAMORAK_", -- each unique's log count, by its piece
    staff = "ITEMLOG_ITEM_GWD_STEAM_BATTLESTAFF",
}

local HOOD, GARB, GOWN, GLOVES, BOOTS, WARD = 24992, 24995, 24998, 25007, 25004, 25001
local SPEAR, STAFF, HILT = 11716, 11736, 11708

local ARMOR = { HOOD, GARB, GOWN, GLOVES, BOOTS, WARD }
local function rolls(r)
    return godwars.Rolls(
        common.Each(ARMOR, r.armor, { [SPEAR] = r.spear, [STAFF] = r.staff }),
        HILT,
        r
    )
end

return {
    key = "kril", -- saved data key: never change it
    name = "K'ril Tsutsaroth",
    assumptions = { common.SOLO_KILLS },

    modes = common.Modes(VARS, rolls),

    items = {
        [HOOD] = { log = VARS.log .. "HEAD" },
        [GARB] = { log = VARS.log .. "BODY" },
        [GOWN] = { log = VARS.log .. "LEGS" },
        [GLOVES] = { log = VARS.log .. "HANDS" },
        [BOOTS] = { log = VARS.log .. "FEET" },
        [WARD] = { log = VARS.log .. "SHIELD" },
        [SPEAR] = { log = VARS.log .. "SPEAR" },
        [STAFF] = { log = VARS.staff },
        [HILT] = { log = VARS.log .. "HILT" },
    },
}

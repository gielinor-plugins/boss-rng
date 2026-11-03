-- K'ril Tsutsaroth, God Wars Dungeon. Rates: see src/bosses/godwars.lua. The wiki doesn't
-- say how his hilt rolls, so it's assumed to work as the other generals' do.

local common = require("src/bosses/common")
local godwars = require("src/bosses/godwars")

local VARS = {
    kc = "BSLAY_KILLS_GWD_KRIL",
    kcHard = "BSLAY_KILLS_GWD_KRIL_HARDMODE",
    log = "ITEMLOG_ITEM_GWD_ZAMORAK_", -- each unique's log count, by its piece
    staff = "ITEMLOG_ITEM_GWD_STEAM_BATTLESTAFF",
    warpriest = "ITEMLOG_ITEM_WARPRIEST_ZAMORAK_", -- the Warpriest set's log counts
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

    items = godwars.Items(
        {
            [HOOD] = { log = VARS.log .. "HEAD", kind = "unique" },
            [GARB] = { log = VARS.log .. "BODY", kind = "unique" },
            [GOWN] = { log = VARS.log .. "LEGS", kind = "unique" },
            [GLOVES] = { log = VARS.log .. "HANDS", kind = "unique" },
            [BOOTS] = { log = VARS.log .. "FEET", kind = "unique" },
            [WARD] = { log = VARS.log .. "SHIELD", kind = "unique" },
            [SPEAR] = { log = VARS.log .. "SPEAR", kind = "unique" },
            [STAFF] = { log = VARS.staff, kind = "unique" },
            [HILT] = { log = VARS.log .. "HILT", kind = "unique" },
            [25041] = { kind = "lore" }, -- Razulei's Tale
            [33805] = { kind = "pet" }, -- K'ril Tinyroth
        },
        VARS.warpriest,
        { HELM = 28785, CAPE = 28788, BODY = 28779, LEGS = 28782, GLOVES = 28773, BOOTS = 28776 }
    ),
}

-- Araxxi. Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28. The game keeps
-- one kill count for solo and duo, so the fight's duo flag, read at each kill, decides
-- the kill's rates.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_ARAXXI",
    duo = "SB_DUO", -- 1 in a duo fight, private or public; 0 solo
    -- Each item's collection log count (Araxxor's internal name is SB, the spider boss)
    log = "ITEMLOG_ITEM_SB_",
}

local LEG_TOP, LEG_MIDDLE, LEG_BOTTOM = 31718, 31719, 31720
local FANG, EYE, WEB = 31722, 31723, 31724
local LEGS = { name = "Leg pieces" }
local ADD_ONS = { name = "Noxious add-ons" }

-- A team's rolls ("solo" or "duo"): a leg and an add-on.
local function rolls(team)
    return function(r)
        return {
            {
                chance = r[team .. "Legs"],
                items = common.Even({ LEG_TOP, LEG_MIDDLE, LEG_BOTTOM }),
            },
            { chance = r[team .. "AddOns"], items = common.Even({ FANG, EYE, WEB }) },
        }
    end
end

return {
    key = "araxxi",
    name = "Araxxi",
    assumptions = {},

    killCounts = { { var = VARS.kc } }, -- solo or duo, through its kill event
    modes = { s = { rolls = rolls("solo") }, d = { rolls = rolls("duo") } },
    killEvents = {
        {
            var = VARS.kc,
            reads = { duo = VARS.duo },
            mode = function(values)
                return values.duo == 1 and "d" or "s"
            end,
        },
    },

    items = {
        [LEG_TOP] = { log = VARS.log .. "LEG_TOP", group = LEGS },
        [LEG_MIDDLE] = { log = VARS.log .. "LEG_MIDDLE", group = LEGS },
        [LEG_BOTTOM] = { log = VARS.log .. "LEG_BOTTOM", group = LEGS },
        [FANG] = { log = VARS.log .. "FANG", group = ADD_ONS }, -- Araxxi's fang
        [EYE] = { log = VARS.log .. "EYE", group = ADD_ONS }, -- Araxxi's eye
        [WEB] = { log = VARS.log .. "WEB", group = ADD_ONS }, -- Araxxi's web
    },
}

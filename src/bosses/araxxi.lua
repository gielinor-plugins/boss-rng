-- Araxxi. Rates: RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28. The game keeps
-- one kill count for solo and duo, so each kill counts by the fight's duo flag.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_ARAXXI",
    duo = "SB_DUO", -- 1 in a duo fight, private or public; 0 solo
    log = "ITEMLOG_ITEM_SB_", -- each item's log count (Araxxor's internal name is SB, the spider boss)
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

-- Tracked kills' modes. Keys are saved: never change them.
local TRACKED = {
    s = { key = "s", kc = VARS.kc, rolls = rolls("solo") },
    d = { key = "d", kc = VARS.kc, rolls = rolls("duo") },
}

return {
    key = "araxxi", -- saved data key: never change it
    name = "Araxxi",
    assumptions = {},

    -- Counted only through its kill event.
    modes = {
        { key = "n", kc = VARS.kc, byEvent = true },
    },
    killEvents = {
        {
            var = VARS.kc,
            reads = { duo = VARS.duo },
            mode = function(values)
                return values.duo == 1 and "d" or "s"
            end,
        },
    },
    modeFor = function(key)
        return TRACKED[key]
    end,

    items = {
        [LEG_TOP] = { log = VARS.log .. "LEG_TOP", kind = "unique", group = LEGS },
        [LEG_MIDDLE] = { log = VARS.log .. "LEG_MIDDLE", kind = "unique", group = LEGS },
        [LEG_BOTTOM] = { log = VARS.log .. "LEG_BOTTOM", kind = "unique", group = LEGS },
        [FANG] = { log = VARS.log .. "FANG", kind = "unique", group = ADD_ONS }, -- Araxxi's fang
        [EYE] = { log = VARS.log .. "EYE", kind = "unique", group = ADD_ONS }, -- Araxxi's eye
        [WEB] = { log = VARS.log .. "WEB", kind = "unique", group = ADD_ONS }, -- Araxxi's web
        [35870] = { log = VARS.log .. "PHEROMONE", kind = "excluded" }, -- Araxyte pheromone: a common drop
        [31753] = { kind = "pet" }, -- Bill
        [31752] = { kind = "pet" }, -- Lana
        [31750] = { kind = "pet" }, -- Pete
        [31748] = { kind = "pet" }, -- Dave
        [31749] = { kind = "pet" }, -- Steve
        [31751] = { kind = "pet" }, -- Gavin
        [33809] = { kind = "pet" }, -- Barry
        [33810] = { kind = "pet" }, -- Mallory
    },
}

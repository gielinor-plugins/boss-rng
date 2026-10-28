-- Araxxi (Araxxor's kill count).
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28: each kill rolls
-- a spider leg at 1/40 solo and 1/70 duo, which leg depending on the path taken,
-- and a weapon add-on at 1/120 solo and 1/200 duo, which add-on depending on
-- Araxxor's style. The rolls are independent. Legs and add-ons are each shown as
-- one group, whose chance doesn't depend on path or style. The game keeps one
-- kill count for solo and duo, so the player estimates their share of duo kills.

local common = require("src/bosses/common")

local LEG_TOP, LEG_MIDDLE, LEG_BOTTOM = 31718, 31719, 31720
local FANG, EYE, WEB = 31722, 31723, 31724
local LEGS = { name = "Leg pieces" }
local ADD_ONS = { name = "Noxious add-ons" }

local DUO = {
    key = "duo", -- saved data key: never change it
    label = "Kills done as a duo",
    default = 0,
    options = {
        { value = 0, label = "0%" }, { value = 5, label = "5%" }, { value = 10, label = "10%" },
        { value = 25, label = "25%" }, { value = 50, label = "50%" }, { value = 75, label = "75%" },
        { value = 100, label = "100%" },
    },
}

-- A kill's chance of a roll, from its solo and duo denominators and the share
-- of kills done as a duo.
local function mixed(solo, duo, duoPercent)
    local share = duoPercent / 100
    return (1 - share) / solo + share / duo
end

return {
    key = "araxxi", -- saved data key: never change it
    name = "Araxxi",
    logPage = "COLLECTION_BOSS_ARAXXI", -- the boss log page's database row
    assumptions = {},
    choices = { DUO },

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Normal", kc = "BSLAY_KILLS_ARAXXI", rolls = function(picks)
            return {
                { chance = mixed(40, 70, picks.duo), items = common.Even({ LEG_TOP, LEG_MIDDLE, LEG_BOTTOM }) },
                { chance = mixed(120, 200, picks.duo), items = common.Even({ FANG, EYE, WEB }) },
            }
        end },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [LEG_TOP] = { log = "ITEMLOG_ITEM_SB_LEG_TOP", kind = "unique", group = LEGS },
        [LEG_MIDDLE] = { log = "ITEMLOG_ITEM_SB_LEG_MIDDLE", kind = "unique", group = LEGS },
        [LEG_BOTTOM] = { log = "ITEMLOG_ITEM_SB_LEG_BOTTOM", kind = "unique", group = LEGS },
        [FANG] = { log = "ITEMLOG_ITEM_SB_FANG", kind = "unique", group = ADD_ONS }, -- Araxxi's fang
        [EYE] = { log = "ITEMLOG_ITEM_SB_EYE", kind = "unique", group = ADD_ONS }, -- Araxxi's eye
        [WEB] = { log = "ITEMLOG_ITEM_SB_WEB", kind = "unique", group = ADD_ONS }, -- Araxxi's web
        [35870] = { log = "ITEMLOG_ITEM_SB_PHEROMONE", kind = "excluded" }, -- Araxyte pheromone: a common drop
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

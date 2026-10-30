-- Araxxi (Araxxor's kill count).
--
-- From the RuneScape Wiki (CC BY-NC-SA 3.0), checked 2026-10-28: each kill rolls
-- a spider leg at 1/40 solo and 1/70 duo, which leg depending on the path taken,
-- and a weapon add-on at 1/120 solo and 1/200 duo, which add-on depending on
-- Araxxor's style. The rolls are independent. Legs and add-ons are each shown as
-- one group, whose chance doesn't depend on path or style.
--
-- The game keeps one kill count for solo and duo. Each tracked kill counts for
-- Solo or Duo by the fight's duo flag, so it's exact; untracked kills use the
-- player's share of duo kills.

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

local DUO = {
    key = "duo", -- saved data key: never change it
    label = "Kills done as a duo",
    default = 0,
    options = common.TENTHS,
    untrackedOnly = true, -- tracked kills use the duo flag
}

-- A kill's rolls, for a share of duo kills (0 to 1): a leg and an add-on.
local function rolls(duoShare)
    local function mixed(solo, duo)
        return (1 - duoShare) / solo + duoShare / duo
    end
    return {
        { chance = mixed(40, 70), items = common.Even({ LEG_TOP, LEG_MIDDLE, LEG_BOTTOM }) },
        { chance = mixed(120, 200), items = common.Even({ FANG, EYE, WEB }) },
    }
end

-- Tracked kills' modes, by name. Mode names are saved with the player's data:
-- never change them.
local TRACKED = {
    Solo = { name = "Solo", kc = VARS.kc, rolls = rolls(0) },
    Duo = { name = "Duo", kc = VARS.kc, rolls = rolls(1) },
}

return {
    key = "araxxi", -- saved data key: never change it
    name = "Araxxi",
    logPage = "COLLECTION_BOSS_ARAXXI", -- the boss log page's database row
    assumptions = {},
    choices = { DUO },

    -- Mode names are saved with the player's data: never change them. Normal gets
    -- the untracked kills (and kills tracked before the duo flag was read).
    modes = {
        { name = "Normal", kc = VARS.kc, untracked = true, rolls = function(picks)
            return rolls(picks.duo / 100)
        end },
    },
    killEvents = { { var = VARS.kc, reads = { duo = VARS.duo }, mode = function(values)
        return values.duo == 1 and "Duo" or "Solo"
    end } },
    modeFor = function(name) return TRACKED[name] end,

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
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

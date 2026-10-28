-- Every boss Boss RNG supports. Each file in src/bosses/ is plain data: see
-- src/bosses/kreearra.lua for the format, and src/bosses/amascut.lua and
-- sanctum.lua for the optional parts. (src/bosses/common.lua, godwars.lua and
-- godwars2.lua are helpers, not bosses.)
--
-- A mode can have a tier, { choice = key, value = v }, for modes sharing one kill
-- count var, split by one of the boss's choices (see src/choices.lua). A tracked
-- kill counts for the mode whose tier the choice's var is in; untracked kills,
-- for the mode of the player's pick.
--
-- Uniques can share a group, { name = "Leg pieces" }: one table row adding up
-- their counts and chances, shown with its lowest item's icon. For items whose
-- split depends on something the player chose (Araxxi's path) or that varies
-- (Araxxor's style): the group's total chance doesn't, so its luck is exact.
--
-- A boss can read vars for its rolls and assumptions: reads = { [key] = var }.
-- Once read, each value is passed with the picks under its key (TzKal-Zuk's
-- Igneous stones). Until then it's nil.
--
-- A boss's assumptions can be a function of the player's picks too, for ones
-- that only hold for some picks (Kerapac's duo kills).
--
-- A mode's rolls can be a function of the player's picks for the boss's choices
-- (see src/choices.lua), for rates set by one, such as Araxxi's share of duo kills.
--
-- A unique listed by more than one boss has one boss log count for all of them,
-- so its drops can't be told apart. Such a unique is pooled: it gets pooledBy,
-- the bosses that list it, and its count is split between them (see stats.Pools).

local BOSS_FILES = {
    "graardor", "kreearra", "kril", "nex", "zilyana", -- God Wars
    "furies", "gregorovic", "helwyr", "vindicta", -- God Wars 2
    "amascut", "sanctum", -- Amascut and Sanctum of Rebirth
    "araxxi", "barrows", "rots", "solak",
    "croesus", "kerapac", "zuk", -- Elder God Wars Dungeon
}

local bosses = {}
for _, file in ipairs(BOSS_FILES) do
    -- Assigning keeps only require's first result (Lua 5.4 also returns the path).
    bosses[#bosses + 1] = require("src/bosses/" .. file)
end

local listedBy = {} -- [log var] = the bosses listing that unique
for _, boss in ipairs(bosses) do
    for _, item in pairs(boss.items) do
        if item.kind == "unique" then
            listedBy[item.log] = listedBy[item.log] or {}
            table.insert(listedBy[item.log], boss)
        end
    end
end
for _, boss in ipairs(bosses) do
    for _, item in pairs(boss.items) do
        local sharers = item.kind == "unique" and listedBy[item.log]
        if sharers and #sharers > 1 then
            item.pooledBy = sharers
        end
    end
end

return bosses

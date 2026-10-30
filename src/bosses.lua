-- Every boss Boss RNG supports. Each file in src/bosses/ is plain data: see
-- src/bosses/kreearra.lua for the format, and src/bosses/amascut.lua and
-- sanctum.lua for the optional parts. (src/bosses/common.lua, godwars.lua and
-- godwars2.lua are helpers, not bosses.)
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
-- A boss can count each tracked kill for a mode made from the game's values at
-- the kill (Barrows chests by the brothers killed, Araxxi kills by team):
--   killEvents   a list of { var, mask, reads = { [key] = var }, mode = function(values) }:
--                when var (or with mask, those bits of it) goes up, the reads
--                are read and mode gives the mode's name, or nil to leave the
--                kill uncounted
--   modeFor      function(name): that mode ({ name, kc, rolls }); kc is nil for
--                kills outside the kill count, shown apart as extraKills (a
--                label, "partial")
-- The boss's own mode for that kill count is then marked byEvent, with no
-- rolls: its kill count isn't watched, since the events count its kills.
--
-- When a mode's rates change, its old ones stay for the kills tracked before:
--   olderRates   { { before = day, rolls = ... }, ... }, oldest first (days
--                from src/days.lua, e.g. days.FromDate(2026, 11, 24)): a kill
--                on a day before an entry's day uses that entry's rolls; later
--                kills use the mode's own. Kills are saved by day, so an update
--                with new rates applies to kills tracked before it shipped.
--
-- A boss's assumptions can be a function of the player's picks too, for ones
-- that only hold for some picks (Kerapac's duo kills).
--
-- A mode's rolls can be a function of the player's picks for the boss's choices
-- (see src/choices.lua), for rates set by one, such as Kerapac's team.
--
-- A unique listed by more than one boss has one boss log count for all of them,
-- so its drops can't be told apart. Such a unique is pooled: it gets pooledBy,
-- the bosses that list it, and a tracked drop counts for the boss killed last
-- (see tracker.AddDrops).

local BOSS_FILES = {
    "graardor", "kreearra", "kril", "nex", "zilyana", -- God Wars
    "furies", "gregorovic", "helwyr", "vindicta", -- God Wars 2
    "amascut", "sanctum", -- Amascut and Sanctum of Rebirth
    "araxxi", "barrows", "rots", "solak",
    "croesus", "kerapac", "zuk", -- Elder God Wars Dungeon
    "dragonkin", -- elite dungeons
    "corp", "raksha", "rasial",
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

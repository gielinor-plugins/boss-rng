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
-- A unique listed by more than one boss has one boss log count for all of them,
-- so its drops can't be told apart. Such a unique is pooled: it gets pooledBy,
-- the bosses that list it, and its count is split between them (see stats.Pools).

local BOSS_FILES = {
    "graardor", "kreearra", "kril", "nex", "zilyana", -- God Wars
    "furies", "gregorovic", "helwyr", "vindicta", -- God Wars 2
    "amascut", "sanctum", -- Amascut and Sanctum of Rebirth
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

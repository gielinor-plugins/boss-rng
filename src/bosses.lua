-- Every boss Boss RNG supports. Each file in src/bosses/ is plain data (common.lua,
-- godwars.lua, godwars2.lua and elite_dungeon.lua are helpers). Fields:
--   key          saved data key: never change
--   name         shown name
--   assumptions  a list of lines, or function(picks) giving one, for ones that hold for some picks
--   modes        a list of { key, kc, rolls, byEvent }. key: short, saved, never change. kc: kill count
--                varbit. rolls: a plain list, or function(r, picks) of a day's rate values (named
--                in src/core/rates/, by boss key) and the player's picks, so each kill uses its
--                day's rates. byEvent: kills are counted by killEvents, containers or claims, so
--                kc isn't watched; it has no rolls unless kills are counted for it directly
--   items        { [item id] = { log, kind, group, stack } }, every item on the boss log page.
--                log: its log count varbit. kind:
--                  unique    counted in luck
--                  shared    log count includes other monsters' drops, so not counted
--                  lore      not counted (no log count varbit found)
--                  pet       not counted (no log count varbit found)
--                  excluded  on the page but not counted, e.g. no published drop rate
--                group = { name }: uniques shown as one row, with the lowest item's icon; for a
--                split that varies (Araxxi's path), the group's total chance is still exact.
--                stack = { most, word }: a log rise of up to most is one drop, and the log count
--                (items, not drops) shows apart as a count of word ("spike")
--   pooledBy     set below: a unique listed by more than one boss has one log count, so a drop
--                counts for the boss killed last (see tracker.AddDrops)
--   reads        { [key] = var }: each value is passed with the picks under key (nil until read)
--   choices      player picks for rates set by one (src/core/choices.lua); choicesHelp: paragraphs
--                on the settings page saying why and how to set them
--   killEvents   a list of { var, mask, reads, lasts, mode }: when var (or its mask bits) rises,
--                mode(values) gives the kill's mode key, or nil to leave it uncounted. lasts = { [key]
--                = varbit } gives its last value above 0 since the previous kill (for values the
--                game resets at the kill, like Croesus's contribution)
--   modeFor      function(key): an event's mode; kc nil means outside the kill count
--   extraKills   label for kills outside the kill count ("partial")
--   containers   { [item id] = { mode, window } }: counts containers opened, not kills (see
--                src/core/containers.lua)
--   claims       a list of { var, mask, kills, reads, mode(values, old) }: counts loot claimed
--                from a chest, not kills (see src/core/claims.lua)
--   unit         what kills are called in the numbers ("chest"); tip: a line on how to play so
--                they're counted

local BOSS_FILES = {
    "graardor", "kreearra", "kril", "nex", "zilyana", -- God Wars
    "furies", "gregorovic", "helwyr", "vindicta", -- God Wars 2
    "amascut", "sanctum", -- Amascut and Sanctum of Rebirth
    "araxxi", "barrows", "rots", "solak",
    "croesus", "kerapac", "zuk", -- Elder God Wars Dungeon
    "dragonkin", "shadow_reef", -- elite dungeons
    "corp", "elidinis", "magister", "raksha", "rasial", "vorkath",
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

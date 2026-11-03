-- Every boss Boss RNG supports. Each file in src/bosses/ is plain data (common.lua,
-- egwd.lua, godwars.lua, godwars2.lua and elite_dungeon.lua are helpers). Fields:
--   key           saved data key: never change
--   name          shown name
--   assumptions   a list of lines, or function(readings) giving them
--   modes         a list of { key, kc, rolls, byEvent }:
--                   key      short and saved: never change
--                   kc       kill count varbit
--                   rolls    a plain list, or function(r, readings, means) of the day's
--                            rate values (src/core/rates/, by boss key), the values read
--                            from the game (see reads) and the day's averages of its
--                            kills' sums (see killEvents; nil without)
--                   byEvent  counted by killEvents, containers or claims, so kc isn't
--                            watched; no rolls unless kills are counted for it directly
--   items         { [item id] = { log, group, stack } }: the uniques counted in luck.
--                 Boss log items not counted are listed in the boss's doc.
--                   log      log count varbit
--                   group    { name }: uniques shown as one row, with the lowest item's
--                            icon; for a split that varies (Araxxi's path), the group's
--                            total chance is still exact
--                   stack    { most, word, plural }: a log rise of up to most is one
--                            drop, and the log count (items) shows apart as a count of
--                            word ("spike"; plural if not word .. "s")
--   pooledBy      set below: a unique listed by more than one boss has one log count,
--                 so a drop counts for the boss killed last (see tracker.AddDrops)
--   reads         { [key] = var }: each value is passed in readings (nil until read)
--   killEvents    a list of { var, mask, reads, lasts, rises, piles, sums, mode }: when
--                 var (or its mask bits) rises, mode(values) gives the kill's mode key,
--                 or nil to leave it uncounted (see src/core/killevents.lua):
--                   reads    { [key] = var }: read at the kill
--                   lasts    { [key] = varbit }: its last value above 0 since the
--                            previous kill, for values the game resets at the kill
--                            (Croesus's contribution)
--                   rises    { [key] = varbit }: true if it rose in the kill's tick
--                            (Zuk's Igneous stones)
--                   piles    { item ids }: values.piles, the player's loot piles that
--                            gained one in the kill's tick (src/core/piles.lua)
--                   sums     { keys of values }: added up over each day's kills and
--                            passed to rolls as averages (Arch-Glacor's enrage, streak)
--   dropsAtClaim  { var, most }: var falls to 0 when waiting loot is claimed
--                 (Arch-Glacor's streak). Drops count only just after a claim, not
--                 after any kill this session, and a log can rise by up to most at once
--   modeFor       function(key): an event's mode; kc nil means outside the kill count
--   extraKills    label for kills outside the kill count ("partial")
--   containers    { [item id] = { mode, window } }: counts containers opened, not
--                 kills (src/core/containers.lua)
--   claims        a list of { var, mask, kills, reads, mode(values, old) }: counts loot
--                 claimed from a chest, not kills (src/core/claims.lua)
--   unit          what kills are called in the numbers ("chest")
--   tip           a line on how to play so kills are counted

local BOSS_FILES = {
    "amascut",
    "araxxi",
    "archglacor",
    "barrows",
    "corp",
    "croesus",
    "dragonkin",
    "elidinis",
    "furies",
    "graardor",
    "gregorovic",
    "helwyr",
    "kerapac",
    "kreearra",
    "kril",
    "magister",
    "nex",
    "raksha",
    "rasial",
    "rots",
    "sanctum",
    "shadow_reef",
    "solak",
    "vindicta",
    "vorkath",
    "zilyana",
    "zuk",
}

local bosses = {}
for _, file in ipairs(BOSS_FILES) do
    -- Assigning keeps only require's first result (Lua 5.4 also returns the path).
    bosses[#bosses + 1] = require("src/bosses/" .. file)
end

local listedBy = {} -- [log var] = the bosses listing that unique
for _, boss in ipairs(bosses) do
    for _, item in pairs(boss.items) do
        listedBy[item.log] = listedBy[item.log] or {}
        table.insert(listedBy[item.log], boss)
    end
end
for _, boss in ipairs(bosses) do
    for _, item in pairs(boss.items) do
        local sharers = listedBy[item.log]
        if #sharers > 1 then
            item.pooledBy = sharers
        end
    end
end

return bosses

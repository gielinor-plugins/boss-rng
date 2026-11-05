-- Every boss Boss RNG supports. Each is a data file in src/bosses/, listed below;
-- common.lua, egwd.lua, godwars.lua, godwars2.lua and elite_dungeon.lua are helpers
-- they share. docs/technical/overview.md shows how kill counts and modes fit together.
--
-- Players' saved data is keyed by a boss's key and its mode keys, so never change one
-- (spec/saved_keys_spec.lua fails if one stops loading).
--
-- Every boss has:
--   key          its saved key: short and lowercase
--   name         the name players see
--   assumptions  lines for the Info tab, or a function(readings) returning them
--   killCounts   { var, mode } for each of its kill count varbits, which add up to its
--                all-time kills. When one with a mode rises, each kill it rose by is a
--                kill of that mode. Kills of one without a mode are counted by
--                killEvents, claims or containers.
--   modes        { [key] = mode }: each kind of kill, by the key its kills are saved
--                under. Loading sets mode.key. A mode has:
--                  rolls    its unique rolls: a list, or a function(r, readings,
--                           means) returning one. r is the rates in effect on the
--                           kill's day (src/core/rates/), readings the values read
--                           from the game (reads), and means that day's averages of
--                           its kills' sums (nil if it has none)
--                  piles    loot piles each kill gives (Kerapac)
--                  partial  true if its kills aren't in the kill count (Barrows)
--   items        { [item id] = item }: the uniques counted. Collection log items left
--                out are listed in the boss's doc page. An item has:
--                  log      its collection log count varbit
--                  group    { name }: shown as one row with its group (Araxxi's legs);
--                           the group's chance is exact even when the split varies
--                  stack    { most, word, plural }: a count rise of up to most is one
--                           drop, and the count is shown on its own ("184 spikes")
--
-- And, when it needs them:
--   reads         { [key] = var }: values passed to rolls and assumptions as readings
--   killEvents    kills told apart by values read at the kill (src/core/kill_events.lua):
--                 a list of { var, mask, reads, lasts, rises, pileItems, sums, mode }.
--                 When var (or its mask bits) rises, mode(values) returns the kill's
--                 mode key, or nil to leave the kill uncounted.
--                   reads      { [key] = var }: read at the kill
--                   lasts      { [key] = varbit }: its last value above 0 before the
--                              kill, for values the game resets at the kill (Croesus)
--                   rises      { [key] = varbit }: true if it rose with the kill (Zuk)
--                   pileItems  item ids marking a loot pile: values.piles is how many
--                              of the player's piles gained one with the kill
--                              (Kerapac)
--                   sums       keys of values to add up by day and pass to rolls as
--                              averages (Arch-Glacor's enrage and streak)
--   claims        kills counted by loot claimed from a chest (src/core/claims.lua): a
--                 list of { var, mask, kills, reads, mode(values, old) }
--   containers    kills counted by chests opened from the backpack
--                 (src/core/containers.lua): { [item id] = { mode, window } }
--   dropsAtClaim  { var, most }: uniques reach the collection log when waiting loot is
--                 claimed, seen as var falling to 0. Drops count only just after a
--                 claim, and a count may rise by up to most at once (Arch-Glacor)
--   unit          what luck counts, if not kills ("chest")
--   extraKills    what partial kills are called ("partial")
--   tip           a line for the Info tab on how to play so kills are counted
--
-- Loading also sets item.pooledBy on a unique more than one boss lists: they share one
-- collection log count, so a drop counts for the boss killed last (tracker.AddDrops).

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

local listedBy = {} -- [collection log var] = the bosses listing that unique
for _, boss in ipairs(bosses) do
    for key, mode in pairs(boss.modes) do
        mode.key = key
    end
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

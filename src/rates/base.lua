-- Each boss's published rates when Boss RNG added it, by boss key (see
-- src/rates.lua): every number a game update could change, as named values its
-- boss file builds rolls from. Boss files only say which items share a roll,
-- and split a roll evenly unless a rate here says otherwise. Sources and dates
-- are in each boss file's header. Rates are chances per kill unless the name
-- says otherwise.

-- A God Wars general's hilt: 1/512, rolled only when its 1/64 unique table misses.
local GWD_HILT = (1 - 1 / 64) / 512

-- A God Wars 2 boss's rates: every table item, its crest and its essence roll,
-- by mode, with own written over them.
local function godWars2(own)
    local values = { normal = 1 / 256, normalEssence = 1 / 64, hard = 1 / 179, hardEssence = 1 / 44 }
    for name, value in pairs(own or {}) do
        values[name] = value
    end
    values.normalCrest, values.hardCrest = values.normal, values.hard
    return values
end

return {
    day = nil, -- the first version: no update day
    rates = {
        amascut = { -- each roll's chance: normal mode, then each enrage tier
            armorShare = 3 / 4, -- of each gear roll, split over five pieces (weapons get the rest)
            gear = 1 / 600, nexus = 1 / 750,
            gear100 = 1 / 70, nexus100 = 1 / 280, shard100 = 1 / 280,
            gear500 = 1 / 60, nexus500 = 1 / 240, shard500 = 1 / 240,
            gear750 = 1 / 50, nexus750 = 1 / 200, shard750 = 1 / 200,
            gear1000 = 1 / 35, nexus1000 = 1 / 140, shard1000 = 1 / 140,
            gear2000 = 1 / 25, nexus2000 = 1 / 100, shard2000 = 1 / 100,
        },
        araxxi = { soloLegs = 1 / 40, soloAddOns = 1 / 120, duoLegs = 1 / 70, duoAddOns = 1 / 200 },
        barrows = { -- per chest
            linza = 1 / 96, amulet = 1 / 480,
            -- Each equipment roll: 1 in max(pieceBase - piecePerBrother x brothers, pieceBest),
            -- one roll per brother plus one, up to maxRolls.
            pieceBase = 450, piecePerBrother = 58, pieceBest = 73, maxRolls = 7,
        },
        corp = { sigil = 1 / 256, elixir = 3 / 512 },
        -- Each item per loot roll, and the loot rolls at full contribution.
        croesus = { armor = 1 / 5400, other = 1 / 5400, lootRolls = 12 },
        dragonkin = { solo = 1 / 83, duo = 1 / 166, trio = 1 / 250 },
        furies = godWars2(),
        graardor = { armor = 1 / 384, hilt = GWD_HILT },
        gregorovic = godWars2(),
        helwyr = godWars2(),
        kerapac = { piles = 3, normal = 1 / 256, hardStaff = 1 / 400, hard = 1 / 180 }, -- per loot pile
        kreearra = { armor = 1 / 384, hilt = GWD_HILT },
        kril = { armor = 1 / 512, spear = 1 / 512, staff = 1 / 512, hilt = GWD_HILT },
        magister = { phylactery = 1 / 18, gloves = 1 / 500 },
        nex = { table = 6 / 128 },
        raksha = { boots = 1 / 130, other = 1 / 325 },
        rasial = { weapon = 1 / 320, armor = 1 / 128 },
        rots = { table = 1 / 80 },
        sanctum = { books = 1 / 125, weapons = 1 / 75, hardBooks = 1 / 100, hardWeapons = 1 / 60, hardShard = 1 / 75 },
        solak = { grimoire = 1 / 200, crossbow = 1 / 400, stave = 1 / 500, mushroom = 1 / 500 },
        vindicta = godWars2({ normal = 1 / 255 }),
        vorkath = { -- per chest
            spike = 1 / 45, codex = 1 / 249,
            hardSpike = 1 / 15, hardCodex = 1 / 150, hardScale = 1 / 150,
        },
        zilyana = { other = 1 / 320, crossbow = 1 / 640, hilt = GWD_HILT },
        zuk = { normal = 1 / 100, hard = 1 / 50, sword = 1 / 30, swordNoCheckpoints = 1 / 27 },
    },
}

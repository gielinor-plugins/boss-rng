-- Jagex's Late-Game Rebalance (design preview: "late November 2026"), the rates
-- it changed for supported bosses, by boss key (see src/rates.lua).
-- Decided where the post doesn't say: God Wars 1 armor includes the shields,
-- and a kill still gives at most one table item; God Wars 2 hard mode crests
-- change like normal mode's; Croesus's rates are per loot roll.

local days = require("src/days")

local CREST = 1 / 128
local HILT = 1 / 384

return {
    day = days.FromDate(2026, 11, 30), -- assumed the last Monday until the patch notes confirm it
    rates = {
        barrows = { amulet = 1 / 240 },
        croesus = { armor = 1 / 3000, other = 1 / 2500 },
        furies = { normalCrest = CREST, hardCrest = CREST },
        graardor = { armor = 1 / 320, hilt = HILT },
        gregorovic = { normalCrest = CREST, hardCrest = CREST },
        helwyr = { normalCrest = CREST, hardCrest = CREST },
        kreearra = { armor = 1 / 320, hilt = HILT },
        kril = { armor = 1 / 320, spear = 1 / 384, staff = 1 / 64, hilt = HILT },
        solak = { crossbow = 1 / 200 },
        vindicta = { normalCrest = CREST, hardCrest = CREST },
        zilyana = { crossbow = 1 / 320, hilt = HILT },
    },
}

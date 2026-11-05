-- Jagex's Late-Game Rebalance: the rates its design preview changed for supported
-- bosses, by boss key (see src/core/rates.lua).
-- Assumed where the post doesn't say: God Wars 1 armor includes the shields,
-- and a kill still gives at most one table item; God Wars 2 hard mode crests
-- change like normal mode's; Croesus's rates are per unique roll.

local days = require("src/utils/days")

local CREST = 1 / 128
local HILT = 1 / 384

return {
    -- From Jagex's November schedule, "November's Month Ahead".
    day = days.FromDate(2026, 11, 23),
    rates = {
        barrows = { amulet = 1 / 240 },
        croesus = { armor = 1 / 3000, other = 1 / 2500 },
        elidinis = { rare = 1 / 256 },
        furies = { normalCrest = CREST, hardCrest = CREST },
        graardor = { armor = 1 / 320, hilt = HILT },
        gregorovic = { normalCrest = CREST, hardCrest = CREST },
        helwyr = { normalCrest = CREST, hardCrest = CREST },
        kreearra = { armor = 1 / 320, hilt = HILT },
        kril = { armor = 1 / 320, spear = 1 / 384, staff = 1 / 64, hilt = HILT },
        magister = { phylactery = 1 / 10, gloves = 1 / 128 },
        solak = { crossbow = 1 / 200 },
        vindicta = { normalCrest = CREST, hardCrest = CREST },
        zilyana = { crossbow = 1 / 320, hilt = HILT },
    },
}

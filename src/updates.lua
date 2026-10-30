-- Game updates that changed drop rates, by the day they went live (see
-- src/days.lua). Boss files date their rate versions with these (see
-- src/rates.lua), so one date switches every boss an update changed. An update
-- whose day isn't known yet is false: rates prepared for it aren't used.
--
-- Rates are worked out from each tracked kill's day whenever they're shown, so
-- a plugin update that ships after the game update re-rates every kill since.

local days = require("src/days")

local updates = {}

-- Jagex's Late-Game Rebalance: "late November 2026". Assumed to be the last
-- Monday until the patch notes confirm it.
updates.LATE_GAME_REBALANCE = days.FromDate(2026, 11, 30)

return updates

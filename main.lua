-- Boss RNG: how lucky have you been at bosses?

local bosses = require("src/bosses")
local gameVars = require("src/core/game_vars")
local tracker = require("src/core/tracker")
local bossUi = require("src/ui")

bossUi.Start()
gameVars.Start(bosses, tracker.AddKills, tracker.AddDrops, bossUi.Refresh)
print("[Boss RNG] Enabled")

-- The client calls this when the plugin is turned off or reloaded.
function PluginShutdown()
    gameVars.Stop()
    bossUi.Stop()
    print("[Boss RNG] Disabled")
end

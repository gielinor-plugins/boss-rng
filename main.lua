-- Boss RNG: how lucky have you been at bosses?

local bosses = require("src/bosses")
local gamevars = require("src/core/gamevars")
local tracker = require("src/core/tracker")
local bossUi = require("src/ui")

bossUi.Start()
gamevars.Start(bosses, tracker.AddKills, tracker.AddDrops, bossUi.Refresh)
print("[Boss RNG] Enabled")

-- The client calls this when the plugin is turned off or reloaded.
function PluginShutdown()
    gamevars.Stop()
    bossUi.Stop()
    print("[Boss RNG] Disabled")
end

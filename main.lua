-- Boss RNG: how lucky have you been at bosses?
-- The game runs this file when the plugin is turned on.

local bosses = require("src/bosses")
local gamevars = require("src/gamevars")
local tracker = require("src/tracker")
local bossUi = require("src/ui")

gamevars.Start(bosses, tracker.AddKills, tracker.AddDrops)
bossUi.Start()
print("[Boss RNG] Enabled")

-- The client calls this when the plugin is turned off or reloaded.
function PluginShutdown()
    gamevars.Stop()
    bossUi.Stop()
    print("[Boss RNG] Disabled")
end

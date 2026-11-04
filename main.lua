-- Boss RNG's entry point: starts the UI and game_vars, and stops both when the plugin
-- is turned off. docs/technical/overview.md explains how the modules fit together.

local bosses = require("src/bosses")
local gameVars = require("src/core/game_vars")
local tracker = require("src/core/tracker")
local bossUi = require("src/ui")

bossUi.Start()
gameVars.Start(bosses, tracker.AddKills, tracker.AddDrops, bossUi.Refresh)

-- The client calls this when the plugin is turned off or reloaded.
function PluginShutdown()
    gameVars.Stop()
    bossUi.Stop()
end

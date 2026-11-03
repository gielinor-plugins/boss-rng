-- Lint settings for luacheck: run `luacheck .` from the project root.

std = "lua54"
max_line_length = 100 -- the same as .stylua.toml's column_width
exclude_files = { "dev/", "reference/", "dist/" }

-- The game API. main.lua defines PluginShutdown, which the client calls.
globals = { "PluginShutdown" }
read_globals = {
    "Event",
    "GameState",
    "Inventory",
    "Player",
    "PersistentDB",
    "Vector4",
    "config",
    "id",
    "prettyui",
    "ui",
    "var",
}

-- Tests run under busted, and spec/mock_api.lua sets up the game API itself.
files["spec/"] = {
    std = "+busted",
    globals = { "Event", "GameState", "Inventory", "Player", "PersistentDB", "config", "ui", "var" },
}

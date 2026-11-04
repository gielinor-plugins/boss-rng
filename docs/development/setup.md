# Development setup

## The repository

```
main.lua      the entry point the game runs
plugin.json   the plugin manifest
src/          plugin modules, loaded with require("src/...")
  bosses/     one data file per boss (src/bosses.lua lists them and documents the format)
  core/       reading the game, tallies, stats and luck math
    rates/    drop rates, one file per game update
  ui/         the panel, details window and settings page (src/ui.lua runs them)
  utils/      helpers with no boss knowledge
spec/         tests, in the same folders as src/
docs/         this documentation
tools/        sync.sh (copy to the beta client), package.sh (build the mod.io zip)
```

Only `main.lua`, `plugin.json`, `src/` and `resources/` (if added) are shipped.
Everything else stays out of the mod.io zip, as Jagex's
[good practice](https://developer.runescape.com/rs/submission/goodpractice.html)
page asks.

## Tools

- [Lua 5.4](https://www.lua.org/) and [busted](https://lunarmodules.github.io/busted/)
  to run the tests.
- [StyLua](https://github.com/JohnnyMorganz/StyLua) to format (settings in
  `.stylua.toml`).
- [luacheck](https://github.com/lunarmodules/luacheck) to lint (settings in
  `.luacheckrc`).

On macOS, `brew install lua luarocks stylua luacheck`, then `luarocks install busted`.

## Running in game

1. Join the plugin beta world, as Jagex's
   [first tutorial](https://developer.runescape.com/rs/tutorial/1helloworld.html)
   describes.
2. Install the UI library named in `plugin.json` from the Plugin Hub. Dev mode
   doesn't download dependencies.
3. Run `tools/sync.sh` to copy the plugin into the client's `dev_plugins` folder.
   Set `BOSS_RNG_DEV_DIR` if your client isn't in the default place.
4. In the game console (Alt or Option + the key under Esc), run `prf`, then
   `pon boss_rng`.
5. After each edit, run `tools/sync.sh`, then `prl boss_rng` in the console.

After changing `plugin.json`'s dependencies, restart the client.

## Before committing

```
busted
stylua .
luacheck .
```

All three must pass. See [Testing](testing.md) for what the tests cover and what
has to be checked in game.

# Boss RNG

Boss RNG shows how lucky you have been with boss log drops at every boss in the
Beasts tab: for each item, each boss, and overall.

## Your data

Boss RNG stores its data **only on your device**. It makes no internet requests
and sends nothing to anyone.

Questions or deletion requests: gielinorplugins@gmail.com

## Development

### Project layout

```
main.lua      entry point the game runs
plugin.json   plugin manifest
src/          plugin modules, loaded with require("src/...")
resources/    images and sounds, if added later (a folder name the game reserves)
spec/         tests
tools/        sync.sh (copy to the beta env locally), package.sh (build the mod.io zip)
docs/         design notes and API notes
```

Only `main.lua`, `plugin.json`, `src/` and `resources/` are shipped.

### Testing in game

1. Join the plugin beta world and import your save (see the
   [official tutorial](https://developer.runescape.com/rs/tutorial/1helloworld.html)).
2. Run `tools/sync.sh` to copy the plugin to
   `~/Jagex/RuneScape-BETA/dev_plugins/boss_rng`.
3. In the console (Alt or Option + the key under Esc), run `prf`, then `pon boss_rng`.
4. After each edit, run `tools/sync.sh` again, then `prl boss_rng`.

### Releasing

Run `tools/package.sh` to build `dist/boss_rng-<version>.zip` for mod.io.

## Credits

Drop rates come from the [RuneScape Wiki](https://runescape.wiki/), licensed under
CC BY-NC-SA 3.0.

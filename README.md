# Boss RNG

Boss RNG shows how lucky you have been with boss log uniques, compared to an
average player with the same kills: for each item, each boss, and overall. It
shows where you stand, never drop rates.

Supported bosses:

- **God Wars Dungeon:** General Graardor, Kree'arra, Commander Zilyana, K'ril
  Tsutsaroth and Nex.
- **God Wars Dungeon 2:** Helwyr, Vindicta & Gorvek, the Twin Furies and Gregorovic.
- **Amascut, the Devourer** and the **Sanctum of Rebirth** (Vermyx, Kezalam and
  Nakatra, as one entry).

## What Boss RNG reads

Boss RNG only uses information the game has already shown you:

- **Kills and drops as they happen.** When a boss's kill count or a unique's boss
  log count goes up, Boss RNG counts the change. Changes in the first seconds
  after logging in are ignored, so the login sync isn't mistaken for kills.
- **Your all-time kill count**, only while the Beasts tab is showing that boss.
- **Amascut's enrage** for each kill, from the enrage you chose for the instance.
  For kills from before Boss RNG, you pick the enrage in the Details window.
- **Your all-time boss log counts**, only while the boss log is open on that
  boss's page.

Both all-time counts have to be seen in the same session before they're used.
Until then, Boss RNG uses the kills and drops it has tracked itself. It never
reads hidden values such as bad luck mitigation, and it never interacts with the
game for you.

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

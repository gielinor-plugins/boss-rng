# Boss RNG

Boss RNG shows how lucky you have been with boss log uniques, compared to an
average player with the same kills: for each boss and each item. It
shows where you stand, never drop rates.

Luck comes from the kills Boss RNG tracks, from the day you install it: each
kill at the drop rates of its day, so rate changes never blur your numbers. It
shows as soon as you get a unique, or once an average player would have had
about one. Until then, each unique shows how many players would still be dry
after the same kills. Your all-time kill counts and boss log
counts are shown next to it, as facts from the game.

Supported bosses:

- **God Wars Dungeon:** General Graardor, Kree'arra, Commander Zilyana, K'ril
  Tsutsaroth and Nex.
- **God Wars Dungeon 2:** Helwyr, Vindicta & Gorvek, the Twin Furies and Gregorovic.
- **Amascut, the Devourer** and the **Sanctum of Rebirth** (Vermyx, Kezalam and
  Nakatra, as one entry).
- **Araxxi**, the **Barrows brothers**, **Barrows: Rise of the Six** and **Solak.**
- **Corporeal Beast**, **The Magister**, **Raksha, the Shadow Colossus** and
  **Rasial, the First Necromancer.**
- **Elder God Wars Dungeon:** Croesus, Kerapac and TzKal-Zuk.
- **Dragonkin Laboratory** (Astellarn, Verak Lith and the Black stone dragon, as one entry).
- **The Shadow Reef** (the Ambassador's crossbow pieces).
- **Zemouregal & Vorkath** (normal and hard mode, by chests opened).

## What Boss RNG reads

Boss RNG only uses information the game has already shown you:

- **Your kill counts and boss log counts**, the same numbers the Beasts tab and
  boss log show, without either needing to be open.
- **Kills and drops as they happen.** When a boss's kill count or a unique's boss
  log count goes up, Boss RNG counts the change, to keep what the game doesn't:
  dry streaks, and which boss a shared drop came from. Changes in the first
  seconds after logging in are ignored, so the login sync isn't mistaken for kills.
- **Amascut's enrage** for each kill, from the enrage you chose for the instance.
- **The date**, from the game clock, so each kill uses the rates of its day.

It never reads hidden values such as bad luck mitigation, and it never interacts
with the game for you.

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

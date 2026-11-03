# Boss RNG

Boss RNG shows how lucky you have been with boss log uniques, for each boss and
each item, compared to an average player with the same kills. It never shows
drop rates.

Luck is based on the kills Boss RNG tracks from the day you install it. Each kill
is measured against the drop rates at the time, so a later drop rate change won't
rewrite your past luck. Early on, before there's enough to rate your luck, it shows
how many players would still have no unique after the same number of kills. Your
all-time kill counts and boss log counts are shown beside it, as facts from the
game. Any assumption a boss needs is shown on its Info tab.

## What Boss RNG reads

Only information the game already shows you:

- **Kill counts and boss log counts**, as the Beasts tab and boss log show them,
  without either being open. Each rise is a kill or a drop. Changes in the first
  seconds after login are ignored, so the login sync isn't taken for kills.
- **What sets a kill's rates**, read as it happens: Amascut's enrage and loot
  piles, Kerapac's loot piles (the ones you own as they land), Croesus
  contribution, elite dungeon team size, Araxxi's duo, the Barrows brothers
  killed, Vorkath chests opened, and whether a TzKal-Zuk run gave an Igneous
  stone (no checkpoints).
- **The date**, from the game clock, so each kill uses the drop rates at the time.

It never reads hidden values such as bad luck mitigation, and never acts in the
game for you.

## Supported bosses

- Amascut, the Devourer
- Araxxi
- Barrows Brothers
- Barrows: Rise of the Six
- Commander Zilyana
- Corporeal Beast
- Croesus
- Dragonkin Laboratory (Astellarn, Verak Lith and the Black stone dragon)
- The Gate of Elidinis
- General Graardor
- Gregorovic
- Helwyr
- Kerapac
- Kree'arra
- K'ril Tsutsaroth
- The Magister
- Nex
- Raksha, the Shadow Colossus
- Rasial, the First Necromancer
- Sanctum of Rebirth (Vermyx, Kezalam and Nakatra)
- The Shadow Reef (the Ambassador)
- Solak
- The Twin Furies
- TzKal-Zuk
- Vindicta & Gorvek
- Zemouregal & Vorkath (by chests opened)

## Your data

Boss RNG stores its data **only on your device**. It makes no internet requests
and sends nothing to anyone.

To start fresh, use Data Controls in Plugin Hub > Manage > Boss RNG: reset one
boss, or every boss, for the character you're logged in as. The game's own counts
aren't changed.

Questions or deletion requests: gielinorplugins@gmail.com

## Development

```
main.lua      entry point the game runs
plugin.json   plugin manifest
src/          plugin modules, loaded with require("src/...")
  bosses/     one data file per boss (src/bosses.lua lists them and documents the format)
  core/       game reading, tallies and luck math
    rates/    drop rates, one file per game update
  ui/         the panel, window and settings page (src/ui.lua runs them)
  utils/      helpers with no boss knowledge
spec/         tests, in the same folders as src/
docs/         each boss's rates, vars and tests (bosses/), and saved data rules (data/)
tools/        sync.sh (copy to the beta client), package.sh (build the mod.io zip)
```

Only `main.lua`, `plugin.json`, `src/` and `resources/` (if added) are shipped.

- **Tests:** run `busted` from the project root.
- **Formatting:** run [StyLua](https://github.com/JohnnyMorganz/StyLua) (`stylua .`)
  from the project root before committing.
- **In game:** join the plugin beta world (see the
  [official tutorial](https://developer.runescape.com/rs/tutorial/1helloworld.html))
  and install the dependency named in `plugin.json` from the Plugin Hub, since
  dev mode doesn't download it. Run `tools/sync.sh`, then in the console (Alt or
  Option + the key under Esc) run `prf` and `pon boss_rng`. After each edit, run
  `tools/sync.sh` and `prl boss_rng`. After changing `plugin.json`'s
  dependencies, restart the client.
- **Release:** `tools/package.sh` builds `dist/boss_rng-<version>.zip` for mod.io.

## Credits

Drop rates come from the [RuneScape Wiki](https://runescape.wiki/), licensed under
CC BY-NC-SA 3.0.

Thanks to these players for helping test group boss kills during development:
dye abolical, EdiblePantys, Memes, Nymbi and Sir Wally I.

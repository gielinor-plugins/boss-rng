# Helwyr

Source: [RuneScape Wiki](https://runescape.wiki/w/Helwyr) (CC BY-NC-SA 3.0), checked 27 October 2026; crest from Jagex's [Late-Game Rebalance](https://secure.runescape.com/m=news/late-game-rebalance-design-preview).

## Drop rates

Each kill rolls one table for the Crest of Seren, Wand of the Cywir elders, Orb
of the Cywir elders or a dormant anima core piece, every item at the same rate.
Only if that misses is there a roll for Serenic essence.

| Item | Normal | Hard mode |
|---|---|---|
| Each table item | 1 in 256 | 1 in 179 |
| Serenic essence | 1 in 64 | 1 in 44 |

From the Late-Game Rebalance, the Crest of Seren is 1 in 128 in both modes, and the
other table items stay as they are. The rebalance doesn't give a hard mode rate, so
it's assumed to be the same.

## How kills are counted

- Assumed solo (the Info tab says so): the kill count doesn't say who you killed
  with, and group kills share drops, so group killers' luck reads low.
- Normal and hard mode kill counts are both counted.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_HELWYR` | Normal mode kill count. |
| `BSLAY_KILLS_HELWYR_HARDMODE` | Hard mode kill count. |
| `ITEMLOG_ITEM_GWD2_SEREN_<ITEM>` | Collection log count each: `CREST`, `WEAPON` (wand), `WEAPON_OFFHAND` (orb), `ESSENCE`. |

## Not counted

- **Helwyr's head** (boss trophy, 1 in 500): not on the collection log.
- **Dormant anima core pieces** (helm, body, legs): one collection log count shared
  by all four God Wars Dungeon 2 bosses. They still take table share above.
- **Lilwyr** (pet): pets aren't counted.

| Collection log item | Id |
|---|---|
| Dormant anima core helm | 37009 |
| Dormant anima core body | 37012 |
| Dormant anima core legs | 37015 |
| Lilwyr | 37182 |

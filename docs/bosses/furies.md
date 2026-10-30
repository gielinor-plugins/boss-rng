# The Twin Furies

How Boss RNG counts your Twin Furies kills. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/The_Twin_Furies)
(CC BY-NC-SA 3.0).

## Drop rates

Each kill rolls one table for the Crest of Zamorak, Blade of Nymora, Blade of
Avaryss or a dormant anima core piece, every item at the same rate: 1 in 256 per
kill in normal mode and 1 in 179 in hard mode. Only if that misses, there's a
roll for Zamorakian essence: 1 in 64 in normal mode and 1 in 44 in hard mode.

## How Boss RNG counts your kills

Kills shared with a group share their drops, and your kill count doesn't say who
you killed with. So Boss RNG assumes every kill was solo, and the "i" says so.
If you often kill in groups, the average player numbers are higher than they
should be for you, and your luck reads lower than it is.

Normal and hard mode kills have their own kill counts, and both are counted.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_TWINDEMONS` | Your Twin Furies kill count. |
| `BSLAY_KILLS_TWINDEMONS_HARDMODE` | Your hard mode kill count. |
| `ITEMLOG_ITEM_GWD2_ZAMORAK_<ITEM>` | Your boss log count for each unique: `CREST`, `WEAPON` (Nymora), `WEAPON_OFFHAND` (Avaryss) and `ESSENCE`. |

## Not counted

- **Wings of the Twin Furies** (a boss trophy, 1 in 500): it isn't on the
  collection log, so there's no count to read.
- **Dormant anima core pieces** (helm, body and legs): all four God Wars Dungeon
  2 bosses drop them, with one boss log count, so they aren't counted. They
  still take their share of the table, which is in the rates above.
- **Nylessa** and **Ava** (pets): pets aren't counted.

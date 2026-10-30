# General Graardor

How Boss RNG counts your General Graardor kills. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/General_Graardor)
(CC BY-NC-SA 3.0).

## Drop rates

Each kill has a 1 in 64 chance at Graardor's unique table, which then gives one
of its items at random. Only if that roll misses, there's a 1 in 512 roll for
the hilt. So a kill gives at most one of these, and the hilt is about 1 in 520
per kill (63/64 x 1/512). Hard mode has the same rates.

Graardor's table has six items, each about 1 in 384 per kill: the Bandos helmet,
chestplate, tassets, gloves, boots and warshield.

## How Boss RNG counts your kills

Kills shared with a group share their drops, and your kill count doesn't say who
you killed with. So Boss RNG assumes every kill was solo, and the "i" says so.
If you often kill in groups, the average player numbers are higher than they
should be for you, and your luck reads lower than it is.

Normal and hard mode kills have their own kill counts, and both are counted.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_GWD_GRAARDOR` | Your General Graardor kill count. |
| `BSLAY_KILLS_GWD_GRAARDOR_HARDMODE` | Your hard mode kill count. |
| `ITEMLOG_ITEM_GWD_BANDOS_<PIECE>` | Your boss log count for each unique: `HEAD`, `BODY`, `LEGS`, `HANDS`, `FEET`, `SHIELD` and `HILT`. |

## Not counted

- **General Graardor's head** (a boss trophy, 1 in 500): it isn't on the
  collection log, so there's no count to read.
- **Godsword shards:** they come from a table every God Wars boss shares, so
  their boss log counts aren't one boss's.
- **The Warpriest set:** it also drops from the bodyguards and other monsters of
  the same god, so its boss log counts aren't only from this boss.
- **The Glory of General Graardor** (lore) and **General Awwdor** (pet): lore
  books and pets aren't counted.

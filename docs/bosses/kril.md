# K'ril Tsutsaroth

How Boss RNG counts your K'ril Tsutsaroth kills. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/K%27ril_Tsutsaroth)
(CC BY-NC-SA 3.0).

## Drop rates

Each kill has a 1 in 64 chance at K'ril's unique table, which then gives one of
its items at random. Only if that roll misses, there's a 1 in 512 roll for the
hilt. So a kill gives at most one of these, and the hilt is about 1 in 520 per
kill (63/64 x 1/512). Hard mode has the same rates.

K'ril's table has eight items, each 1 in 512 per kill: the six Subjugation
pieces (hood, garb, gown, gloves, boots and ward), the Zamorakian spear and the
steam battlestaff.

The wiki doesn't say how K'ril's hilt is rolled. The generals share one drop
system, so Boss RNG assumes it works like Graardor's and Zilyana's, where the
wiki does say.

## How Boss RNG counts your kills

Kills shared with a group share their drops, and your kill count doesn't say who
you killed with. So Boss RNG assumes every kill was solo, and the "i" says so.
If you often kill in groups, the average player numbers are higher than they
should be for you, and your luck reads lower than it is.

Normal and hard mode kills have their own kill counts, and both are counted.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_GWD_KRIL` | Your K'ril Tsutsaroth kill count. |
| `BSLAY_KILLS_GWD_KRIL_HARDMODE` | Your hard mode kill count. |
| `ITEMLOG_ITEM_GWD_ZAMORAK_<PIECE>` | Your boss log count for each unique: `HEAD`, `BODY`, `LEGS`, `HANDS`, `FEET`, `SHIELD`, `SPEAR` and `HILT`. The steam battlestaff's is `ITEMLOG_ITEM_GWD_STEAM_BATTLESTAFF`. |

## Not counted

- **K'ril Tsutsaroth shoulder guard** (a boss trophy, 1 in 500): it isn't on the
  collection log, so there's no count to read.
- **Godsword shards:** they come from a table every God Wars boss shares, so
  their boss log counts aren't one boss's.
- **The Warpriest set:** it also drops from the bodyguards and other monsters of
  the same god, so its boss log counts aren't only from this boss.
- **Razulei's Tale** (lore) and **K'ril Tinyroth** (pet): lore books and pets
  aren't counted.

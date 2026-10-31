# The Magister

How Boss RNG counts your Magister kills. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/Magister) (CC BY-NC-SA 3.0), and the
changes from Jagex's
[Late-Game Rebalance](https://secure.runescape.com/m=news/late-game-rebalance-design-preview).

## Drop rates

The Magister is a solo fight. On top of its main drop, each kill rolls for two
uniques on their own:

| Unique | Now | From the Late-Game Rebalance |
|---|---|---|
| Phylactery | 1 in 18 | 1 in 10 |
| Gloves of passage | 1 in 500 | 1 in 128 |

Phylacteries are by far the most common unique, so most of the boss's headline
luck and dry streak comes from them; the gloves have their own row.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_MENAPHOS_SLAYER_BOSS` | Your Magister kill count. |
| `ITEMLOG_ITEM_MAGISTER_<ITEM>` | Your boss log count for each unique: `PHYLACTERY` and `HANDS` (gloves). |

## Not counted

- **The Minister** (pet): pets aren't counted.
- **The Magister's Journal #1 to #5:** lore pages.
- **Soul obelisk** (a boss trophy, 1 in 500): it isn't on the collection log, so
  there's no count to read.

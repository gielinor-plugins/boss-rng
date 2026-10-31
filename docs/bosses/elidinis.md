# The Gate of Elidinis

How Boss RNG counts your Gate of Elidinis kills. Drop rates are from Jagex's
[Gate of Elidinis Drop Rates](https://runescape.wiki/w/Update:Gate_of_Elidinis_Drop_Rates_-_This_Week_In_RuneScape)
(via the RuneScape Wiki, CC BY-NC-SA 3.0), and the changes from Jagex's
[Late-Game Rebalance](https://secure.runescape.com/m=news/late-game-rebalance-design-preview).

## Drop rates

Each kill (cleanse) rolls once for the rare table, then gives one of its four
uniques evenly, so a kill gives at most one:

| Unique | Now | From the Late-Game Rebalance |
|---|---|---|
| Runic attuner | 1 in 480 | 1 in 256 |
| Memory dowser | 1 in 480 | 1 in 256 |
| Scripture of Elidinis | 1 in 480 | 1 in 256 |
| Eclipsed Soul prayer codex | 1 in 480 | 1 in 256 |
| Latent Offering (its own roll) | 1 in 71 | 1 in 71 |

The rebalance gives each rare's new rate but not whether they still share one
roll; Boss RNG assumes they do. Latent Offerings are by far the most common
unique, so most of the boss's headline luck and dry streak comes from them.

## How Boss RNG counts your kills

Nearly every kill is solo, and your kill count doesn't say who you killed with,
so Boss RNG assumes every kill was solo, and the "i" says so.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_ELIDINIS_BOSS` | Your Gate of Elidinis kill count. |
| `ITEMLOG_ITEM_ELIDINIS_BOSS_<ITEM>` | Your boss log count for each unique: `SKILLING_OFFHAND_RUNECRAFTING` (attuner), `SKILLING_OFFHAND_DIVINATION` (dowser), `ELIDINIS_BOOK_UNLOCK_TOKEN` (scripture) and `OFFERINGS_AMULET_UPGRADE_MATERIAL` (Latent Offering). The codex's is `ITEMLOG_ITEM_COMBATV2_PRAYER_CODEX_ECLIPSED_SOUL`. |

## Not counted

- **Edie** (pet): pets aren't counted.
- **After The Flood:** lore.
- **The Gate of Elidinis** (a boss trophy): it isn't on the collection log, so
  there's no count to read.

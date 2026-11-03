# The Magister

Source: [RuneScape Wiki](https://runescape.wiki/w/Magister) (CC BY-NC-SA 3.0), checked 31 October 2026; changes from Jagex's [Late-Game Rebalance](https://secure.runescape.com/m=news/late-game-rebalance-design-preview).

## Drop rates

On top of its main drop, each kill rolls for two uniques on their own:

| Unique | Now | From the Late-Game Rebalance |
|---|---|---|
| Phylactery | 1 in 18 | 1 in 10 |
| Gloves of passage | 1 in 500 | 1 in 128 |

## How kills are counted

- A solo fight.
- Phylacteries, by far the most common unique, drive most of the headline luck
  and dry streak; the gloves have their own row.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_MENAPHOS_SLAYER_BOSS` | Kill count. |
| `ITEMLOG_ITEM_MAGISTER_<ITEM>` | Boss log count each: `PHYLACTERY`, `HANDS` (gloves). |

## Not counted

- **The Minister** (pet) and **The Magister's Journal #1 to #5** (lore): lore and pets aren't counted.
- **Soul obelisk** (boss trophy, 1 in 500): not on the collection log.

| Boss log item | Id |
|---|---|
| The Minister | 40670 |
| The Magister's Journal #1 | 40663 |
| The Magister's Journal #2 | 40664 |
| The Magister's Journal #3 | 40665 |
| The Magister's Journal #4 | 40666 |
| The Magister's Journal #5 | 40667 |

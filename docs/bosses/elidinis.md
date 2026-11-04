# The Gate of Elidinis

Source: Jagex's [Gate of Elidinis Drop Rates](https://runescape.wiki/w/Update:Gate_of_Elidinis_Drop_Rates_-_This_Week_In_RuneScape) via the RuneScape Wiki (CC BY-NC-SA 3.0), checked 31 October 2026; changes from Jagex's [Late-Game Rebalance](https://secure.runescape.com/m=news/late-game-rebalance-design-preview).

## Drop rates

Each kill (cleanse) rolls once for the rare table, which gives one of its four
uniques evenly, so a kill gives at most one. Latent Offering has its own roll.

| Unique | Now | From the Late-Game Rebalance |
|---|---|---|
| Runic attuner | 1 in 480 | 1 in 256 |
| Memory dowser | 1 in 480 | 1 in 256 |
| Scripture of Elidinis | 1 in 480 | 1 in 256 |
| Eclipsed Soul prayer codex | 1 in 480 | 1 in 256 |
| Latent Offering | 1 in 71 | 1 in 71 |

The rebalance doesn't say if the rares still share one roll; assumed yes.

## How kills are counted

- Nearly every kill is solo, and the kill count doesn't say who you killed with,
  so every kill is assumed solo (the Info tab says so).
- Latent Offerings, by far the most common unique, drive most of the headline
  luck and dry streak.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_ELIDINIS_BOSS` | Kill count. |
| `ITEMLOG_ITEM_ELIDINIS_BOSS_<ITEM>` | Collection log count each: `SKILLING_OFFHAND_RUNECRAFTING` (attuner), `SKILLING_OFFHAND_DIVINATION` (dowser), `ELIDINIS_BOOK_UNLOCK_TOKEN` (scripture), `OFFERINGS_AMULET_UPGRADE_MATERIAL` (Latent Offering). The codex's is `ITEMLOG_ITEM_COMBATV2_PRAYER_CODEX_ECLIPSED_SOUL`. |

## Not counted

- **Edie** (pet) and **After The Flood** (lore): lore and pets aren't counted.
- **The Gate of Elidinis** (boss trophy): not on the collection log.

| Collection log item | Id |
|---|---|
| After The Flood | 57533 |
| Edie | 57548 |

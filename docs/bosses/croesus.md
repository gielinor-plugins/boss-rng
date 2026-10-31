# Croesus

How Boss RNG counts your Croesus kills. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/Croesus)
(CC BY-NC-SA 3.0).

## Drop rates

Each loot roll has a 1 in 600 chance of a unique, one of nine evenly (1 in 5,400
each per roll): the five Cryptbloom pieces, the Sporehammer, the Foultorch, the
Spore sack and the Scripture of Bik. Every player gets their own rolls, by their
contribution:

| Contribution | Rolls | Unique rolls |
|---|---|---|
| 0 to 19 | 0 | 0 |
| 20 to 59 | 1 | 0 |
| 60 to 99 | 1 | 1 |
| 100 to 179 | 2 | 2 |
| 180 to 229 | 3 | 3 |
| 230 to 279 | 4 | 4 |
| 280 to 309 | 5 | 5 |
| 310 to 329 | 6 | 6 |
| 330 to 344 | 7 | 7 |
| 345 to 359 | 8 | 8 |
| 360 to 379 | 9 | 9 |
| 380 to 399 | 10 | 10 |
| 400 to 419 | 11 | 11 |
| 420 or more | 12 | 12 |

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_EGWD_BIK_BOSS` | Your Croesus kill count. |
| `EGWD_BIK_BOSS_PERSONAL_CONTRIBUTION` | Your contribution, rising through the fight. |
| `ITEMLOG_ITEM_EGWD_BIK_<ITEM>` | Your boss log count for each unique, for example `BOSS_MAGIC_HELM`, `BOSS_OFFHAND_MINING` (Sporehammer), `BOSS_SEED_STORAGE_UNIQUE` (Spore sack) and `BOOK_UNLOCK_TOKEN` (scripture). |

## How Boss RNG counts your kills

When your kill count goes up, Boss RNG takes your contribution, its last value
before the kill, and counts the kill at that many unique rolls. A kill where no
contribution was seen (for example, Boss RNG turned on just as the kill ended)
isn't counted.

Each kill is saved under its unique rolls, as day and count (see
[docs/data/saved_data.md](../data/saved_data.md)). For example, 30 kills at full
contribution and 2 at 345 to 359 on one day, then 5 at full contribution the
next:

```lua
croesus = {
    kills = { ["12 rolls"] = "20757:30,20758:5", ["8 rolls"] = "20757:2" },
    dryFrom = {},
    items = {},
}
```

## How this was tested

In game on 31 October 2026 by the developer, in a team of 3, logging each var
change with its game tick:
- `EGWD_BIK_BOSS_PERSONAL_CONTRIBUTION` (11 bits of `EGWD_BIK_BOSS_TEMP_1`) rose
  through the fight (188, 242, 311, 398) and read 466 in the kill count's tick:
  the contribution the game showed, so 12 rolls.
- It read 0 when the chest was opened about 2 minutes later, so it resets after
  the kill (exactly when wasn't seen). Taking its last value above 0 before the
  kill makes the reset's timing not matter.
- No unique dropped, so when a unique reaches the boss log wasn't seen. Loot can
  build up in the chest over kills, but rolls are known at each kill, so kills
  stay the unit.

## Not counted

- **Croesus' head** (a boss trophy, 1 in 500): it isn't on the collection log,
  so there's no count to read.
- **Little Sus** (pet): pets aren't counted.

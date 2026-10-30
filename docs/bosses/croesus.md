# Croesus

How Boss RNG counts your Croesus kills. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/Croesus)
(CC BY-NC-SA 3.0).

## Drop rates

Each loot roll has a 1 in 600 chance of a unique, one of nine evenly (1 in 5,400
each per roll): the five Cryptbloom pieces, the Sporehammer, the Foultorch, the
Spore sack and the Scripture of Bik. Your number of rolls goes up with your
contribution, to 12 at full contribution. Every player gets their own rolls.

## How Boss RNG counts your kills

Your kill count doesn't say how much you contributed, so Boss RNG assumes full
contribution (12 rolls) on every kill, and the "i" says so. If you often
contribute less, your luck reads lower than it is.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_EGWD_BIK_BOSS` | Your Croesus kill count. |
| `ITEMLOG_ITEM_EGWD_BIK_<ITEM>` | Your boss log count for each unique, for example `BOSS_MAGIC_HELM`, `BOSS_OFFHAND_MINING` (Sporehammer), `BOSS_SEED_STORAGE_UNIQUE` (Spore sack) and `BOOK_UNLOCK_TOKEN` (scripture). |

## Not counted

- **Croesus' head** (a boss trophy, 1 in 500): it isn't on the collection log,
  so there's no count to read.
- **Little Sus** (pet): pets aren't counted.

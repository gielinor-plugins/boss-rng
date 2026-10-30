# Barrows: Rise of the Six

How Boss RNG counts your Rise of the Six kills. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/The_Barrows:_Rise_of_the_Six)
(CC BY-NC-SA 3.0).

## Drop rates

Each chest has a 1 in 80 chance of a kiteshield, one of three evenly: the
Malevolent, Merciless or Vengeful kiteshield, 1 in 240 each. Every player in the
team gets their own chest and rolls.

## How Boss RNG counts your kills

Your kill count goes up at the kill, whether or not you loot the chest. So Boss
RNG assumes every chest was looted, and the "i" says so.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_BARROWSROTS` | Your Rise of the Six kill count. |
| `ITEMLOG_ITEM_ROTS_SHIELD_<STYLE>` | Your boss log count for each kiteshield: `MAGIC` (Malevolent), `MELEE` (Merciless) and `RANGED` (Vengeful). |

## Not counted

- **Rise of the Six chest** (a boss trophy, 1 in 500): it isn't on the
  collection log, so there's no count to read.
- **Malevolent energy:** every chest gives it, so it's not a rare drop.
- **The brothers' bobbleheads:** cosmetic unlocks.

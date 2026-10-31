# Kerapac

How Boss RNG counts your Kerapac kills. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/Kerapac,_the_bound)
(CC BY-NC-SA 3.0).

## Drop rates

Each kill gives three loot piles, and each pile rolls for a unique:

- **Normal mode:** 1 in 256 per pile, for Kerapac's wrist wraps, the Greater
  Concentrated Blast codex or the Scripture of Jas, evenly.
- **Hard mode:** 1 in 400 per pile for a Fractured Staff of Armadyl piece, and
  if that misses, 1 in 180 for one of the same three.

The staff pieces drop in order (shaft, gem, then symbol), so Boss RNG shows them
as one row.

## How Boss RNG counts your kills

Who gets the piles depends on your team. Solo, you get all three. In a duo, the
top damager gets two and the other player one, so you average one and a half. In
a trio, each player gets one.

Your kill count doesn't say how many piles you got, and counting them as they
land isn't reliable. So for now Boss RNG uses your average loot piles per kill
for each mode, set on the settings page (Plugin Hub, Manage, Boss RNG's gear),
from 1 to 3. It starts at 3, as if solo, and applies to all your kills in that
mode. The "i" says what it's set to.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_EGWD_JAS_BOSS` | Your normal mode kill count. |
| `BSLAY_KILLS_EGWD_JAS_BOSS_HARDMODE` | Your hard mode kill count. |
| `ITEMLOG_ITEM_EGWD_JAS_<ITEM>` | Your boss log count for each unique: `BOSS_MAGIC_WEAPON_TOP`, `_MIDDLE` and `_BOTTOM` (staff pieces), `BOSS_MAGIC_GLOVES` (wraps) and `BOOK_UNLOCK_TOKEN` (scripture). The codex's is `ITEMLOG_ITEM_COMBATV2_ABILITY_CODEX_MAGIC_GREATER_CONCENTRATED_BLAST`. |

## Not counted

- **Kerapac's time-torn Staff of Armadyl** (a boss trophy, 1 in 500): it isn't
  on the collection log, so there's no count to read.
- **Kerry** (pet): pets aren't counted.

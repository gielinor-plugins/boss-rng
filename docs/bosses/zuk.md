# TzKal-Zuk

How Boss RNG counts your TzKal-Zuk kills. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/TzKal-Zuk)
(CC BY-NC-SA 3.0).

## Drop rates

TzKal-Zuk is a solo fight.

- **Normal mode:** the Magma Tempest codex and the Scripture of Ful are 1 in 100
  each per kill.
- **Hard mode:** they're 1 in 50 each, and Ek-ZekKil pieces drop too: 1 in 30
  for any piece, or 1 in 27 in a run without checkpoints. The pieces drop in
  order (a random one, then the other two), so Boss RNG shows them as one row.

## How Boss RNG counts your kills

Every run without checkpoints, in either mode, gives an Igneous stone. So your
stones say how many of your runs had no checkpoints, and Boss RNG uses their
share of your kills for the hard mode piece rate.

The stones can't say which mode those runs were in. When that matters (you've
used checkpoints in some runs, and the stones could come from either mode), Boss
RNG assumes you used checkpoints as often in both modes, and the "i" says so.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_EGWD_FUL_BOSS` | Your normal mode kill count. |
| `BSLAY_KILLS_EGWD_FUL_BOSS_HARDMODE` | Your hard mode kill count. |
| `ITEMLOG_ITEM_EGWD_FUL_BOSS_INFERNAL_STONE` | Your Igneous stones: runs without checkpoints. |
| `ITEMLOG_ITEM_EGWD_FUL_<ITEM>` | Your boss log count for each unique: `BOSS_MELEE_WEAPON_TOP`, `_MIDDLE` and `_BOTTOM` (Ek-ZekKil pieces) and `BOOK_UNLOCK_TOKEN` (scripture). The codex's is `ITEMLOG_ITEM_COMBATV2_ABILITY_CODEX_MAGIC_MAGMA_TEMPEST`. |

## Not counted

- **TzKal-Zuk's helmet** (a boss trophy, 1 in 25): it isn't on the collection
  log, so there's no count to read.
- **Igneous stone:** a reward for a run without checkpoints, not a drop.
- **Little Zuk** (pet): pets aren't counted.

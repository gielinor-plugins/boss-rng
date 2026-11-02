# TzKal-Zuk

Source: [RuneScape Wiki](https://runescape.wiki/w/TzKal-Zuk) (CC BY-NC-SA 3.0), checked 28 October 2026.

## Drop rates

| Item | Normal | Hard mode |
|---|---|---|
| Magma Tempest codex | 1 in 100 | 1 in 50 |
| Scripture of Ful | 1 in 100 | 1 in 50 |
| Any Ek-ZekKil piece | none | 1 in 30; 1 in 27 in a run without checkpoints |

Pieces drop in order (a random one, then the other two), so they're one row.

## How kills are counted

- A solo fight.
- Every run without checkpoints, in either mode, gives an Igneous stone, so your
  stones' share of your kills sets the hard mode piece rate.
- Stones don't say the mode. When that matters (some runs used checkpoints),
  checkpoints are assumed used as often in both modes (the Info tab says so).

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_EGWD_FUL_BOSS` | Normal mode kill count. |
| `BSLAY_KILLS_EGWD_FUL_BOSS_HARDMODE` | Hard mode kill count. |
| `ITEMLOG_ITEM_EGWD_FUL_BOSS_INFERNAL_STONE` | Igneous stones: runs without checkpoints. |
| `ITEMLOG_ITEM_EGWD_FUL_<ITEM>` | Boss log count each: `BOSS_MELEE_WEAPON_TOP`, `_MIDDLE`, `_BOTTOM` (Ek-ZekKil pieces), `BOOK_UNLOCK_TOKEN` (scripture). The codex's is `ITEMLOG_ITEM_COMBATV2_ABILITY_CODEX_MAGIC_MAGMA_TEMPEST`. |

## Not counted

- **TzKal-Zuk's helmet** (boss trophy, 1 in 25): not on the collection log.
- **Igneous stone:** a reward for a run without checkpoints, not a drop.
- **Little Zuk** (pet): pets aren't counted.

# TzKal-Zuk

Source: [RuneScape Wiki](https://runescape.wiki/w/TzKal-Zuk) (CC BY-NC-SA 3.0), checked 2 November 2026.

## Drop rates

| Item | Normal | Hard mode |
|---|---|---|
| Magma Tempest codex | 1 in 100 | 1 in 50 |
| Scripture of Ful | 1 in 100 | 1 in 50 |
| Any Ek-ZekKil piece | none | 1 in 30; 1 in 27 in a run without checkpoints |

Pieces drop in order (a random one, then the other two), so they're one row.

## How kills are counted

- A solo fight.
- A run without checkpoints, in either mode, gives an Igneous stone in the kill's
  tick. Each hard mode kill is saved as `h` (no checkpoints) if the stone's log
  count rose in its tick, or `hc` (checkpoints) if not. Normal mode is `n`: its
  rates don't depend on checkpoints.
- An overcharged pontifex shadow ring raises every unique 2%
  ([Shared assumptions](README.md#shared-assumptions)).
- The collection log counts at most 250 stones. After that a kill can't show one, so
  it counts as `h`: those players have mastered the fight. The Info tab says so.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_EGWD_FUL_BOSS` | Normal mode kill count. |
| `BSLAY_KILLS_EGWD_FUL_BOSS_HARDMODE` | Hard mode kill count. |
| `ITEMLOG_ITEM_EGWD_FUL_BOSS_INFERNAL_STONE` | Igneous stones: a rise in a hard mode kill's tick means no checkpoints. |
| `EGWD_PONTIFEX_RING_PASSIVE_UNLOCKED` | 1 once the pontifex shadow ring is overcharged. |
| `ITEMLOG_ITEM_EGWD_FUL_<ITEM>` | Collection log count each: `BOSS_MELEE_WEAPON_TOP`, `_MIDDLE`, `_BOTTOM` (Ek-ZekKil pieces), `BOOK_UNLOCK_TOKEN` (scripture). The codex's is `ITEMLOG_ITEM_COMBATV2_ABILITY_CODEX_MAGIC_MAGMA_TEMPEST`. |

## Tests

In game on 2 November 2026 by the developer, logging each change to the kill
counts, the collection log counts and the encounter progress, and the reward chest
updating, with the game tick.

| Test | Seen |
|---|---|
| Hard mode, no checkpoints, looted after the kill | The stone's log count (108 to 109) and the hard mode kill count (100 to 101) rose in the same tick. The chest updated through the fight and again after; looting changed no count. |

## Not counted

- **TzKal-Zuk's helmet** (boss trophy, 1 in 25): not on the collection log.
- **Igneous stone:** a reward for a run without checkpoints, not a drop.
- **Little Zuk** (pet): pets aren't counted.

| Collection log item | Id |
|---|---|
| Igneous stone | 52500 |
| Little Zuk | 52546 |

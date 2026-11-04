# The Shadow Reef

Source: [RuneScape Wiki](https://runescape.wiki/w/The_Ambassador) (CC BY-NC-SA 3.0), checked 31 October 2026.

## Drop rates

Only the Ambassador's Eldritch crossbow pieces are tracked. Each kill rolls for a
piece, per player, by team size:

| Players | Any piece |
|---|---|
| Solo | 1 in 55 |
| Duo | 1 in 111 |
| Trio | 1 in 166 |

The first piece is random and each next one is one you don't have yet, so the
limb, mechanism and stock are one row.

## How kills are counted

- The Ambassador has solo and group kill counts. A group kill counts at the
  team size in the dungeon at the kill.
- Everyone in the dungeon counts, not just the fight (tested 31 October 2026).
  A teammate who sits out a boss is assumed to still count toward its drop rate
  (the Info tab says so).
- The Crassian Leviathan and Taraket aren't counted.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_DUNGEON_ULTHVEN3_SOLO` | Solo Ambassador kill count. |
| `BSLAY_KILLS_DUNGEON_ULTHVEN3` | Group Ambassador kill count. |
| `DUNGEON_PLAYERS_AT_BOSS_KILL` | Players in the dungeon at the kill, read at each group kill. |
| `ITEMLOG_ITEM_DUNGEON_2H_RANGED_<PIECE>` | Collection log count per piece: `LIMB`, `MECHANISM`, `STOCK`. |

## Not counted

- **Black stone heart:** a common drop.
- **The Last Offering** and **Kranon's Ancient Journal** (lore) and **Ambi**
  (pet): lore and pets aren't counted.
- **Head of the Ambassador** (boss trophy, 1 in 50): not on the collection log.

| Collection log item | Id |
|---|---|
| Black stone heart | 47506 |
| The Last Offering | 47468 |
| Kranon's Ancient Journal | 47469 |
| Ambi | 47537 |

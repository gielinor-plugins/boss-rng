# The Shadow Reef

How Boss RNG counts your Shadow Reef kills. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/The_Ambassador) (CC BY-NC-SA 3.0).

## Drop rates

Only the Ambassador's Eldritch crossbow pieces are tracked. Each kill rolls for
a piece, per player, by the size of your team:

| Players | Any piece |
|---|---|
| Solo | 1 in 55 |
| Duo | 1 in 111 |
| Trio | 1 in 166 |

Your first piece is random, and each next one is a piece you don't have yet, so
Boss RNG shows the limb, mechanism and stock as one row.

## How Boss RNG counts your kills

The game counts the Ambassador's solo and group kills apart. When your group
kill count goes up, Boss RNG reads how many players were in the dungeon and
counts the kill at that team size. The Crassian Leviathan and Taraket aren't
counted.

The game reads everyone in the dungeon, not just those in the fight. A teammate
who sits out a boss but stays in the dungeon still counts toward the team, so
that kill counts at a lower rate than you had; the "i" says so.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_DUNGEON_ULTHVEN3_SOLO` | Your solo Ambassador kill count. |
| `BSLAY_KILLS_DUNGEON_ULTHVEN3` | Your group Ambassador kill count. |
| `DUNGEON_PLAYERS_AT_BOSS_KILL` | The players in the dungeon at the kill, read at each group kill. |
| `ITEMLOG_ITEM_DUNGEON_2H_RANGED_<PIECE>` | Your boss log count for each piece: `LIMB`, `MECHANISM` and `STOCK`. |

## Not counted

- **Black stone heart:** a common drop.
- **The Last Offering** and **Kranon's Ancient Journal:** lore.
- **Ambi** (pet): pets aren't counted.
- **Head of the Ambassador** (a boss trophy, 1 in 50): it isn't on the
  collection log, so there's no count to read.

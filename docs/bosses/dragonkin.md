# Dragonkin Laboratory

Source: [RuneScape Wiki](https://runescape.wiki/w/Dragonkin_Laboratory) (CC BY-NC-SA 3.0), checked 28 October 2026. Astellarn, Verak Lith and the Black stone dragon are one entry.

## Drop rates

Each boss drops its own codex to each player (Astellarn: Flurry, Verak Lith:
Fury, Black stone dragon: Barge). Teams are at most three.

| Players | Each codex |
|---|---|
| Solo | 1 in 83 |
| Duo | 1 in 166 |
| Trio | 1 in 250 |

## How kills are counted

- Each boss has solo and group kill counts. Solo kills count at 1 in 83.
- A group kill counts at the rate for the players in the dungeon at the kill
  (solo if your partner left). If that can't be read, the kill isn't counted.
- Everyone in the dungeon counts, not just the fight (tested 31 October 2026).
  A teammate who sits out a boss is assumed to still count toward its drop rate
  (the Info tab says so).

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_DUNGEON_DRAGONFORT<N>_SOLO` | Solo kill count per boss: 1 Astellarn, 2 Verak Lith, 3 the Black stone dragon. |
| `BSLAY_KILLS_DUNGEON_DRAGONFORT<N>` | Group kill count per boss. |
| `DUNGEON_PLAYERS_AT_BOSS_KILL` | Players in the dungeon at the kill, read at each group kill. |
| `ITEMLOG_ITEM_DUNGEON_MELEE_CODEX_<NAME>` | Collection log count per codex: `FLURRY`, `FURY`, `BARGE`. |

## Not counted

- **Astellarn's head**, **Verak Lith's head** and **Black Stone Dragon's head**
  (boss trophies, 1 in 50 each from their boss): not on the collection log.
- **Draconic energy:** a common drop.
- **Redacted Dragonkin Research** and **Diary of an Overzealous Gnome** (lore)
  and **Bisdi** (pet): lore and pets aren't counted.

| Collection log item | Id |
|---|---|
| Redacted Dragonkin Research | 43373 |
| Diary of an Overzealous Gnome | 43374 |
| Draconic energy | 43165 |
| Bisdi | 47548 |

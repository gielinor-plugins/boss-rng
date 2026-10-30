# Dragonkin Laboratory

How Boss RNG counts your Dragonkin Laboratory kills (Astellarn, Verak Lith and the Black stone dragon, as one entry). Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/Dragonkin_Laboratory)
(CC BY-NC-SA 3.0).

## Drop rates

Each boss drops its own codex, to each player: Astellarn the Flurry codex, Verak
Lith the Fury codex and the Black stone dragon the Barge codex. The rate depends
on how many players are there: 1 in 83 solo, 1 in 166 duo and 1 in 250 trio.
Teams are at most three.

## How Boss RNG counts your kills

Each boss has a solo kill count and a group kill count.

- **Solo kills** count at 1 in 83.
- **Group kills:** when a group kill count goes up, Boss RNG reads how many
  players were in the room at the kill, so each kill counts at the right rate
  exactly. A group kill where your partner never came in counts at the solo
  rate. If the player count can't be read at a kill, that kill isn't counted.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_DUNGEON_DRAGONFORT<N>_SOLO` | Your solo kill count for each boss: 1 Astellarn, 2 Verak Lith, 3 the Black stone dragon. |
| `BSLAY_KILLS_DUNGEON_DRAGONFORT<N>` | Your group kill count for each boss. |
| `DUNGEON_PLAYERS_AT_BOSS_KILL` | How many players were in the room at the kill. Read at each group kill. |
| `ITEMLOG_ITEM_DUNGEON_MELEE_CODEX_<NAME>` | Your boss log count for each codex: `FLURRY`, `FURY` and `BARGE`. |

## Not counted

- **Astellarn's head**, **Verak Lith's head** and **Black Stone Dragon's head**
  (boss trophies, 1 in 50 each from their boss): they aren't on the collection
  log, so there's no count to read.
- **Draconic energy:** a common drop.
- **Redacted Dragonkin Research** and **Diary of an Overzealous Gnome** (lore)
  and **Bisdi** (pet): lore books and pets aren't counted.

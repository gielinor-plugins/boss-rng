# Barrows brothers

How Boss RNG counts your Barrows chests, and what we learned from testing in
game. Drop rates are from the [RuneScape Wiki](https://runescape.wiki/w/Barrows)
(CC BY-NC-SA 3.0).

## How a run works

- You kill some of the six brothers (Ahrim, Dharok, Guthan, Karil, Torag and
  Verac), and you can also kill Akrisae and Linza. Then you loot the chest.
- Your first search of the chest brings out the brother in the tunnel. You can
  kill him first, or loot the chest without killing him.
- Your Barrows kill count only goes up for a chest with **6 or more brothers**.
  Akrisae counts toward the 6, Linza doesn't. The wiki says all six original
  brothers are needed, but in our tests:
  - 3 brothers: no kill count
  - 5 brothers and Linza: no kill count
  - 5 brothers and Akrisae: +1 kill count
- A chest with fewer than 6 brothers is a **partial chest**. It can still drop
  pieces, and those count in your boss log.

## Drop rates

With n brothers killed (Linza not counted), the chest makes min(n + 1, 7) rolls.
Each roll has a 1 in max(450 - 58n, 73) chance of a Barrows piece. A piece comes
from one of the brothers you killed, picked evenly, then one of their items,
picked evenly. Linza, if you killed her, adds one roll at 1 in 96 for one of her
five items. Before the 20 July 2026 update, that roll was 1 in 192.

Every chest also has a 1 in 480 chance of the **Amulet of the forsaken**, from
Jagex's [Late-Game Rebalance design preview](https://secure.runescape.com/m=news/late-game-rebalance-design-preview)
(1 in 240 from the late November 2026 update). It doesn't say whether partial
chests can give it, so Boss RNG assumes they can, and the "i" says so.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_BARROWS` | Your Barrows kill count. |
| `ITEMLOG_ITEM_BARROWS_<BROTHER>_<PIECE>` | Your boss log count for each piece. Linza's use `SISTER`. |
| `BARROWS_KILLED_AHRIM` to `BARROWS_KILLED_VERAC` | Whether each of the six brothers is dead this run. |
| `BARROWS_KILLED_COUNT` | How many brothers are dead this run, Akrisae and Linza included. |
| `SISTER_KILLED_LINZA` | Whether Linza is dead this run. |
| `BARROWS`, bit 0x4000000 | Turns on when you loot the chest, and off when your next run starts. The game doesn't name this bit. |

There's no var for Akrisae on his own, so Boss RNG works him out: the brother
count, less the six brothers' flags, less Linza.

`BARROWS_CHEST_OPEN` turns on at your first search, before the tunnel brother
is dead, so Boss RNG doesn't use it.

## How Boss RNG counts your chests

When you loot, Boss RNG reads which brothers you killed and counts the chest
with exactly their drop chances. Partial chests count too, and show after your
tracked kill count ("12 kills (+2 partial)").

## Dry streaks

A chest can only give pieces from brothers you killed that run. So an item's
dry count only counts chests where that brother was killed. For example, if you
got Ahrim's robe top and then looted two chests without Ahrim, the robe top
still shows 0 dry: neither chest could have given it. The headline's dry streak
counts every chest since your last unique.

## Not counted

- **Corruption sigil:** it only drops if you have a dragon defender or better,
  which Boss RNG doesn't track.
- **Barrows chest** (a boss trophy, 1 in 500): it isn't on the collection log,
  so there's no count to read.

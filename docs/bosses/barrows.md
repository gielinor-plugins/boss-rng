# Barrows Brothers

Source: [RuneScape Wiki](https://runescape.wiki/w/Barrows) (CC BY-NC-SA 3.0), checked 28 October 2026; amulet from Jagex's [Late-Game Rebalance design preview](https://secure.runescape.com/m=news/late-game-rebalance-design-preview).

## Drop rates

With n brothers killed (Linza not counted), the chest makes min(n + 1, 7) rolls.
A hit picks a killed brother evenly, then one of his items evenly.

| Roll | Rate |
|---|---|
| Each brother roll | 1 in max(450 - 58n, 73) |
| Linza (if killed), one of her five items | 1 in 96 (1 in 192 before the 20 July 2026 update) |
| Amulet of the forsaken, every chest | 1 in 480 (1 in 240 from the late November 2026 update) |

The preview doesn't say if partial chests can give the amulet; assumed yes (the
Info tab says so).

## How kills are counted

- A run: kill some of Ahrim, Dharok, Guthan, Karil, Torag and Verac, optionally
  Akrisae and Linza, then loot. The first search brings out the tunnel brother;
  you can loot without killing him.
- Each looted chest counts with exactly the chances of that run's brothers.
- The kill count only rises for **6+ brothers**, Akrisae counting and Linza not
  (see Tests). Fewer makes a **partial chest**: it can still drop pieces (they
  count in the boss log), is counted, and shows after the kill count ("12 kills
  (+2 partial)").
- Akrisae has no var: he's the brother count less the six brothers' flags, less
  Linza.
- **Dry streaks:** an item's dry count only counts chests where its brother died.
  After Ahrim's robe top and two chests without Ahrim, it still shows 0 dry. The
  headline dry streak counts every chest since your last unique.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_BARROWS` | Kill count. |
| `ITEMLOG_ITEM_BARROWS_<BROTHER>_<PIECE>` | Boss log count each piece; Linza's use `SISTER`. |
| `BARROWS_KILLED_AHRIM` to `BARROWS_KILLED_VERAC` | Each of the six brothers dead this run. |
| `BARROWS_KILLED_COUNT` | Brothers dead this run, Akrisae and Linza included. |
| `SISTER_KILLED_LINZA` | Linza dead this run. |
| `BARROWS`, bit 0x4000000 | On when you loot, off when the next run starts. Unnamed by the game. |

Not used: `BARROWS_CHEST_OPEN`, which turns on at the first search, before the
tunnel brother dies.

## Tests

The wiki says all six original brothers are needed for a kill count; in game:

| Killed | Kill count |
|---|---|
| 3 brothers | none |
| 5 brothers and Linza | none |
| 5 brothers and Akrisae | +1 |

## Not counted

- **Corruption sigil:** needs a dragon defender or better, which isn't tracked.
- **Barrows chest** (boss trophy, 1 in 500): not on the collection log.

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

## How chests are saved

Each looted chest is saved under a mode key for the brothers killed that run, so
its rates can be rebuilt from the key ([saved data](../data/saved-data.md)). At
the loot, each brother killed sets his bit:

| Brother | Bit | How it's known |
|---|---|---|
| Ahrim | `0x1` | `BARROWS_KILLED_AHRIM` is 1 |
| Dharok | `0x2` | `BARROWS_KILLED_DHAROK` is 1 |
| Guthan | `0x4` | `BARROWS_KILLED_GUTHAN` is 1 |
| Karil | `0x8` | `BARROWS_KILLED_KARIL` is 1 |
| Torag | `0x10` | `BARROWS_KILLED_TORAG` is 1 |
| Verac | `0x20` | `BARROWS_KILLED_VERAC` is 1 |
| Akrisae | `0x40` | `BARROWS_KILLED_COUNT` is more than the six flags plus Linza |
| Linza | `0x80` | `SISTER_KILLED_LINZA` is 1 |

The key is `c` and the bits in lowercase hex, without leading zeros: `c3f` is the
six originals, `c7f` adds Akrisae, `cbf` adds Linza instead, `cff` is all eight.
Read back, the set bits give the brothers sharing the equipment rolls (the first
seven) and Linza's own roll. The chest is in the kill count with 6 or more of
those seven, and a partial chest otherwise. The bits follow the brothers' order in
`src/bosses/barrows.lua`, so that order must never change.

The key saves who died, not whether the chest counted, so a change to the kill
count rule needs no saved data change. If Akrisae stopped counting toward the 6,
the rule would depend on the chest's day (before the change, he counts), and
each saved key gives the same brothers either way. Today a chest's kill count is
set from its key alone, so the rule would need each kill's day too
(`stats.lua` already has it for rates).

For example, two runs on day 20757:

- Ahrim, Dharok, Karil, Torag, Verac and Akrisae (no Guthan): `0x7b`, so `c7b`.
  Six brothers, so it counts as a kill, with 7 brother rolls and the amulet roll.
- Ahrim, Dharok and Linza: `0x83`, so `c83`. Two brothers, so a partial chest,
  with 3 brother rolls, Linza's roll and the amulet roll.

```lua
barrows = {
    kills = { c7b = "20757:1", c83 = "20757:1" },
    dryFrom = {},
    items = {},
}
```

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

| Boss log item | Id |
|---|---|
| Corruption sigil | 36156 |

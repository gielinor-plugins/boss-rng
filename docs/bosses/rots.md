# Barrows: Rise of the Six

Source: [RuneScape Wiki](https://runescape.wiki/w/The_Barrows:_Rise_of_the_Six) (CC BY-NC-SA 3.0), checked 28 October 2026.

## Drop rates

Every player gets their own chest and rolls. Each chest has a 1 in 80 chance of
a kiteshield, one of three evenly: Malevolent, Merciless or Vengeful, 1 in 240
each.

## How kills are counted

- The kill count rises at the kill, looted or not, so every chest is assumed
  looted (the "i" says so).

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_BARROWSROTS` | Kill count. |
| `ITEMLOG_ITEM_ROTS_SHIELD_<STYLE>` | Boss log count per kiteshield: `MAGIC` (Malevolent), `MELEE` (Merciless), `RANGED` (Vengeful). |

## Not counted

- **Rise of the Six chest** (boss trophy, 1 in 500): not on the collection log.
- **Malevolent energy:** every chest gives it, so it's not a rare drop.
- **The brothers' bobbleheads:** cosmetic unlocks.

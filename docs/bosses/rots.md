# Barrows: Rise of the Six

Source: [RuneScape Wiki](https://runescape.wiki/w/The_Barrows:_Rise_of_the_Six) (CC BY-NC-SA 3.0), checked 28 October 2026.

## Drop rates

Every player gets their own chest and rolls. Each chest has a 1 in 80 chance of
a kiteshield, one of three evenly: Malevolent, Merciless or Vengeful, 1 in 240
each.

## How kills are counted

- The kill count rises at the kill, looted or not, so every chest is assumed
  looted (the Info tab says so).

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_BARROWSROTS` | Kill count. |
| `ITEMLOG_ITEM_ROTS_SHIELD_<STYLE>` | Boss log count per kiteshield: `MAGIC` (Malevolent), `MELEE` (Merciless), `RANGED` (Vengeful). |

## Tests

In game on 2 November 2026 by the developer, logging the kill count, boss log
counts and var changes with their game tick.

| Test | Seen |
|---|---|
| Failed kill, teleported out | Kill count unchanged. |
| Kill in a duo, looted, escaped | Kill count 132 to 133 at the kill. Malevolent energy's log count 202 to 204 about 72 seconds later. |
| Kill, looted, escaped | Kill count up at the kill. Energy's log count 204 to 205 about 69 seconds later. |
| Kill, not looted, escaped | Kill count up at the kill. Energy's log count unchanged. |
| Kill, looted 15 seconds later, escaped | At the loot the backpack changed, but no var that hadn't already changed since the kill, except a combat var that also changes without looting. `REWARD_CHEST` unchanged. Energy's log count 205 to 207 at the escape. |
| Kill, not looted, escaped | Kill count up at the kill. Energy's log count unchanged. |

Conclusions:
- No var marks a loot, so chests looted can't be counted: every chest stays
  assumed looted.
- Energy's log count rises only after looting, at the escape rather than the
  loot.
- No unique dropped, so when one reaches the boss log wasn't seen.

## Not counted

- **Rise of the Six chest** (boss trophy, 1 in 500): not on the collection log.
- **Malevolent energy:** every chest gives it, so it's not a rare drop.
- **The brothers' bobbleheads:** cosmetic unlocks.

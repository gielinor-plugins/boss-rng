# Nex

Source: [RuneScape Wiki](https://runescape.wiki/w/Nex) (CC BY-NC-SA 3.0), checked 27 October 2026.

## Drop rates

Each kill has a 6 in 128 roll at the unique table. Its 18 items (Torva, Pernix
and Virtus sets with gloves and boots, Virtus book and wand, Zaryte bow) are each
listed at 1 in 384, which is 6/128 split evenly, so it's assumed to pick one at
random.

## How kills are counted

- Assumed solo (the Info tab says so): the kill count doesn't say who you killed
  with, and group kills share drops, so group killers' luck reads low.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_GWD_NEX` | Kill count. |
| `ITEMLOG_ITEM_GWD_NEX_<PIECE>` | Boss log count each, by piece and style, e.g. `HEAD_MELEE` (Torva full helm), `BODY_RANGED` (Pernix body), `FEET_MAGIC` (Virtus boots), then `BOOK`, `WAND`, `BOW`. |

## Not counted

- **Nex's wings** (boss trophy, 1 in 500): not on the collection log.
- **Ancient emblem:** only drops to players carrying a tier 70 or better
  defender, so not every kill can drop it.
- **Nex's Followers** (lore) and **Nexterminator** (pet): lore and pets aren't counted.

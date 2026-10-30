# Nex

How Boss RNG counts your Nex kills. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/Nex)
(CC BY-NC-SA 3.0).

## Drop rates

Each kill has a 6 in 128 chance at Nex's unique table. Its 18 items (the Torva,
Pernix and Virtus sets with their gloves and boots, the Virtus book and wand,
and the Zaryte bow) are each listed at 1 in 384 per kill. That's 6/128 split
evenly over the 18, so Boss RNG takes the table to pick one at random.

## How Boss RNG counts your kills

Kills shared with a group share their drops, and your kill count doesn't say who
you killed with. So Boss RNG assumes every kill was solo, and the "i" says so.
If you often kill in groups, the average player numbers are higher than they
should be for you, and your luck reads lower than it is.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_GWD_NEX` | Your Nex kill count. |
| `ITEMLOG_ITEM_GWD_NEX_<PIECE>` | Your boss log count for each unique, by piece and style: for example `HEAD_MELEE` (Torva full helm), `BODY_RANGED` (Pernix body), `FEET_MAGIC` (Virtus boots), then `BOOK`, `WAND` and `BOW`. |

## Not counted

- **Nex's wings** (a boss trophy, 1 in 500): it isn't on the collection log, so
  there's no count to read.
- **Ancient emblem:** it only drops to players carrying a tier 70 or better
  defender, so not every kill can drop it.
- **Nex's Followers** (lore) and **Nexterminator** (pet): lore books and pets
  aren't counted.

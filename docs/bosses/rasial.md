# Rasial, the First Necromancer

How Boss RNG counts your Rasial kills. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/Rasial,_the_First_Necromancer)
(CC BY-NC-SA 3.0).

## Drop rates

Rasial is a solo fight. Each kill makes two rolls at the same time:

- a 1 in 320 weapon roll, for the Omni guard or the Soulbound lantern
- a 1 in 128 armor roll, for one of the five First Necromancer pieces

So every unique is 1 in 640 per kill, and a kill can rarely give two.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_RASIAL_BOSS` | Your Rasial kill count. |
| `ITEMLOG_ITEM_NECRO_RASIAL_<PIECE>_T95` | Your boss log count for each unique: `ARMGUARD` (Omni guard), `LANTERN`, `HEAD`, `BODY`, `LEGS`, `HANDS` and `FEET`. |

## Not counted

- **Miso:** pets aren't counted.
- **Rasial's crown** (a boss trophy, 1 in 500): it isn't on the collection log,
  so there's no count to read.

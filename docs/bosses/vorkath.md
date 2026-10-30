# Zemouregal & Vorkath

How Boss RNG counts your Zemouregal & Vorkath chests. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/Zemouregal_%26_Vorkath) (CC BY-NC-SA
3.0), which gives Jagex's published rates.

## Drop rates

Every player who did damage gets their own chest, so your team doesn't change
your chances. Each chest rolls once for a rare, in its first slot:

- **Normal mode:** Vorkath's spike 1 in 45 (4 to 7 of them), or the Invoke Lord
  of Bones incantation codex 1 in 249.
- **Hard mode:** Vorkath's spike 1 in 15 (6 to 9), the codex 1 in 150, or
  Vorkath's scale 1 in 150.

## How Boss RNG counts your chests

You can keep chests and open them whenever you like, so Boss RNG counts
**chests opened**, not kills. When you open one, the chest leaves your backpack
as the reward window opens; Boss RNG counts it for its mode (the chest says
normal or hard), and any rare in it at the same moment. Banking or claiming a
chest doesn't count.

So saving chests never makes you look unlucky, and a chest opened while Boss
RNG is off is simply not tracked, along with whatever it gave.

Spikes drop in stacks, and your boss log counts spikes, not drops. Boss RNG
counts each stack as one drop for luck, and shows your boss log's spike count on
its own ("Boss log: 400 kills · 6 uniques · 184 spikes").

Spikes are the most common rare, so most of the boss's headline luck and dry
streak comes from them. Each item's row shows its own luck and dry streak, so
check the codex and scale rows for those.

## What Boss RNG reads

| What | What it holds |
|---|---|
| `BSLAY_KILLS_FORT_BOSS_ZEMO_VORKATH` | Your normal mode kill count. |
| `BSLAY_KILLS_FORT_BOSS_ZEMO_VORKATH_HARD` | Your hard mode kill count. |
| `ITEMLOG_ITEM_VORKATH_DRAGONHIDE_UPGRADE_MATERIAL` | Your boss log count of Vorkath's spikes. |
| `ITEMLOG_ITEM_VORKATH_DRACOLICH_UPGRADE_MATERIAL` | Your boss log count of Vorkath's scales. |
| `ITEMLOG_ITEM_NECROMANCY_INCANTATION_CODEX_INVOKE_LORD_OF_BONES` | Your boss log count of the codex. |
| Your backpack | How many chests you have, normal and hard, to see one opened. |

## Not counted

- **Zemouregal's nexus:** it's given at 100 kills, not dropped.
- **Vorki:** pets aren't counted.
- **Vorkath's claw, Vorkath's head and the weapon override token:** they go
  straight to your backpack at the kill and aren't on this boss log page.

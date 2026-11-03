# Zemouregal & Vorkath

Source: Jagex's 8 January 2024 post, raised 14 July 2025, via the [RuneScape Wiki](https://runescape.wiki/w/Zemouregal_%26_Vorkath) (CC BY-NC-SA 3.0), checked 30 October 2026.

## Drop rates

Every player who did damage gets their own chest, so team size doesn't matter.
Each chest rolls once for a rare, in its first slot:

| Rare | Normal | Hard mode |
|---|---|---|
| Vorkath's spike | 1 in 45 (4 to 7) | 1 in 15 (6 to 9) |
| Invoke Lord of Bones incantation codex | 1 in 249 | 1 in 150 |
| Vorkath's scale | none | 1 in 150 |

## How kills are counted

- **Chests opened** are counted, not kills, since chests can be kept. A chest
  counts for its mode (it says normal or hard), with any rare in it, when it
  leaves your backpack as the reward window opens. Banking or claiming doesn't
  count.
- So saving chests never looks unlucky, and a chest opened with Boss RNG off
  isn't tracked, nor its loot.
- Spikes drop in stacks and the boss log counts spikes. Each stack is one drop
  for luck; the spike count shows apart ("All-time: 400 kills · 184
  spikes · 6 other uniques").
- Spikes drive most of the headline luck and dry streak; the codex and scale rows
  show their own.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_FORT_BOSS_ZEMO_VORKATH` | Normal mode kill count. |
| `BSLAY_KILLS_FORT_BOSS_ZEMO_VORKATH_HARD` | Hard mode kill count. |
| `ITEMLOG_ITEM_VORKATH_DRAGONHIDE_UPGRADE_MATERIAL` | Boss log count of spikes. |
| `ITEMLOG_ITEM_VORKATH_DRACOLICH_UPGRADE_MATERIAL` | Boss log count of scales. |
| `ITEMLOG_ITEM_NECROMANCY_INCANTATION_CODEX_INVOKE_LORD_OF_BONES` | Boss log count of the codex. |
| Your backpack | Chests held, normal and hard, to see one opened. |

## Not counted

- **Zemouregal's nexus:** given at 100 kills, not dropped.
- **Vorki** (pet): pets aren't counted.
- **Vorkath's claw, Vorkath's head, weapon override token:** go straight to your
  backpack at the kill; not on this boss log page.

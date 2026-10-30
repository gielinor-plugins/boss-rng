# Raksha, the Shadow Colossus

How Boss RNG counts your Raksha kills. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/Raksha,_the_Shadow_Colossus)
(CC BY-NC-SA 3.0).

## Drop rates

Raksha can be fought solo or in a duo. In a duo, each player gets their own
drop at the same rates as solo, so both count the same.

Each kill has a 1 in 50 chance at the unique table. Since 14 July 2025, the
table gives:

- Fleeting boots: 1 in 130 per kill
- Shadow spike, Greater Ricochet ability codex, Greater Chain ability codex and
  Divert ability codex: 1 in 325 each per kill

Before then, the table also had the Laceration boots and Blast diffusion boots
([wiki revision](https://runescape.wiki/w/Raksha,_the_Shadow_Colossus?diff=prev&oldid=36778162)):

- Laceration boots, Blast diffusion boots and Fleeting boots: 1 in 230 each
- Shadow spike and each codex: 1 in 575 each

## How Boss RNG counts your kills

Solo and duo kills have their own kill counts, at the same rates. Boss RNG came
out after the July 2025 change, so every tracked kill uses today's rates.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_DINO_BOSS_SOLO` | Your solo kill count. |
| `BSLAY_KILLS_DINO_BOSS_DUO` | Your duo kill count. |
| `ITEMLOG_ITEM_DINO_SLAYER_RANGED_BOOTS` | Your boss log count of Fleeting boots. |
| `ITEMLOG_ITEM_DINO_BOSS_BOOTS_ATTACHMENT` | Your boss log count of Shadow spikes. |
| `ITEMLOG_ITEM_COMBATV2_ABILITY_CODEX_<CODEX>` | Your boss log count of each codex: `RANGED_GREATER_RICOCHET`, `MAGIC_GREATER_CHAIN` and `DEFENCE_DIVERT`. |

## Not counted

- **Raklette:** pets aren't counted.
- **Laceration boots and Blast diffusion boots:** no longer dropped, and no
  longer on the collection log.
- **Raksha's head** (a boss trophy, 1 in 500): it isn't on the collection log,
  so there's no count to read.

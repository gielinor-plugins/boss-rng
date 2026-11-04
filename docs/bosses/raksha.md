# Raksha, the Shadow Colossus

Source: [RuneScape Wiki](https://runescape.wiki/w/Raksha,_the_Shadow_Colossus) (CC BY-NC-SA 3.0), checked 29 October 2026; old rates from this [wiki revision](https://runescape.wiki/w/Raksha,_the_Shadow_Colossus?diff=prev&oldid=36778162).

## Drop rates

Each kill has a 1 in 50 roll at the unique table. Solo or duo, each player gets
their own drop at the same rates.

| Item | Since 14 July 2025 | Before |
|---|---|---|
| Fleeting boots | 1 in 130 | 1 in 230 |
| Laceration boots, Blast diffusion boots | not dropped | 1 in 230 each |
| Shadow spike | 1 in 325 | 1 in 575 |
| Greater Ricochet, Greater Chain, Divert ability codex | 1 in 325 each | 1 in 575 each |

## How kills are counted

- Solo and duo have their own kill counts, at the same rates.
- Boss RNG came out after the July 2025 change, so every tracked kill uses
  today's rates.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_DINO_BOSS_SOLO` | Solo kill count. |
| `BSLAY_KILLS_DINO_BOSS_DUO` | Duo kill count. |
| `ITEMLOG_ITEM_DINO_SLAYER_RANGED_BOOTS` | Collection log count of Fleeting boots. |
| `ITEMLOG_ITEM_DINO_BOSS_BOOTS_ATTACHMENT` | Collection log count of Shadow spikes. |
| `ITEMLOG_ITEM_COMBATV2_ABILITY_CODEX_<CODEX>` | Collection log count per codex: `RANGED_GREATER_RICOCHET`, `MAGIC_GREATER_CHAIN`, `DEFENCE_DIVERT`. |

## Not counted

- **Raklette** (pet): pets aren't counted.
- **Laceration boots and Blast diffusion boots:** no longer dropped or on the
  collection log.
- **Raksha's head** (boss trophy, 1 in 500): not on the collection log.

| Collection log item | Id |
|---|---|
| Raklette | 51101 |

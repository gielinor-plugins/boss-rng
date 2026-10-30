# Sanctum of Rebirth

How Boss RNG counts your Sanctum of Rebirth kills (Vermyx, Kezalam and Nakatra, as one entry). Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/Sanctum_of_Rebirth)
(CC BY-NC-SA 3.0).

## Drop rates

Rates are from Jagex, via the wiki's boss pages. Every player gets their own
rolls, and each boss rolls on its own:

| Boss | Book (codex or scripture) | Weapon (Roar or Ode) | Shard |
|---|---|---|---|
| Vermyx, Kezalam | 1 in 125 | none | none |
| Vermyx, Kezalam hard mode | 1 in 100 | none | none |
| Nakatra | 1 in 125 | 1 in 75 | none |
| Nakatra hard mode | 1 in 100 | 1 in 60 | 1 in 75 |

The book is the Divine Rage prayer codex or the Scripture of Amascut, evenly.
Nakatra's weapon is Roar of Awakening or Ode to Deceit, evenly.

The 9 March 2026 update set these rates. Before it, the book table was 1 in 90
(hard mode 1 in 80), Nakatra's weapons 1 in 50 (hard mode 1 in 40) and the Shard
1 in 80.

## How Boss RNG counts your kills

Each boss has its own normal and hard mode kill counts, and all six are
counted. Boss RNG came out after the March 2026 update, so every tracked kill
uses today's rates.

The Shard of Genesis Essence has one boss log count shared with Amascut. A
tracked Shard counts for whichever of the two you killed last.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_RAID_REBIRTH1_<BOSS>` | Your kill count for each boss: `WYRM_BOSS` (Vermyx), `BEAST_BOSS` (Kezalam) and `SLAYER_MASTER_BOSS` (Nakatra), each also with `_HARDMODE`. |
| `ITEMLOG_ITEM_<ITEM>` | Your boss log count for each unique: `COMBATV2_PRAYER_CODEX_DIVINE_RAGE`, `RAID_REBIRTH1_AMASCUT_BOOK_UNLOCK_TOKEN` (scripture), `MAGIC_DEVOURER_WAND_T95` (Roar), `MAGIC_DEVOURER_ORB_T95` (Ode) and the Shard's. |

## Not counted

- **Vermyx's head**, **Kezalam's head** and **Nakatra's mosaic** (boss trophies,
  1 in 50 each from their boss): they aren't on the collection log, so there's
  no count to read.
- **The Brood Mother**, **The Beast of Darkness** and **Death and Devourers**
  (lore) and **Neffie** (pet): lore books and pets aren't counted.

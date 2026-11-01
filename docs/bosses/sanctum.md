# Sanctum of Rebirth

Source: Jagex via the [RuneScape Wiki](https://runescape.wiki/w/Sanctum_of_Rebirth) boss pages (CC BY-NC-SA 3.0), checked 27 October 2026. Vermyx, Kezalam and Nakatra are one entry.

## Drop rates

Every player gets their own rolls, and each boss rolls on its own. The book is
the Divine Rage prayer codex or the Scripture of Amascut, evenly; Nakatra's
weapon is Roar of Awakening or Ode to Deceit, evenly.

| Boss | Book | Weapon | Shard |
|---|---|---|---|
| Vermyx, Kezalam | 1 in 125 | none | none |
| Vermyx, Kezalam hard mode | 1 in 100 | none | none |
| Nakatra | 1 in 125 | 1 in 75 | none |
| Nakatra hard mode | 1 in 100 | 1 in 60 | 1 in 75 |

The 9 March 2026 update set these. Before: book 1 in 90 (hard mode 1 in 80),
Nakatra's weapons 1 in 50 (hard mode 1 in 40), Shard 1 in 80.

## How kills are counted

- All six kill counts (each boss, normal and hard mode) are counted.
- Boss RNG came out after the March 2026 update, so every tracked kill uses
  today's rates.
- The Shard of Genesis Essence has one boss log count shared with Amascut. A
  tracked Shard counts for whichever of the two you killed last.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_RAID_REBIRTH1_<BOSS>` | Kill count per boss: `WYRM_BOSS` (Vermyx), `BEAST_BOSS` (Kezalam), `SLAYER_MASTER_BOSS` (Nakatra), each also with `_HARDMODE`. |
| `ITEMLOG_ITEM_<ITEM>` | Boss log count each: `COMBATV2_PRAYER_CODEX_DIVINE_RAGE`, `RAID_REBIRTH1_AMASCUT_BOOK_UNLOCK_TOKEN` (scripture), `MAGIC_DEVOURER_WAND_T95` (Roar), `MAGIC_DEVOURER_ORB_T95` (Ode) and the Shard's. |

## Not counted

- **Vermyx's head**, **Kezalam's head** and **Nakatra's mosaic** (boss trophies,
  1 in 50 each from their boss): not on the collection log.
- **The Brood Mother**, **The Beast of Darkness** and **Death and Devourers**
  (lore) and **Neffie** (pet): lore and pets aren't counted.

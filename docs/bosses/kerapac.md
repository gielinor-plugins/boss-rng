# Kerapac

Source: [RuneScape Wiki](https://runescape.wiki/w/Kerapac,_the_bound) (CC BY-NC-SA 3.0), checked 28 October 2026.

## Drop rates

Each kill gives three loot piles, each rolling for a unique. "Wraps, codex or
scripture" is Kerapac's wrist wraps, the Greater Concentrated Blast codex or the
Scripture of Jas, evenly.

| Roll, per pile | Normal | Hard mode |
|---|---|---|
| Fractured Staff of Armadyl piece | none | 1 in 400 |
| Wraps, codex or scripture | 1 in 256 | 1 in 180, only if the staff roll misses |

Staff pieces drop in order (shaft, gem, then symbol), so they're one row.

## How kills are counted

- Piles by team: solo all three; duo two for the top damager and one for the
  other (one and a half on average); trio one each.
- The kill count doesn't say how many piles you got, and counting them as they
  land isn't reliable. So each mode uses your average piles per kill, 1 to 3, set
  on the settings page (Plugin Hub, Manage, Boss RNG's gear). It starts at 3 (as
  if solo), applies to all kills in that mode, and the Info tab shows it.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_EGWD_JAS_BOSS` | Normal mode kill count. |
| `BSLAY_KILLS_EGWD_JAS_BOSS_HARDMODE` | Hard mode kill count. |
| `ITEMLOG_ITEM_EGWD_JAS_<ITEM>` | Boss log count each: `BOSS_MAGIC_WEAPON_TOP`, `_MIDDLE`, `_BOTTOM` (staff pieces), `BOSS_MAGIC_GLOVES` (wraps), `BOOK_UNLOCK_TOKEN` (scripture). The codex's is `ITEMLOG_ITEM_COMBATV2_ABILITY_CODEX_MAGIC_GREATER_CONCENTRATED_BLAST`. |

## Not counted

- **Kerapac's time-torn Staff of Armadyl** (boss trophy, 1 in 500): not on the
  collection log.
- **Kerry** (pet): pets aren't counted.

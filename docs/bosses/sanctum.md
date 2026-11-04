# Sanctum of Rebirth

Source: Jagex via the [RuneScape Wiki](https://runescape.wiki/w/Sanctum_of_Rebirth) boss pages (CC BY-NC-SA 3.0), checked 27 October 2026. Vermyx, Kezalam and Nakatra are tracked together.

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

- Each boss's loot waits in a chest until you claim it, and the run can't be entered
  again until you do. So each claim is one kill, counted when you claim, at that
  boss's difficulty (normal or hard mode). Uniques reach the collection log at the
  claim (assumed, as at Amascut), so they're counted with it.
- A claim counts only if Boss RNG saw its kill: loot left waiting from before
  Boss RNG was on isn't counted.
- Boss RNG came out after the March 2026 update, so every tracked kill uses
  today's rates.
- The Shard of Genesis Essence has one collection log count shared with Amascut. A
  tracked Shard counts for whichever of the two you killed last.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_RAID_REBIRTH1_<BOSS>` | Kill count per boss: `WYRM_BOSS` (Vermyx), `BEAST_BOSS` (Kezalam), `SLAYER_MASTER_BOSS` (Nakatra), each also with `_HARDMODE`. |
| `RAID_REBIRTH1_VARP_1` | Each boss's waiting loot and its difficulty (0 normal, 1 hard): Vermyx bit `0x1`, difficulty `0x300`; Kezalam `0x4`, `0xC00`; Nakatra `0x10`, `0x3000`. Its rare fields (`0x2`, `0x8`, `0x20`, and the run's `0x40`, `0x80`) would reveal a reward before it's claimed, so they're never read. |
| `ITEMLOG_ITEM_<ITEM>` | Collection log count each: `COMBATV2_PRAYER_CODEX_DIVINE_RAGE`, `RAID_REBIRTH1_AMASCUT_BOOK_UNLOCK_TOKEN` (scripture), `MAGIC_DEVOURER_WAND_T95` (Roar), `MAGIC_DEVOURER_ORB_T95` (Ode) and the Shard's. |

## Tests

In game on 1 November 2026 by the developer, solo, logging each var change with
its game tick.

| Test | Seen |
|---|---|
| Nakatra hard mode kill | Kill count 75 to 76 and Nakatra's loot bit set, in one tick, with difficulty 1. |
| Its claim, inside | The boss reward chest opened and the loot bit and difficulty cleared, in one tick. Kill count unchanged. |
| Vermyx, then Kezalam, normal mode | Each: kill count and loot bit up in the kill's tick, difficulty 0; bit cleared in the claim's tick. |
| Nakatra normal mode, left before claiming | Re-entering was refused until claimed. The claim from the chest outside (another inventory) cleared the bit in its tick. |

No unique dropped in these tests. Jagex's drop rates post says Nakatra's weapon
and Shard rolls happen once per run, when Nakatra dies, which likely fills the
two run rare fields; they add no rolls beyond the rates above.

## Not counted

- **Vermyx's head**, **Kezalam's head** and **Nakatra's mosaic** (boss trophies,
  1 in 50 each from their boss): not on the collection log.
- **The Brood Mother**, **The Beast of Darkness** and **Death and Devourers**
  (lore) and **Neffie** (pet): lore and pets aren't counted.

| Collection log item | Id |
|---|---|
| The Brood Mother | 57121 |
| The Beast of Darkness | 57122 |
| Death and Devourers | 57123 |
| Neffie | 57167 |

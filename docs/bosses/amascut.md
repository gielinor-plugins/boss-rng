# Amascut, the Devourer

How Boss RNG counts your Amascut kills. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/Amascut,_the_Devourer)
(CC BY-NC-SA 3.0).

## Drop rates

Rates are from Jagex's "Drop Rates Revealed", via the wiki. Every player gets
their own unique rolls each kill, whatever the team size:

- a weapons and armor roll: armor three times in four (split evenly over the
  five pieces of Tumeken's set), otherwise one of the two weapons (Tumeken's
  Light or the Devourer's Guard)
- a roll for the Devourer's Nexus
- in enrage mode only, a roll for the Shard of Genesis Essence

| Mode | Weapons and armor | Nexus | Shard |
|---|---|---|---|
| Normal | 1 in 600 | 1 in 750 | none |
| Enrage 100% | 1 in 70 | 1 in 280 | 1 in 280 |
| Enrage 500% | 1 in 60 | 1 in 240 | 1 in 240 |
| Enrage 750% | 1 in 50 | 1 in 200 | 1 in 200 |
| Enrage 1,000% | 1 in 35 | 1 in 140 | 1 in 140 |
| Enrage 2,000%+ | 1 in 25 | 1 in 100 | 1 in 100 |

So each armor piece is 3/20 of the weapons and armor chance, and each weapon 1/8
of it.

## How Boss RNG counts your kills

- **Tracked enrage kills:** when your enrage kill count goes up, Boss RNG reads
  the enrage you set for the instance and counts the kill at the rates of the
  highest tier at or below it.
- **Untracked enrage kills:** your kill count can't say their enrage, so you
  pick your average enrage on the settings page (Plugin Hub > Manage > Boss RNG
  settings). Untracked kills are ones Boss RNG didn't record: from before you
  installed it, while it was off, or on another device.
- **Loot piles:** each kill makes five loot piles, each with its own rolls. In a
  team of five you get one; in smaller teams the extra piles go to the top
  damagers. Your kill count doesn't say your team, so Boss RNG assumes one pile
  per kill, as in a team of five.
- **The Shard of Genesis Essence** has one boss log count shared with Nakatra in
  the Sanctum of Rebirth. A tracked Shard counts for whichever of the two you
  killed last. If you have untracked Shards from both, you split them between
  the two on the settings page.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_AMASCUT_BOSS` | Your normal mode kill count. |
| `BSLAY_KILLS_AMASCUT_BOSS_HARDMODE` | Your enrage mode kill count, every tier. |
| `AMASCUT_BOSS_LAST_ENRAGE` | The enrage set for the instance, read at each enrage kill. |
| `ITEMLOG_ITEM_<ITEM>` | Your boss log count for each unique, for example `MAGIC_DEVOURER_HEAD_T95` (mask), `MELEE_DEVOURER_HALBERD_T95` (Tumeken's Light), `NECRO_DEVOURER_ARMGUARD_T95` (Devourer's Guard) and `NECRO_DEVOURER_NEXUS_T80`. The Shard's is `COMBATV2_INNATE_MASTERY_UNLOCK_T95_WEAPON_STAT_UPGRADE_T1`. |

## Not counted

- **Amascut's crown** (a boss trophy, 1 in 500): it isn't on the collection log,
  so there's no count to read.
- **Memoirs of the Devourer** (lore) and **Amaskitty** (pet): lore books and
  pets aren't counted.

# Amascut, the Devourer

Source: Jagex's "Drop Rates Revealed" via the [RuneScape Wiki](https://runescape.wiki/w/Amascut,_the_Devourer) (CC BY-NC-SA 3.0), checked 27 October 2026.

## Drop rates

Each kill makes five loot piles, whatever the team size (in smaller teams the extra
piles go to the base tank and top damagers). Each pile rolls separately for weapons
and armor (armor 3 in 4, split over the five Tumeken's pieces, so 3/20 each;
otherwise Tumeken's Light or the Devourer's Guard, 1/8 each), the Devourer's Nexus
and, in enrage only, the Shard of Genesis Essence.

| Mode | Weapons and armor | Nexus | Shard |
|---|---|---|---|
| Normal | 1 in 600 | 1 in 750 | none |
| Enrage 100% | 1 in 70 | 1 in 280 | 1 in 280 |
| Enrage 500% | 1 in 60 | 1 in 240 | 1 in 240 |
| Enrage 750% | 1 in 50 | 1 in 200 | 1 in 200 |
| Enrage 1,000% | 1 in 35 | 1 in 140 | 1 in 140 |
| Enrage 2,000%+ | 1 in 25 | 1 in 100 | 1 in 100 |

## How kills are counted

- **Piles claimed** are counted, not kills ("piles" in the panel). Piles wait in
  your chest across kills; no new instance starts until you claim.
- At a claim, the chest's pile count just before it falls to 0 is the claim's
  piles, counted at that chest's rates with any unique in it.
- **Only fully seen claims count:** every kill since the count was last 0 must
  have raised it, and the rises must add up to the claim. Otherwise the whole
  claim is skipped, so it never skews luck. This catches loot from before Boss
  RNG was on or before login, and stacked kills that stop raising the count.
  Claiming after each kill avoids both; the panel and details window say so.
- **Mode:** the chest says if it's normal mode; otherwise the instance's enrage
  picks the highest tier at or below it (4,000% counts as 2,000%+). A chest's
  piles always share one instance.
- Waiting uniques are never read before the claim; the game only shows a green
  glow.
- The Shard's collection log count is shared with Nakatra (Sanctum of Rebirth); a
  tracked Shard counts for whichever you killed last.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_AMASCUT_BOSS` | Normal mode kill count (boss log line). |
| `BSLAY_KILLS_AMASCUT_BOSS_HARDMODE` | Enrage kill count, all tiers (boss log line). |
| `AMASCUT_BOSS_VARP_1` | Waiting loot: piles (`AMASCUT_BOSS_COMMON_LOOT_AVAILABLE`) and normal mode or not (`AMASCUT_BOSS_LOOT_DIFFICULTY`), read at the claim. |
| `AMASCUT_BOSS_LAST_ENRAGE` | The instance's enrage, read when claiming enrage loot. |
| `ITEMLOG_ITEM_<ITEM>` | Collection log count each, e.g. `MAGIC_DEVOURER_HEAD_T95` (mask), `MELEE_DEVOURER_HALBERD_T95` (Tumeken's Light), `NECRO_DEVOURER_ARMGUARD_T95` (Devourer's Guard), `NECRO_DEVOURER_NEXUS_T80`; Shard `COMBATV2_INNATE_MASTERY_UNLOCK_T95_WEAPON_STAT_UPGRADE_T1`. |

`AMASCUT_BOSS_VARP_1` bits, from the game's varbit definitions
(`AMASCUT_BOSS_LOOT_AVAILABLE` is bits 16 to 27):

| Bits | Varbit | Seen |
|---|---|---|
| 0 to 15 | `AMASCUT_BOSS_HIGHEST_ENRAGE` | Best enrage ever (2000) |
| 16 to 18 | `AMASCUT_BOSS_COMMON_LOOT_AVAILABLE` | Piles waiting (0 to 7) |
| 19 to 27 | `AMASCUT_BOSS_RARE_1/2/3_LOOT_AVAILABLE` | Rares waiting, never read |
| 28 to 31 | `AMASCUT_BOSS_LOOT_DIFFICULTY` | 0 normal, 2 at 100%, 5 at 1,000% |

## Tests

In game on 31 October 2026 by the developer, teams of 2, 3 and 5, logging each
var change with its game tick.

| Test | Seen |
|---|---|
| Enrage 1,000%, team of 3, base role | Piles 2, set in the kill count's tick. Enrage var changed (750 to 1000) as the instance started. |
| Claiming it | Chest opened and loot var cleared (piles 0) in one tick. |
| Enrage 1,000%, team of 5, 2 kills, then a claim | Piles 1, 2, then 0. A teammate got a unique; the developer's rare fields stayed 0. |
| Normal, team of 2, top damage | Piles 3, difficulty 0, enrage var unchanged (1000). Re-entry before claiming refused: "You cannot enter, as you still have loot to claim from the nearby chest." |
| Enrage 100%, team of 2, 3 kills, rejoining between, then a claim | Piles 3, then 5 (re-entry allowed). Kill 3 raised the kill count (1477 to 1478) but not the piles (still 5, though 7 fits). No loot seemed missing; can't tell if the chest held 5 piles or 8. Claim cleared 5 to 0. |

Also confirmed: no solo kills; enrage is set at 100, 500, 750, 1,000, 2,000 or
4,000%; unclaimed loot survives logging out.

Conclusions:
- Piles rise in the kill count's tick and fall to 0 in the claim's tick (seen
  five times), so a claim's old value is its piles.
- Stacked loot can stop raising the count (kill 3). Counting such a claim would
  show the player luckier than they are, hence the fully seen rule, which
  doesn't depend on why it happens (unknown).
- Difficulty tells normal mode apart (the enrage var keeps the last enrage
  instance's); the enrage var gives the tier.
- The rare fields are the player's own and clear at the claim. Three fields fit
  the three unique rolls, so they likely count waiting rares (unconfirmed).
  Never read: they'd reveal the chest early.
- Assumed, not yet confirmed in game: your own unique reaches the collection log
  at the claim, the first time the game shows which unique it is.

## Not counted

- **Amascut's crown** (boss trophy, 1 in 500): not on the collection log.
- **Memoirs of the Devourer** (lore) and **Amaskitty** (pet): lore and pets
  aren't counted.

| Collection log item | Id |
|---|---|
| Memoirs of the Devourer | 59321 |
| Amaskitty | 59363 |

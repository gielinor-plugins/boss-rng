# Amascut, the Devourer

How Boss RNG counts your Amascut loot. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/Amascut,_the_Devourer)
(CC BY-NC-SA 3.0).

## Drop rates

Rates are from Jagex's "Drop Rates Revealed", via the wiki. Each kill makes five
loot piles, whatever the team size: one per player in a team of five, and in
smaller teams the extra piles go to the top damagers. Each pile has its own
unique rolls:

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

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_AMASCUT_BOSS` | Your normal mode kill count, shown on the boss log line. |
| `BSLAY_KILLS_AMASCUT_BOSS_HARDMODE` | Your enrage mode kill count, every tier, shown on the boss log line. |
| `AMASCUT_BOSS_VARP_1` | Your chest's waiting loot: the piles (`AMASCUT_BOSS_COMMON_LOOT_AVAILABLE`) and whether it's normal mode (`AMASCUT_BOSS_LOOT_DIFFICULTY`), read as you claim it. |
| `AMASCUT_BOSS_LAST_ENRAGE` | The enrage set for the instance, read as you claim enrage loot. |
| `ITEMLOG_ITEM_<ITEM>` | Your boss log count for each unique, for example `MAGIC_DEVOURER_HEAD_T95` (mask), `MELEE_DEVOURER_HALBERD_T95` (Tumeken's Light), `NECRO_DEVOURER_ARMGUARD_T95` (Devourer's Guard) and `NECRO_DEVOURER_NEXUS_T80`. The Shard's is `COMBATV2_INNATE_MASTERY_UNLOCK_T95_WEAPON_STAT_UPGRADE_T1`. |

## How Boss RNG counts your loot

Your piles wait in your chest, adding up over kills, until you claim them, and
you can't start a new instance until you do. So Boss RNG counts **loot piles
claimed**, not kills: when you claim your chest, it counts the piles in it at
that chest's rates, along with any unique in it. Your numbers say "piles"
instead of "kills" for this boss.

- **Piles:** the game keeps how many piles are waiting in your chest, and it
  goes up by your piles at each kill. When you claim, it falls to 0, and its
  value just before is your piles.
- **Only fully seen claims count.** Boss RNG counts a claim only if it saw every
  pile in it arrive: each kill since the count was last empty raised it, and
  the rises add up to what you claim. Otherwise the claim isn't counted, piles
  and uniques together, so it never skews your luck. That happens with loot
  waiting from before Boss RNG was on (or from before you logged in), and when
  stacked kills stop raising the count (see the tests below). Claiming after
  each kill avoids both; the panel and details window say so.
- **Mode:** the chest says whether its loot is from normal mode. Otherwise Boss
  RNG reads the enrage set for the instance and uses the highest tier at or
  below it (4,000% counts as 2,000%+). A chest's piles always share one
  instance, since a new one can't start until they're claimed.
- **Never read:** which uniques are waiting in your chest before you claim it.
  The game only shows that one is (the green glow), so Boss RNG doesn't look.
- **The Shard of Genesis Essence** has one boss log count shared with Nakatra in
  the Sanctum of Rebirth. A tracked Shard counts for whichever of the two you
  killed last.

## How this was tested

In game on 31 October 2026 by the developer, in teams of 2, 3 and 5, logging each
var change with its game tick.

**The loot var.** `AMASCUT_BOSS_VARP_1` holds, by the game's varbit definitions:

| Bits | Varbit | Seen |
|---|---|---|
| 0 to 15 | `AMASCUT_BOSS_HIGHEST_ENRAGE` | Best enrage ever (2000) |
| 16 to 18 | `AMASCUT_BOSS_COMMON_LOOT_AVAILABLE` | Piles waiting (0 to 7) |
| 19 to 27 | `AMASCUT_BOSS_RARE_1/2/3_LOOT_AVAILABLE` | Rares waiting, never read |
| 28 to 31 | `AMASCUT_BOSS_LOOT_DIFFICULTY` | 0 normal, 2 at 100%, 5 at 1,000% |

`AMASCUT_BOSS_LOOT_AVAILABLE` covers bits 16 to 27.

**Tests:**

| Test | Seen |
|---|---|
| Enrage 1,000%, team of 3, base role | Piles 2, set in the kill count's tick. The enrage var changed (750 to 1000) as the instance started. |
| Claiming it | In one tick the chest opened and the loot var cleared (piles 0). |
| Enrage 1,000%, team of 5, 2 kills, then a claim | Piles 1, then 2, then 0. A teammate got a unique; the developer's rare fields stayed 0. |
| Normal, team of 2, top damage | Piles 3, difficulty 0, enrage var unchanged (1000). Re-entering before claiming was refused: "You cannot enter, as you still have loot to claim from the nearby chest." |
| Enrage 100%, team of 2, 3 kills, rejoining between them, then a claim | Piles 3, then 5 (re-entering was allowed). Kill 3 raised the kill count (1477 to 1478) but not the piles: still 5, though 7 would fit. No loot seemed missing. The claim cleared 5 to 0. The loot couldn't settle whether the chest held 5 piles or 8. |

Also confirmed: Amascut can't be killed solo; enrage is set at 100, 500, 750,
1,000, 2,000 or 4,000%; unclaimed loot stays through logging out.

**What this means:**
- Piles rise by each kill's piles in its kill count's tick and fall to 0 in the
  claim's tick (seen five times), so a claim's old value is its piles.
- Stacked loot can stop raising the count (kill 3), leaving a claim's value
  too low. Counting it would show the player luckier than they are, so a
  claim only counts when every kill since the count was last 0 raised it and
  the rises add up. Why kill 3 didn't raise it is unknown; the rule doesn't
  depend on it.
- Difficulty tells normal mode apart (the enrage var keeps the last enrage
  instance's); the enrage var gives the tier.
- The rare fields are the player's own (0 when a teammate got a unique) and
  clear at the claim. Three fields fit the three unique rolls (gear, Nexus,
  Shard), so they likely count waiting rares; unconfirmed. Never read: they'd
  reveal the chest before it's claimed.

**Not yet seen:** one of the developer's own uniques. It's assumed to reach the
boss log at the claim, since only then does the game show
which unique it is.

## Not counted

- **Amascut's crown** (a boss trophy, 1 in 500): it isn't on the collection log,
  so there's no count to read.
- **Memoirs of the Devourer** (lore) and **Amaskitty** (pet): lore books and
  pets aren't counted.

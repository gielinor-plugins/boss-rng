# Arch-Glacor (hard mode)

Source: [RuneScape Wiki](https://runescape.wiki/w/Arch-Glacor) (CC BY-NC-SA 3.0), checked 3 November 2026.

Only hard mode is tracked.

## Drop rates

Any unique, per kill: (1,500 + 15 × enrage + 25 × streak) in a million, where enrage
is the fight's (0 to 4,000%) and streak is the kill's place in the streak (1 to
200). That's 1 in 656 for a streak's first kill at 0% enrage, up to 1 in 15. The
wiki notes players worked the formula out; it matches the published drop rates.

| Unique | Share of a unique |
|---|---|
| Frozen core of Leng | 24% |
| Scripture of Wen | 38% |
| Leng artefact | 38% |

Dark nilas: 1 in 100 per kill on their own roll, whatever the enrage and streak, in
a stack of 2 plus 1 per 5 streak kills (up to 42).

An overcharged pontifex shadow ring raises every unique 2%
([Shared assumptions](README.md#shared-assumptions)), except dark nilas: the wiki
doesn't say it raises them.

## How kills are counted

- A solo fight.
- Each hard mode kill is saved as `h`, with its enrage and streak added up per day
  (`sums` in the saved data). A day's kills use its average enrage and streak. The
  formula is a straight line in both, so the averages give the same expected
  uniques as each kill on its own (dry streak chances differ slightly).
- Loot waits in a chest until claimed, and uniques reach the collection log about a
  second later. A claim resets the streak to 0, so a collection log rise counts as a
  drop only in the 10 seconds after a claim. A claim can bring several of one
  unique: each is a drop. The streak stops rising at 200, but kills can go on
  unclaimed, so a claim's rise has no tight limit (up to 10,000). Normal mode never
  resets the streak, so its drops (the scripture, the artefact and dark nilas)
  aren't counted here.
- Dark nilas aren't on the wiki's unique table, but they count as a unique here:
  they're on the collection log, rare (1 in 100) and needed for the Leng weapons.
- Dark nilas count like Vorkath's spikes: all of a claim's dark nilas are one drop,
  and their collection log count, which counts items, is shown separately
  ("All-time: 233 kills · 7 dark nilas · 5 other uniques"). A long streak can hold
  two drops, which the plugin counts as one. The Info tab says so.
- A death keeps part of the streak's loot (5% per streak kill, up to 75%), claimed
  later at the chest outside. Kills whose loot was lost count as dry. Uniques kept
  count at that claim.
- The all-time unique count is the collection log's, so it includes normal mode
  drops.
- A claim's uniques count even when some of the streak's kills weren't tracked: kills
  made before installing Boss RNG or while it was off, or cleared by a reset before
  the claim. Those uniques count without their kills, so luck reads higher than it
  should. Claiming a streak before installing or resetting avoids it.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_EGWD_WEN_BOSS_HARDMODE` | Hard mode kill count. |
| `EGWD_WEN_BOSS_CURRENT_ENRAGE` | The fight's enrage, read at the kill. It rises only when the player continues the streak. |
| `EGWD_WEN_BOSS_CURRENT_STREAK` | Kills in the streak, this one included, read at the kill. 0 once claimed. |
| `ITEMLOG_ITEM_EGWD_WEN_<ITEM>` | Collection log count each: `BOSS_INGREDIENT_HARDMODE` (Frozen core of Leng), `BOOK_UNLOCK_TOKEN` (scripture), `BOSS_GLOVES_UPGRADE` (Leng artefact), `BOSS_INGREDIENT_RARE_NEW` (dark nilas). |
| `EGWD_PONTIFEX_RING_PASSIVE_UNLOCKED` | 1 once the pontifex shadow ring is overcharged. |

## Tests

In game on 3 November 2026 by the developer, solo, overcharged pontifex shadow ring.

### Method

A dev probe logged, with the logic tick (50 per second):

- values, on every change: both kill counts, every `ITEMLOG_ITEM_EGWD_WEN_`
  collection log count, every var named with ENRAGE or STREAK, and the pontifex
  ring's vars;
- names only, at most once a second: every other `EGWD_WEN` or `GLACOR` var;
- names only: each inventory the game added or updated, except the backpack and worn
  gear.

Names with REWARD, LOOT, DROP, SEED, UNIQUE, CHEST, RARE, PIECE or OWED were never
read, except collection log counts, so loot waiting in the chest stayed unread.

### Runs

| Run | Seen |
|---|---|
| 1. Three kills from 0%, then a claim | At each kill, the kill count and the streak rose in the same tick (streak 1, 2, 3), with enrage 0, 10 and 20. Enrage rose only on continuing, about 8 seconds after each kill. The claim reset the streak and enrage to 0. No unique. |
| 2. Two kills, a death in the third fight, a claim outside | The kills as in run 1 (enrage 0, 16, 24). The death changed neither the kill count nor the streak. The claim at the chest outside, about 70 seconds later, reset the streak to 0. The chest opens a loot window, and the streak resets when the loot is claimed from it, not when the chest opens. |
| 3. Five kills from 3,000%, a Scripture of Wen, a claim | Streak 1 to 5, and enrage 3,000, 3,013, 3,026, 3,038 and 3,053 at the kills. The claim reset the streak to 0 and enrage to 3,000, the next streak's start. 60 ticks (1.2 seconds) after the claim, the scripture's collection log count rose from 4 to 5. |

The loot chest updated 3 to 5 seconds after each kill.

Collection log counts read at rest matched the player's collection log: Scripture
of Wen 4, Frozen core of Leng 0, Leng artefact 1, dark nilas 7. The ring's vars read
`EGWD_PONTIFEX_RING_PASSIVE_UNLOCKED` 1, and `_UPGRADE` 1 and `_CHARGE` 1,000 for
each Elder God Wars Dungeon boss.

### Conclusions

- **Rate at the kill.** The kill count and the streak rise in the same tick, and the
  enrage still holds the fight's value: it changes only when the player chooses to
  continue, always after the kill. So the kill event reads both at the kill. The
  streak var already includes this kill (the wiki's "streak + 1").
- **Enrage gain varies** (+10, +10, +16, +8, +13, +13, +12, +15), so it's read at
  every kill, never predicted.
- **The claim is the streak falling to 0.** A death leaves the streak as it was
  until the claim outside, so one rule covers both.
- **Uniques reach the collection log after the claim's tick** (60 ticks in run 3),
  so a rise counts within 10 seconds of a claim. Counting only the claim's tick
  would have missed it.
- **Normal mode drops stay out:** normal mode has no streak, so no claim.

### Tracking checks

Run 3's saved tallies and window, against values worked out by hand:

| Check | Saved or shown | Worked out |
|---|---|---|
| Kills on day 20760 | 9 | 4 (streak 10 to 13, the night before a world reset) + 5 |
| Streak sum | 61 | 10 + 11 + 12 + 13 + 1 + 2 + 3 + 4 + 5 |
| Enrage sum | 23,712 | 2,123 + 2,138 + 4,321 (two kills not logged) + 3,000 + 3,013 + 3,026 + 3,038 + 3,053 |
| Expected uniques | 0.468 | (9 × 1,500 + 15 × 23,712 + 25 × 61) / 1,000,000 / 0.98 = 0.378, plus 9 × 1/100 dark nilas |
| Headline | Top 23% luck | 22.7% of players fewer, for 1 unique at 0.468 expected |
| Scripture of Wen | 1, top 8%, Dry 0 | 0.144 expected; its streak and any unique's restarted at the claim |
| Still dry: Frozen core, Leng artefact, dark nilas | 91%, 86%, 91% | 91.3%, 86.5%, 91.4% |

A world reset ended the earlier streak unclaimed: its 4 kills count as dry, and the
next kill saved streak 1 at 3,000%.

The collection log page (`COLLECTION_BOSS_EGWD_WEN_BOSS`, row 4493) lists 13 items,
with the same ids as the boss file and the Not counted table below.

### Assumed, not yet confirmed in game

- A claim with several of one unique raises its collection log count by that many,
  each counted as a drop.
- A claim's dark nilas raise their count once, counted as one drop.

## Not counted

- **Arch-Glacor core** (boss trophy, 1 in 500): not on the collection log.
- **Glacor remnants:** a common drop.
- **Dark ice shard and sliver, the Dark Shard and Sliver of Leng, and the three
  Adornments:** made, not dropped.
- **Gladys** (pet): pets aren't counted.

| Collection log item | Id |
|---|---|
| Glacor remnants | 52018 |
| Dark ice shard | 52041 |
| Dark ice sliver | 52045 |
| Dark Shard of Leng | 52053 |
| Dark Sliver of Leng | 52057 |
| Glacor's Adornment | 52022 |
| Arch-Glacor's Adornment | 52023 |
| Ur-Glacor's Adornment | 52024 |
| Gladys | 52119 |

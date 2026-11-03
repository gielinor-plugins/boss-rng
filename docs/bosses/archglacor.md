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

The overcharged pontifex shadow ring raises every unique 2% (`src/bosses/egwd.lua`).
The wiki doesn't say it raises dark nilas, so they're left as they are.

## How kills are counted

- A solo fight.
- Each hard mode kill is saved as `h`, with its enrage and streak added up per day
  (`sums` in the saved data). A day's kills use its average enrage and streak. The
  formula is a straight line in both, so the averages give the same expected
  uniques as each kill on its own (dry streak chances differ slightly).
- Loot waits in a chest until claimed, and uniques reach the boss log about a
  second later. A claim resets the streak to 0, so a boss log rise counts as a drop
  only in the 10 seconds after a claim. A claim can bring several of one unique:
  each is a drop. The streak stops rising at 200, but kills can go on unclaimed,
  so a claim's rise has no tight limit (up to 10,000). Normal mode never resets the
  streak, so its drops (the scripture, the artefact and dark nilas) aren't counted
  here.
- Dark nilas aren't on the wiki's unique table, but they count as a unique here:
  they're on the boss log, rare (1 in 100) and needed for the Leng weapons.
- Dark nilas count like Vorkath's spikes: a claim's are one drop, and the boss log
  count (items) shows apart ("All-time: 233 kills · 7 dark nilas · 5 other
  uniques"). A long streak can hold two drops, which the plugin counts as one. 
  The Info tab says so.
- A death keeps part of the streak's loot (5% per streak kill, up to 75%), claimed
  later at the chest outside. Kills whose loot was lost count as dry. Uniques kept
  count at that claim.
- The all-time unique count is the boss log's, so it includes normal mode drops.
- If the ring isn't overcharged, the plugin can't see it, so it's assumed not
  worn.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_EGWD_WEN_BOSS_HARDMODE` | Hard mode kill count. |
| `EGWD_WEN_BOSS_CURRENT_ENRAGE` | The fight's enrage, read at the kill. It rises only when the player continues the streak. |
| `EGWD_WEN_BOSS_CURRENT_STREAK` | Kills in the streak, this one included, read at the kill. 0 once claimed. |
| `ITEMLOG_ITEM_EGWD_WEN_<ITEM>` | Boss log count each: `BOSS_INGREDIENT_HARDMODE` (Frozen core of Leng), `BOOK_UNLOCK_TOKEN` (scripture), `BOSS_GLOVES_UPGRADE` (Leng artefact), `BOSS_INGREDIENT_RARE_NEW` (dark nilas). |
| `EGWD_PONTIFEX_RING_PASSIVE_UNLOCKED` | 1 once the pontifex shadow ring is overcharged. |

## Tests

In game on 3 November 2026 by the developer, solo, overcharged pontifex shadow ring.

### Method

A dev probe logged, with the logic tick (50 per second):

- values, on every change: both kill counts, every `ITEMLOG_ITEM_EGWD_WEN_` boss log
  count, every var named with ENRAGE or STREAK, and the pontifex ring's vars;
- names only, at most once a second: every other `EGWD_WEN` or `GLACOR` var;
- names only: each inventory the game added or updated, but the backpack and worn
  gear.

Names with REWARD, LOOT, DROP, SEED, UNIQUE, CHEST, RARE, PIECE or OWED were never
read, except boss log counts, so loot waiting in the chest stayed unread.

### Runs

| Run | Ticks | Seen |
|---|---|---|
| 1. Three kills from 0%, then a claim | 638480, 640344, 659002 | Kill count 218 to 221. At each kill, in the same tick: streak 0 to 1, 1 to 2, 2 to 3. Enrage at each kill: 0, 10, 20. |
| | 638869, 640759 | Continuing: enrage 0 to 10, 10 to 20, about 8 s after each kill. |
| | 659334 | Claim: streak 3 to 0, enrage 20 to 0, `MONEY_POUCH` updated, `EGWD_WEN_BOSS_LOOT_*` changed. No unique, no boss log change. |
| 2. Two kills, a death in the third fight, a claim outside | 681059, 683485 | Kill count 221 to 223, streak 0 to 1, 1 to 2. Enrage 0 to 16, 16 to 24 on continuing. |
| | 685105 to about 688300 | Third fight and death: no kill count or streak change. |
| | 691946 | Claim at the chest outside, about 70 s after the death: streak 2 to 0, enrage 24 to 0, `MONEY_POUCH` updated. |
| 3. Five kills from 3,000%, a Scripture of Wen, a claim | 5767 to 27132 | Kill count 236 to 241, streak 1 to 5 at each kill. Enrage at each kill: 3,000, 3,013, 3,026, 3,038, 3,053. |
| | 28510 | Claim: streak 5 to 0, enrage 3,053 to 3,000 (the next streak's start). |
| | 28570 | 60 ticks (1.2 s) after the claim: `BOOK_UNLOCK_TOKEN` 4 to 5, `BOSS_INGREDIENT_COMMON_NEW` (Glacor remnants) 16,618 to 17,083. |

Each loot chest update (`EGWD_WEN_BOSS_LOOT_INV`) came 150 to 270 ticks after its kill.

Boss log counts read at rest matched the player's boss log: Scripture of Wen 4,
Frozen core of Leng 0, Leng artefact 1 (`BOSS_GLOVES_UPGRADE`), dark nilas 7
(`BOSS_INGREDIENT_RARE_NEW`). Ring: `EGWD_PONTIFEX_RING_PASSIVE_UNLOCKED` 1, and per
boss `_UPGRADE` 1 and `_CHARGE` 1,000 (BIK, FUL, JAS, WEN).

### Conclusions

- **Rate at the kill.** The kill count and the streak rise in the same tick, and the
  enrage still holds the fight's value: it changes only when the player chooses to
  continue, always after the kill. So the kill event reads both at the kill: s is
  the streak var (this kill included, the wiki's "streak + 1"), e the enrage var.
- **Enrage gain varies** (+10, +10, +16, +8, +13, +13, +12, +15), so it's read at
  every kill, never predicted.
- **The claim is the streak falling to 0.** A death leaves the streak as it was
  until the claim outside, so one rule covers both.
- **Uniques reach the boss log after the claim's tick** (60 ticks in run 3), so a
  rise counts within 10 seconds of a claim. Counting only the claim's tick would
  have missed it.
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

The boss log page (`COLLECTION_BOSS_EGWD_WEN_BOSS`, row 4493) lists 13 items, with
the same ids as the boss file and "Boss log ids" below.

### Not yet checked

- Several of one unique in one claim, and dark nilas at a claim.

## Not counted

- **Arch-Glacor core** (boss trophy, 1 in 500): not on the collection log.
- **Glacor remnants:** a common drop.
- **Dark ice shard and sliver, the Dark Shard and Sliver of Leng, and the three
  Adornments:** made, not dropped.
- **Gladys** (pet): pets aren't counted.

| Boss log item | Id |
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

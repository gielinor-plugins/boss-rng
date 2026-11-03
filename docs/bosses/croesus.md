# Croesus

Source: [RuneScape Wiki](https://runescape.wiki/w/Croesus) (CC BY-NC-SA 3.0), checked 28 October 2026.

## Drop rates

Each unique roll has a 1 in 600 chance of one of nine uniques evenly (1 in 5,400
each): the five Cryptbloom pieces, Sporehammer, Foultorch, Spore sack and
Scripture of Bik. Each player gets their own rolls, by contribution:

- Below 20: no rolls. 20 to 59: 1 loot roll, no unique roll.
- From 60, unique rolls equal loot rolls: 1 at 60, 2 at 100, 3 at 180, 4 at
  230, 5 at 280, 6 at 310, 7 at 330, 8 at 345, 9 at 360, 10 at 380, 11 at 400,
  12 at 420 or more.

## How kills are counted

- At each kill, the kill counts at the unique rolls for your last contribution
  before it. A kill with no contribution seen (say, Boss RNG turned on as the
  kill ended) isn't counted.
- Loot can stack in the chest, but rolls are known at each kill, so kills stay
  the unit.
- Kills are saved by unique rolls, as day and count
  ([saved data](../data/saved_data.md)). Here, 30 full contribution kills and 2
  at 345 to 359 one day, then 5 full the next:

```lua
croesus = {
    kills = { r12 = "20757:30,20758:5", r8 = "20757:2" },
    dryFrom = {},
    items = {},
}
```

- The overcharged pontifex shadow ring raises every unique 2%
  (`src/bosses/egwd.lua`). If it isn't overcharged, the plugin can't see it, so it's
  assumed not worn.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_EGWD_BIK_BOSS` | Kill count. |
| `EGWD_PONTIFEX_RING_PASSIVE_UNLOCKED` | 1 once the pontifex shadow ring is overcharged. |
| `EGWD_BIK_BOSS_PERSONAL_CONTRIBUTION` | Your contribution, rising through the fight (11 bits of `EGWD_BIK_BOSS_TEMP_1`). |
| `ITEMLOG_ITEM_EGWD_BIK_<ITEM>` | Boss log count each, e.g. `BOSS_MAGIC_HELM`, `BOSS_OFFHAND_MINING` (Sporehammer), `BOSS_SEED_STORAGE_UNIQUE` (Spore sack), `BOOK_UNLOCK_TOKEN` (scripture). |

## Tests

In game on 31 October 2026 by the developer, team of 3, logging each var change
with its game tick:

- Contribution rose (188, 242, 311, 398) and read 466 in the kill count's tick:
  the value the game showed, so 12 rolls.
- It read 0 at the chest about 2 minutes later, so it resets after the kill
  (exact time not seen). Using its last value above 0 before the kill makes that
  timing irrelevant.
- No unique dropped, so when one reaches the boss log wasn't seen.

## Not counted

- **Croesus' head** (boss trophy, 1 in 500): not on the collection log.
- **Little Sus** (pet): pets aren't counted.

| Boss log item | Id |
|---|---|
| Little Sus | 52459 |

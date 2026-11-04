# Caching

What Boss RNG keeps in memory to avoid repeating work. Nothing here is saved.
Each cache holds results worked out from saved data or the game, so a stale check
only costs a recompute.

## Picked boss's stats

`withStats` in `src/ui/state.lua` reruns `stats.ForBoss` only when this key changes:

```
<boss key>|<tracker.Changes(boss)>|<all-time kills>|<all-time log counts>|<readings>
```

| Input | Changes when |
|---|---|
| boss key | another boss is picked |
| `tracker.Changes(boss)` | that boss's kill, drop or reset is recorded, every boss is reset, or another character loads |
| all-time counts | the game sends new counts (read every redraw) |
| readings | a value the boss reads from the game (see `reads` in `src/bosses.lua`) changes |

The dropdown reads only `tallies.Total` and `gameVars.AllTimeKills`, so only the
picked boss's stats are worked out. The key is also the entry's `inputs`.

## Drawn views

The panel and window also skip a redraw when what they'd show is unchanged: see
[UI](ui.md#when-views-draw).

## Encoded tallies

`encoded` in `src/core/tracker.lua` keeps each boss's saved form, so a save encodes
only bosses without one. Cleared for one boss by `talliesFor` (before its tallies
change) and for all when another character loads or every boss is reset.

## Within one stats calculation

`rates.For` builds each boss's rate history once. Within each `stats.ForBoss` call,
`batcher` in `src/core/stats.lua` keeps:

- each mode's rolls and each unique's chance per kill, once per
  [rate version](luck-math.md#rate-versions);
- each set of kills (all tracked kills, or one dry streak's) added up by mode and
  rate version, as batches.

Over years of play a boss has hundreds of days of kills but only a few rate
versions, so the math runs once per batch, not once per day. Arch-Glacor is the
exception: its rates depend on each day's average enrage and streak, so each day is
its own version.

## Cost

`stats.ForBoss` was timed with Lua 5.4 on 4 November 2026, taking the fastest of 5
runs, for 5 years of 10 kills a day in every mode listed, with a unique about every
20 days. That's far more than a real player, to show the worst case. Times vary by
about a fifth between runs:

| Boss (modes played) | Day by day | In batches |
|---|---|---|
| Barrows (3 chest types) | about 2,400 ms | 7 ms |
| Croesus (2 contribution levels) | about 200 ms | 3 ms |
| Amascut (normal and 1,000%) | about 70 ms | 3 ms |
| Kree'arra (normal and hard) | about 50 ms | 3 ms |
| Arch-Glacor | about 25 ms | 11 ms |
| Vorkath (hard) | about 9 ms | 1 ms |

A heavy player's whole record: 10 kills a day at 5 bosses and 10 a week at 10 more,
with a unique about every 20 days at each:

| Played for | Saved record | Encoding every boss | Slowest boss's stats |
|---|---|---|---|
| 4 weeks | about 11 KB | under 1 ms | about 2 ms (Barrows) |
| 1 year | about 50 KB | about 5 ms | about 3 ms (Barrows) |
| 5 years | about 220 KB | about 25 ms | about 11 ms (Arch-Glacor) |

So stats take milliseconds even after years, and rerun only when their inputs
change (above). After a kill only that boss is re-encoded. How long the game takes
to write the record wasn't measured. [Saved data](../data/saved-data.md) describes
the record and its size.

## Rules

- Change tallies only through `talliesFor`, then save.
- Anything new `stats.ForBoss` reads must join the inputs key.

# Caches

All in memory, never saved. Each holds results worked out from saved data or the
game, so a stale check only costs a recompute.

## Picked boss's stats

`withStats` in `src/ui.lua` reruns `stats.ForBoss` only when this key changes:

```
<boss key>|<tracker.Changes()>|<all-time kills>|<all-time log counts>|<picks>
```

| Input | Changes when |
|---|---|
| boss key | another boss is picked |
| `tracker.Changes()` | a kill or drop is recorded, or another character loads |
| all-time counts | the game sends new counts (read every redraw) |
| picks | a choice, or a value the boss reads from the game, changes |

The dropdown reads only `tracker.Total` and `gamevars.AllTimeKills`, so only the
picked boss's stats are worked out.

## Encoded tallies

`encoded` in `src/core/tracker.lua` keeps each boss's saved form, so a save encodes
only bosses without one. Cleared for one boss by `talliesFor` (before its tallies
change) and for all when another character loads.

## Also

- `rates.For` builds each boss's rate history once.
- Each `stats.ForBoss` call keeps rolls and chances per rate version.

## Rules

- Change tallies only through `talliesFor`, then save.
- Anything new `stats.ForBoss` reads must join the inputs key.

# Caches

All in memory, never saved. Each holds results worked out from saved data or the
game, so a stale check only costs a recompute.

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

The dropdown reads only `tracker.Total` and `gamevars.AllTimeKills`, so only the
picked boss's stats are worked out. The key is also the entry's `inputs`.

## Drawn views

`src/ui.lua` redraws on the logic tick after a change, once however many changes the
tick had (a kill and its drop are two). The panel and window are skipped when what
they show is unchanged: the boss list and the shown boss's `inputs`. So a kill at
another boss leaves them, and their scroll and open dropdowns, alone. Opening the
window, or the game giving the panel a fresh layer, always draws. The settings page
always redraws: it's small and rarely open.

Only views still shown are redrawn. The game gives no event when it minimizes the
ribbon panel, closes it or hands it to another plugin; it clears the layer. So each
layer holds a 1 x 1 transparent marker (`src/ui/layer_view.lua`), and a layer that no
longer lists the marker among its children isn't drawn in until the game gives it
back (`ContentLayerReady` or `SettingsLayerReady`, which redraw). A layer that can't
list its children falls back to the marker's `visibleGlobal`.

Tested in game on 3 November 2026 (ribbon panel, read every half second):

| Panel | Layer's children | Our marker |
|---|---|---|
| Open | 4, including the marker | a child |
| Minimized or closed | 0 | not a child |
| Given to another plugin | the other plugin's (2 to 4) | not a child, though its `visibleGlobal` could still read true |
| Restored or picked again | `ContentLayerReady` fired, then redrawn | a new marker, a child |

Kills while another plugin was shown or the panel was minimized drew nothing; switching
back showed them. The layer's own `visible`, `visibleGlobal` and `hidden` never
changed, so only a component of ours, found among its children, tells.

## Encoded tallies

`encoded` in `src/core/tracker.lua` keeps each boss's saved form, so a save encodes
only bosses without one. Cleared for one boss by `talliesFor` (before its tallies
change) and for all when another character loads or every boss is reset.

## Also

- `rates.For` builds each boss's rate history once.
- Each `stats.ForBoss` call keeps rolls and chances per rate version, or per day
  for a mode with sums that day (Arch-Glacor).

## Cost

Measured on 2 November 2026 with Lua 5.4 on a desktop, 10 kills a day in every
mode, a unique about every 20 days:

| Tracked | `stats.ForBoss` | Encode one boss |
|---|---|---|
| Kree'arra, 1 year | 4.7 ms | 1.0 ms |
| Vorkath, 1 year | 2.3 ms | 0.7 ms |
| Amascut, 1 year | 7.2 ms | 0.7 ms |
| Sanctum of Rebirth (6 modes), 1 year | 5.5 ms | 4.2 ms |
| Kree'arra, 3 years | 20 ms | 3.1 ms |

Each redraw draws the panel and the window, and each kill or drop saves every boss,
so without these caches a heavy player would pay this on every redraw and kill.
Typical data (weeks, not years) costs well under a millisecond.

## Rules

- Change tallies only through `talliesFor`, then save.
- Anything new `stats.ForBoss` reads must join the inputs key.

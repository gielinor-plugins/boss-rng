# Caches

Boss RNG keeps two caches, both in memory only. Neither holds saved data, and
neither is ever saved: each holds something worked out from saved data or the
game, with what it was worked out from, so a change always gives a fresh result.
The worst a cache can do is work something out again.

## Stats of the picked boss

`withStats` in `src/ui.lua`.

**Why:** a redraw happens after every kill and drop, and whenever the panel
opens or resizes or the details window opens, moves or changes. Working out a
boss's stats walks its kills by mode and day for every dry streak, which grows
with days played.

**What's kept:** the last stats worked out, and an inputs key:

```
<boss key>|<tracker.Changes()>|<all-time kills>|<all-time log counts>|<picks>
```

| Input | Changes when |
|---|---|
| boss key | another boss is picked |
| `tracker.Changes()` | a kill or drop is recorded, or another character logs in |
| all-time kills and log counts | the game sends new counts (read from the game every redraw) |
| picks | the player changes a choice, or a value the boss reads from the game changes |

**Use:** every redraw reads the inputs again and builds the key. If it matches,
the kept stats are drawn; if not, stats are worked out again and kept.

**Also:** listing bosses for the dropdown reads only tracked kills
(`tracker.Total`) and the game's kill counts (`gamevars.AllTimeKills`), so only
the picked boss's stats are ever worked out.

## Saved form of each boss's tallies

`encoded` in `src/tracker.lua`.

**Why:** the character's record is saved after every kill and drop, and saving
encodes each boss's kills as text (see `saved_data.md`).

**What's kept:** each boss's encoded tallies, by boss key.

| Cleared | When |
|---|---|
| one boss's | its tallies are about to change (`talliesFor`, used by every kill and drop) |
| every boss's | another character's record is loaded |

**Use:** saving encodes only bosses with nothing kept, then keeps them.

## Rules

- A cache holds only results. Saved data and game values are always read from
  their source.
- Anything that changes tallies goes through `talliesFor` and saves, which
  clears that boss's encoded form and moves `tracker.Changes()` on.
- A new input to stats (anything `stats.ForBoss` reads) must be added to the
  inputs key, or the kept stats could be drawn after it changed.

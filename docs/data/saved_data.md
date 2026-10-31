# Saved data

What Boss RNG saves with `PersistentDB`, and how to read it. Code:
`src/saved.lua` (per-character records), `src/tracker.lua` (version and
conversion) and `src/tallies.lua` (the tallies format).

## Entries

`PersistentDB` is per plugin and shared by every character on the computer, so
each character gets its own entries, keyed by display name:

| Key | Holds | Version |
|---|---|---|
| `char:<name>` | Tallies: kills and drops Boss RNG tracked | 5 |
| `choices:<name>` | The player's picks (Kerapac's team per mode) | 3 |

All-time kill counts and boss log counts are never saved: they're read from
the game. Keys are always text, so item ids and days are saved as text. The
game gives numbers back as decimals (`13.0`).

## `char:<name>`

```
{ version = 5, lastBoss = <boss key>, bosses = { [boss key] = tallies } }
```

`lastBoss` is the boss killed last: a pooled unique (one boss log count shared
by two bosses) is counted for it.

### Tallies

| Field | Saved as | Meaning |
|---|---|---|
| `kills` | `{ [mode name] = "day:n,day:n" }` | Tracked kills per mode and day |
| `dryFrom` | `{ [streak key] = start }` | Starts of dry streaks that don't run from the first kill |
| `items` | `{ [item id] = drops }` | Tracked drops per unique |

**Days** are whole days since 1 January 1970, UTC, from the game clock
(`CLOCK_TIME_DATE_MINUTES`). Day `0` means the clock couldn't be read.

**Kills** are text per mode: `day:count` pairs joined by commas, days in
order. In memory they're `{ [mode name] = { [day] = count } }`.

**Streak keys** are `any` (the boss's streak: kills since any unique) and each
unique's item id (kills since that unique). A drop resets its item's streak
and `any`.

### Dry streaks

A streak isn't saved as kills: it's the kills since its start. A start is one of:

| Start | Saved | Streak |
|---|---|---|
| From the first kill | no entry | every kill |
| After a drop | `{ day, at }` | every kill after `day`, plus kills on `day` and day `0` beyond `at` |
| Kept as counted | `{ dry = { [mode] = "day:n" } }` | exactly `dry`, counted on (see Conversion) |

`day` is the latest day with kills when the streak started (`0` if none), and
`at` the kills then on that day and on day `0`, as `{ [mode] = { [day] = n } }`.
For each mode and day with `n` kills:

```
since = n                     if day > start.day
since = n - at[mode][day]     if day == start.day or day == 0
since = 0                     if day < start.day
```

This is exact because days only go forward: every kill after a start is on its
day or later, or on day `0`.

A unique added to a boss in a plugin update has no entry, so its streak runs
from the boss's first tracked kill, like its expected drops.

## Example

Vorkath: 13 hard mode chests on day 20756, a spike (56079) from the 13th, then
2 more chests on day 20757. The codex (56068) and scale (56321) never dropped.

```json
"vorkath": {
  "kills": { "Hard mode": "20756:13,20757:2" },
  "dryFrom": {
    "56079": { "day": 20756, "at": { "Hard mode": { "20756": 13 } } },
    "any":   { "day": 20756, "at": { "Hard mode": { "20756": 13 } } }
  },
  "items": { "56079": 1 }
}
```

| Streak | Read as | Kills |
|---|---|---|
| `56079` | 20756: 13 - 13 = 0; 20757: 2 (after its day) | 2 |
| `any` | the same start | 2 |
| `56068`, `56321` | no entry: from the first kill | 15 |

Another chest on day 20758 changes `kills` to `"20756:13,20757:2,20758:1"` and
nothing else: every streak gets longer by being read again.

## Conversion

A `char:` record from an older version is converted when it loads
(`codec.Decode` in `src/tracker.lua`), and saved in the new form at the next
change.

- **Version 4** kept each streak's kills, `dry = { [key] = { [mode] = { [day] = n } } }`,
  and kills as tables. Each streak becomes a start: no entry if it equals
  every kill, else from its earliest known day (or after every kill if
  it has none). If reading that start back doesn't give exactly the same kills,
  the streak is kept as counted instead, so nothing is lost.
- **Older versions** start again.

## `choices:<name>`

```
{ version = 3, bosses = { [boss key] = { [choice key] = value } } }
```

For example `{ kerapac = { normalTeam = "solo", hardTeam = "duo" } }`. Choice
keys and values are saved data: never rename them.

## Performance

- **Loading** decodes each mode's text once, when the character's record loads.
- **Saving** happens after every kill and drop. Each boss's encoded tallies are
  kept and only the changed boss is encoded again (`talliesFor` in
  `src/tracker.lua`).
- **Drawing** lists bosses from their kill counts only, and works out stats
  for the picked boss alone. Those stats are kept until the boss, its tallies
  (`tracker.Changes`), the game's totals or the picks change (`withStats` in
  `src/ui.lua`). Only derived numbers are kept, never saved data, so a change
  always gives fresh numbers.

## Size

Each saved table entry costs about 100 bytes on disk (the game writes keys,
values and indentation), so tallies avoid an entry per day: a day of kills adds
about 10 characters to a mode's text, and streaks only change at drops. One
boss with ten uniques played daily for a year is about 10 KB (version 4: about
140 KB).

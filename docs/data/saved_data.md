# Saved data

Saved with `PersistentDB`, which every character on the computer shares, so keys
end in the display name (a new name starts a new entry). Code: `src/utils/saved.lua`,
`src/core/tracker.lua` (version), `src/core/tallies.lua` (format).

| Key | Holds | Version |
|---|---|---|
| `char:<name>` | Tracked kills and drops | 5 |
| `choices:<name>` | The player's picks | 4 |

All-time kill and log counts are read from the game, never saved. Keys are always
text (item ids, days); numbers come back as decimals (`13.0`).

## `char:<name>`

`{ version = 5, lastBoss = <boss key>, bosses = { [boss key] = tallies } }`

`lastBoss` (the boss killed last) gets any pooled unique (one log count shared by
two bosses). Each boss's tallies:

| Field | Saved as |
|---|---|
| `kills` | `{ [mode name] = "day:n,day:n" }`, days in order |
| `dryFrom` | `{ [streak key] = start }` |
| `items` | `{ [item id] = drops }` |

- **Days**: whole days since 1 January 1970 UTC (`CLOCK_TIME_DATE_MINUTES`); `0` if
  the clock couldn't be read.
- **Streak keys**: `any` (since any unique) and each unique's item id. A drop resets
  its item's streak and `any`.

### `dryFrom` starts

A streak is the kills since its start (`tallies.Dry`):

| Saved | Streak |
|---|---|
| no entry | every kill |
| `{ day, at }` | kills after `day`, plus kills on `day` and day `0` beyond `at` |

`day` is the latest day with kills at the drop (`0` if none); `at` is
`{ [mode] = { [day] = n } }` for that day and day `0`. Exact because days only go
forward. A unique added later has no entry, so it runs from the first kill.

## Example

Vorkath: 13 hard mode chests on day 20756, a spike (56079) on the 13th, then 2 more
on day 20757. No codex (56068) or scale (56321).

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

`56079` and `any`: 2 kills. `56068` and `56321`: 15. A new kill changes only `kills`.

## Versions

Any other version starts again: nothing is converted until a release needs it.
Both versions are set to 1 before release (a TODO in the code).

## `choices:<name>`

`{ version = 4, bosses = { [boss key] = { [choice key] = value } } }`, for example
`{ kerapac = { normalPiles = 3, hardPiles = 1.5 } }`. Missing or invalid values use
the default.

## Size

A saved table entry costs about 100 bytes on disk; a day of kills adds about 10
characters to a mode's text. One boss with ten uniques played daily for a year is
about 10 KB.

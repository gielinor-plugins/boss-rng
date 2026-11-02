# Saved data

Boss RNG saves with `PersistentDB`, on this computer only. Every character on the
computer shares it, so each key ends in the display name (a new name starts a new
entry). All-time kill and log counts are read from the game, never saved.

| Key | Holds | Code |
|---|---|---|
| `char:<name>` | Tracked kills, drops and dry streaks | `src/core/tracker.lua`, `src/core/tallies.lua` |
| `choices:<name>` | The player's picks (settings) | `src/core/choices.lua` |

Each record has a `version`. A record with any other version starts again.

Keys are always text (item ids, days), and numbers come back as decimals (`13.0`).

## `char:<name>`

`{ version, lastBoss = <boss key>, bosses = { [boss key] = tallies } }`

`lastBoss`, the boss killed last, gets any pooled unique (one log count shared by
two bosses). Data Controls on the settings page clears one boss's tallies
(`tracker.Reset`) or every boss's (`tracker.ResetAll`), after a confirmation;
`choices:` is kept. Each boss's tallies:

| Field | Saved as |
|---|---|
| `kills` | `{ [mode key] = "day:n,day:n" }`, days in order |
| `dryFrom` | `{ [streak key] = start }` |
| `items` | `{ [item id] = drops }` |

- **Days:** whole days since 1 January 1970 UTC (`CLOCK_TIME_DATE_MINUTES`), or `0`
  if the clock couldn't be read.
- **Mode keys:** short codes set in each boss file: `n` normal, `h` hard mode, or
  the boss's own, such as `e1000` (Amascut's enrage tier), `r12` (Croesus's unique
  rolls) or `c3f` (Barrows: `c` and the hex bits of the brothers killed).
- **Streak keys:** `any` (since any unique) and each unique's item id. A drop resets
  its item's streak and `any`.

### Dry streak starts

A streak is the kills since its start (`tallies.Dry`):

| Saved | Streak |
|---|---|
| no entry | every kill |
| `{ day, at }` | kills after `day`, plus kills on `day` and day `0` beyond `at` |

`day` is the latest day with kills at the drop (`0` if none), and `at` is
`{ [mode key] = { [day] = n } }` for that day and day `0`. This is exact because
days only go forward. A unique added later has no entry, so it runs from the first
kill.

### Example

Vorkath: 13 hard mode chests on day 20756, a spike (56079) on the 13th, then 2 more
on day 20757. No codex (56068) or scale (56321).

```json
"vorkath": {
  "kills": { "h": "20756:13,20757:2" },
  "dryFrom": {
    "56079": { "day": 20756, "at": { "h": { "20756": 13 } } },
    "any":   { "day": 20756, "at": { "h": { "20756": 13 } } }
  },
  "items": { "56079": 1 }
}
```

`56079` and `any`: 2 kills. `56068` and `56321`: 15. A new kill changes only `kills`.

## `choices:<name>`

`{ version, bosses = { [boss key] = { [choice key] = value } } }`, for example
`{ kerapac = { normalPiles = 3, hardPiles = 1.5 } }`. Missing or invalid values use
the default.

## Size

A saved table entry costs about 100 bytes on disk, and a day of kills adds about 10
characters to a mode's text. One boss with ten uniques played daily for a year is
about 10 KB.

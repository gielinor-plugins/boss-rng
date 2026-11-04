# Saved data

Boss RNG saves with `PersistentDB`, on this computer only. Every character on the
computer shares it, so each key ends in the display name (a new name starts a new
entry). All-time kill and log counts are read from the game, never saved.

| Key | Holds | Code |
|---|---|---|
| `char:<name>` | Tracked kills, drops and dry streaks | `src/core/tracker.lua`, `src/core/tallies.lua` |

The record has a `version`. A record with any other version is replaced with an
empty one ([Compatibility](compatibility.md#not-built-yet)).

Keys are always text (item ids, days), and numbers come back as decimals (`13.0`).
A sample record is in [`saved-data.example.json`](saved-data.example.json).

## `char:<name>`

`{ version, lastBoss = <boss key>, bosses = { [boss key] = tallies } }`

`lastBoss`, the boss killed last, gets any pooled unique (one log count shared by
two bosses). Data Controls on the settings page clears one boss's tallies
(`tracker.Reset`) or every boss's (`tracker.ResetAll`), after a confirmation.
Each boss's tallies:

| Field | Saved as |
|---|---|
| `kills` | `{ [mode key] = "day:n,day:n" }`, days in order |
| `sums` | `{ [name] = { [mode key] = "day:total,day:total" } }`, only for bosses whose kills carry values (see below) |
| `dryFrom` | `{ [streak key] = start }` |
| `items` | `{ [item id] = drops }` |

- **Days:** whole days since 1 January 1970 UTC (`CLOCK_TIME_DATE_MINUTES`), or `0`
  if the clock couldn't be read.
- **Mode keys:** short codes set in each boss file: `n` normal, `h` hard mode, or
  the boss's own, such as `e1000` (Amascut's enrage tier), `r12` (Croesus's unique
  rolls), `hc` (TzKal-Zuk hard mode with checkpoints) or `c3f` (Barrows: `c` and
  the hex bits of the brothers killed).
- **Sums:** values read at each kill that set its rate, added up by mode and day
  (`sums` in `src/bosses.lua`). Arch-Glacor saves `enrage` and `streak`; a day's
  kills use their averages. Saving the values, not the rate, lets rate changes
  re-rate them.
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

[`saved-data.example.json`](saved-data.example.json) is a full record, taken from a
real character with the name changed. Its Vorkath entry: 7 hard mode chests on day
20760, with two spike drops (56079), the last at the 3rd chest. No codex (56068) or
scale (56321) yet.

```json
"vorkath": {
  "kills": { "h": "20760:7" },
  "dryFrom": {
    "56079": { "day": 20760, "at": { "h": { "20760": 3 } } },
    "any": { "day": 20760, "at": { "h": { "20760": 3 } } }
  },
  "items": { "56079": 2 }
}
```

`56079` and `any`: 4 kills dry. `56068` and `56321` have no entry, so they run from
the first chest: 7. A new chest changes only `kills`.

## On disk

The example shows the record as Lua sees it. The game stores it in its plugin
database as JSON, writing every table as a list of `{ "key": ..., "value": ... }`
pairs and every number as a decimal:

```json
[
  { "key": "version", "value": 1.0 },
  { "key": "lastBoss", "value": "barrows" },
  { "key": "bosses", "value": [ { "key": "vorkath", "value": [ ... ] } ] }
]
```

## Size

A saved table entry costs about 100 bytes on disk, and a day of kills adds about 10
characters to a mode's text. One boss with ten uniques played daily for a year is
about 10 KB.

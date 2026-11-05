# Saved data

Boss RNG saves with `PersistentDB`, on this computer only. Every character on the
computer shares it, so each key starts with the character's display name (a new name
starts anew). All-time kill and log counts are read from the game, never saved.

| Key | Holds | Code |
|---|---|---|
| `char:<name>` | `{ version, lastBoss }` | `src/core/tracker.lua` |
| `char:<name>:<boss key>` | `{ version, kills, sums, dryFrom, items }`: that boss's tracked kills, drops and dry streaks | `src/core/tracker.lua`, `src/core/tallies.lua` |

Each boss has its own entry, so entries stay small ([Size](#size)). A kill or drop
saves only that boss's entry, and the character's when `lastBoss` changes.

Every entry has a `version`. An entry of any other version reads as empty and is
replaced at its next save ([Compatibility](compatibility.md#not-built-yet)).

Keys are always text (item ids, days), and numbers come back as decimals (`13.0`).
A sample character's entries are in [`saved-data.example.json`](saved-data.example.json).

## `char:<name>`

`lastBoss`, the boss killed last, gets any shared unique (one collection log count
shared by two bosses). Resetting every boss deletes this entry too, and the next kill
saves it again.

## `char:<name>:<boss key>`

Created when the boss's first kill or drop is tracked. Data Controls on the settings page deletes
one boss's entry (`tracker.Reset`) or every boss's (`tracker.ResetAll`), after a
confirmation. The fields:

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
| no start saved | every kill |
| `{ day, at }` | kills after `day`, plus kills on `day` and day `0` beyond `at` |

`day` is the latest day with kills at the drop (`0` if none), and `at` is
`{ [mode key] = { [day] = n } }` for that day and day `0`. This is exact because
days only go forward. A unique added later has no start saved, so it runs from the
first kill.

### Example

[`saved-data.example.json`](saved-data.example.json) is a character's entries, taken
from a real character with the name changed. Its Vorkath entry: 7 hard mode chests
on day 20760, with two spike drops (56079), the last at the 3rd chest. No codex
(56068) or scale (56321) yet.

```json
"char:ExampleName:vorkath": {
  "version": 1,
  "kills": { "h": "20760:7" },
  "dryFrom": {
    "56079": { "day": 20760, "at": { "h": { "20760": 3 } } },
    "any": { "day": 20760, "at": { "h": { "20760": 3 } } }
  },
  "items": { "56079": 2 }
}
```

`56079` and `any`: 4 chests dry. `56068` and `56321` have no start saved, so they
run from the first chest: 7. A new chest changes only `kills`.

## On disk

The example shows the entries as Lua sees them. The game stores each in its plugin
database as indented JSON, writing every table as a list of `{ "key", "value" }`
pairs and every number as a decimal. The example file's character entry, on disk:

```json
[
	{
		"key" : "version",
		"value" : 1.0
	},
	{
		"key" : "lastBoss",
		"value" : "barrows"
	}
]
```

## Size

The game can't save every size of entry: in the beta client on 4 November 2026, an
entry of 104,350 bytes on disk saved, and one of about 131,000 failed. A failed save
returns false, and the entry already saved stays as it was.

In a boss's entry on disk, each collected unique adds about 50 bytes, each dry streak
start about 340, and each day of kills about 9 per mode. One boss with ten uniques
played daily for a year is about 8 KB. A heavy player's largest entry is about 58 KB
after 5 years ([Caching](../technical/caching.md#cost)).

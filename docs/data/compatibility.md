# Compatibility: changing rates, modes, items and bosses

Saved data holds only kills, drops and streak starts (`saved_data.md`); rates apply
when shown. So most changes go in `src/core/rates/` and boss files, with no data
conversion.

## Rules

- Never rename a boss key, mode key or item id without converting saved
  data: they're keys in it.
- Never rename a rate in `src/core/rates/base.lua` without renaming it in every
  update file. A missing name raises an error; `spec/core/rates_spec.lua` fails if an
  update has a name base lacks.
- A rate of 0 means not on the table that day: those kills don't count toward its
  expected drops or streak (`luck.ItemChances` skips 0). For uniques added later,
  not removed ones.

## Checklist

| Change | Do |
|---|---|
| Rate changes | Add the value to that update's file, by boss key. Earlier kills keep the old rate. |
| New game update | Add `src/core/rates/<name>.lua` returning `{ day = <day>, rates = { ... } }` with only changed values; append `<name>` to `rates.UPDATES` in `src/core/rates.lua`. |
| Unique added | 0 in base, rate in the update file, item and roll in the boss file. |
| Unique removed | Not supported yet; see below. |
| Start counting an item (such as Saradomin's hum at Zilyana) | Add it to the boss file's `items` with its log count, rate in base: counts over every tracked kill, though earlier drops weren't tracked. Or 0 in base and its rate from the plugin update's day. Move it out of the doc's "Not counted". |
| Stop counting a unique | Remove it from `items` and its roll, and list it under the doc's "Not counted". Its saved data stays, unused. |
| New mode | New mode key and kill count var. Streaks span every mode. |
| A kill's rate depends on values read at it (such as Arch-Glacor's enrage and streak) | Save the values as sums, not the rate, so a later rate change still re-rates the kills. |
| Kill count rule changes (such as which brothers a Barrows kill needs) | A dated rule in the boss file, read with each kill's day. Not built: a mode's kill count is fixed by its key today, so `stats.lua` would first pass each kill's day to it, as it does for rolls. The saved facts don't change. |
| Saved facts change format for one boss | A version for that boss: see below. |

Example (not real): Solak gains item 99999 at 1 in 300 on day 21000.

```lua
relic = 0                     -- base.lua, in solak
solak = { relic = 1 / 300 },  -- the update's file
[RELIC] = { log = VARS.log .. "RELIC" }, -- boss file, plus a roll using r.relic
```

Its dry count and expected drops start on day 21000.

## Removing a unique (planned)

The item should vanish: no row, no part in luck on any day. Kills stay.

1. Delete it from the boss file (log entry and roll).
2. Delete its rate from `src/core/rates/`; add any changed rates for other items to
   the update's file.
3. Drop its `items` and `dryFrom` entries the next time the boss's tallies change.
   Until built, they stay saved but unread.

`any` keeps its start even if the removed item set it.

## A version per boss (planned)

The record's `version` resets every boss, so it's only for a change to the whole
saved shape. When one boss's saved facts must change format (such as saving a
value per kill that was saved per run), give that boss its own version:

1. The boss file declares `dataVersion`, and its saved tallies keep the version
   they were written with. A missing version reads as 1, so data saved before this
   is built still loads.
2. On load, tallies behind their boss's version go through the boss file's
   `convert(tallies, from)` if it has one, or start again for that boss only.

Prefer saving facts and interpreting them in code by day, so most changes need
neither.

# Modeling future changes

How to model changes to the game or to Boss RNG without losing or misreading
saved data. Saved data (see `saved_data.md`) holds only kills by mode and day,
drops, and where dry streaks start; every rate is applied when numbers are
shown. So most changes are made in `src/rates/` and boss files, and saved data
needs no conversion.

## Rules that keep saved data valid

- Never rename a boss key, a mode name or an item id: they're keys in saved data.
- Never rename a rate in `src/rates/base.lua` without renaming it in every
  update file (`spec/rates_spec.lua` fails if an update changes a name base
  doesn't have, and reading a missing name raises an error).
- A rate of 0 means the item isn't on the table that day: kills from that day
  don't count toward its expected drops or its dry streak (`luck.ItemChances`
  leaves out chances of 0). It's for uniques added later, not removed ones.

## Jagex changes a rate

Add the new value to that update's file, by boss key. Kills before its day keep
the old rate.

```lua
-- src/rates/late_game_rebalance.lua
solak = { crossbow = 1 / 200 },
```

## Jagex removes a unique

Not supported yet; this is what should happen, and how to do it when it comes up.

**Expected:** an item that leaves a boss's log is gone from Boss RNG entirely:
no row, and no part in luck on any day, past kills included. Luck can change;
that's intended, since the boss can't give it any more. Kills stay.

**How** (example, not a real change: Raksha's Fleeting boots leave its table and log):

1. Delete the boots from the boss file: their log entry and their part of the
   roll. Stats only read a boss's own uniques, so the row and their part in
   luck go with them.
2. Delete their rate from `src/rates/`. If the removal changed the other
   items' rates, add those to the update's file as usual.
3. Clean up saved data: drop the boots' entries from `items` and `dryFrom` the
   next time the boss's tallies change. Until that's built, they stay saved but
   unused, since nothing reads items a boss doesn't have.

The boss's own streak (`any`) keeps its start, even if a pair of boots set it:
only the latest start is saved, so the one before can't be recovered.

## Jagex adds a unique

Example (not a real change): Solak gains a "Grove relic" (item id 99999) at
1 in 300 on day 21000.

1. Base gives it 0, since it wasn't on the table before:
   `solak = { ..., relic = 0 }`.
2. The update gives its rate: `solak = { relic = 1 / 300 }`.
3. The boss file adds the item and a roll reading `r.relic`:
   `[RELIC] = { log = VARS.log .. "RELIC", kind = "unique" }`.

Its streak has no saved start, so it runs from the first tracked kill, but
kills before day 21000 can't drop it (rate 0), so its dry count and expected
drops both start on day 21000.

## Boss RNG starts counting a unique that already dropped

Example: the wiki publishes a rate for Commander Zilyana's hum (today
`kind = "excluded"`, with no rate). Changing it to a unique with its rate in
base counts it over every tracked kill, for expected drops and its dry streak.
Drops of it before that plugin update weren't tracked, so a player who got one
then would read as less lucky with it than they are.

To count it only from the plugin update instead, model it like a new unique: 0
in base, and its rate from the day the plugin update ships. That puts a plugin
date in the rates files, so decide when it comes up. The effect is limited to
that one item's row and its part of the boss's luck.

## Boss RNG stops counting a unique

Change its kind (for example to `excluded`). It leaves the UI and luck. Its
saved drops and streak start stay unused, and would be cleaned up like a
removed unique's (step 3 above).

## A boss gains a mode

Example: a new hard mode with its own kill count. Add a mode with a new name and
kill count var. Its kills are saved under the new name; the boss's streaks run
across every mode, as now.

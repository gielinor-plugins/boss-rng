# Changing bosses, rates and items

How to change a boss, its drop rates or its items without breaking players' saved
data, and what each change does to kills already tracked.

Saved data holds only facts: each boss's kills by mode and day, its drops, and where
each dry streak starts ([Saved data](saved-data.md)). Drop rates and rolls live in
the code and are applied each time stats are shown. So most changes need code only,
and no conversion of saved data.

## What must never change

| Never change | Because | Guarded by |
|---|---|---|
| A boss's `key` | Saved data is keyed by it | `spec/saved_keys_spec.lua` |
| A mode key in a boss's `modes` | Saved kills are keyed by it | `spec/saved_keys_spec.lua` |
| An item id in a boss's `items` | Saved drops and dry streaks are keyed by it | Nothing: item ids are the game's own, so they never need to |
| Barrows' chest key format (`c` and hex bits, in the brothers' order) | Every saved Barrows chest is keyed by it | `spec/saved_keys_spec.lua`, for a sample of keys |
| A rate's name in `src/core/rates/base.lua` | Update files override rates by name | `spec/core/rates_spec.lua` fails if an update names a rate the base lacks; a rate looked up that no file has raises an error |

## Common changes

| Change | What to do | Kills already tracked |
|---|---|---|
| A game update changes rates | Add `src/core/rates/<update>.lua` returning `{ day = days.FromDate(year, month, day), rates = { [boss key] = { changed values only } } }`, and append its name to `rates.UPDATES` in `src/core/rates.lua`. Before the update's date is known, use `day = false`: the file is ignored until it's set. | Keep their old rates. Kills from the update's day use the new ones. |
| A boss gains a unique | Add the item to `items` and a roll using a new rate name. Give the rate 0 in `base.lua` and its real value in the update's file. | Couldn't have dropped it, so it adds nothing to their expected drops or its dry streak. |
| Jagex removes a unique from a boss's drops | Set its rate to 0 in the update's file. Keep the item. | Keep it: past drops and expected drops stay, and from the update's day it stops adding up. |
| Boss RNG starts counting an item the boss always dropped | Add it to `items` and its roll, with its rate in `base.lua`, and move it out of the boss page's Not counted list. | All count toward its expected drops, though drops before this change weren't tracked. To avoid that, use 0 in `base.lua` and its rate from the plugin update's day instead. |
| Boss RNG stops counting an item | Remove it from `items` and its roll, and add it to the boss page's Not counted list. | It drops out of their luck on every day, as if it never counted. Its saved drops and dry streak stay but are never read. |
| A boss gains a mode, such as a hard mode | Add a key to `modes` and its kill count to `killCounts` (`common.NormalAndHard` for a normal and hard pair), and list the key in `spec/saved_keys_spec.lua`. First confirm in game that the new mode has its own kill count var: if it shares one, tell the modes apart with a kill event instead. | Unchanged. Dry streaks span every mode, so they carry on. |
| A kill's rate depends on a value read at the kill (such as Arch-Glacor's enrage) | Save the value as one of the kill event's `sums`, not the rate, and work the rate out from it in `rolls`. | A later rate change still applies to them, since the facts are saved, not the rate. |
| A new boss | Follow [Adding a boss](../development/adding-a-boss.md). | None yet. |

## Example: a boss gains a unique

Solak gains a relic (item 99999) at 1 in 300, in an update on 4 January 2027.

In `src/core/rates/base.lua`, the rate exists but is 0 before the update:

```lua
solak = { grimoire = 1 / 200, crossbow = 1 / 400, stave = 1 / 500, mushroom = 1 / 500, relic = 0 },
```

In the update's file, `src/core/rates/<update>.lua`:

```lua
return {
    day = days.FromDate(2027, 1, 4),
    rates = { solak = { relic = 1 / 300 } },
}
```

In `src/bosses/solak.lua`, the item and its own roll:

```lua
{ chance = r.relic, items = { [RELIC] = 1 } }, -- in rolls(r)
[RELIC] = { log = VARS.log .. "RELIC" }, -- in items
```

Kills before 4 January 2027 can't drop the relic. From that day each kill adds 1/300
to its expected drops, and its dry streak counts only those kills.

## Not built yet

These changes would need code that doesn't exist yet. Prefer saving facts and
working rates out from them by day, so most changes need none of it.

- **A kill count rule changes by date,** such as Akrisae no longer counting toward a
  Barrows kill. Whether a mode is in the kill count (`partial`) is fixed by its key
  today; `stats.lua` would need to pass each kill's day to it, as it already does for
  rates. The saved chest keys record who died, so they'd still be right.
- **The saved shape changes,** for every boss or for one, such as saving per kill
  something now saved per run. That needs `VERSION` in `src/core/tracker.lua`
  raised. Today an entry of any other version reads as empty and is replaced at its
  next save, so raising `VERSION` alone would wipe every player's data. The same
  change must add a converter from every older version, with a spec, and leave any
  entry it can't read untouched. Entries whose format didn't change only need their
  version updated ([Saved data](saved-data.md)).

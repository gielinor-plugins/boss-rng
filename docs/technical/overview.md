# Technical overview

Boss RNG is a RuneScape plugin in plain Lua 5.4, with no build step: the files in
`src/` are what the game runs. This page is the map. For what happens on each game
event, see [Events](events.md).

## How it fits together

```
game events -> game_vars -> tracker -> saved data
                   |            |
                   |            v
                   +-------->  ui -> stats -> panel, window, settings
            (all-time totals)
```

1. **Reading the game.** `game_vars` watches each boss's kill counts and collection
   log counts. It's the only code that reads the game, with its helpers. It reports
   each kill (with its mode, see below) and each drop.
2. **Keeping tallies.** `tracker` adds each kill and drop to the logged-in
   character's tallies, by day, and saves them. Nothing else writes saved data.
3. **Working out luck.** When a view draws, `stats` turns the tallies into luck, dry
   streaks and expected drops, rating each kill at its day's drop rates. The game's
   all-time totals are shown beside them, never used for luck.
4. **Drawing.** `ui` redraws the open views after a change, using the plugin's UI
   library (declared in `plugin.json`).

## Bosses and modes

Each boss is a data file in `src/bosses/`, listed in `src/bosses.lua`, which
documents every field. A boss has:

- **Kill counts** (`killCounts`): the game's kill count varbits. Their sum is the
  all-time kill count shown.
- **Modes** (`modes`): each kind of kill with its own drop rates, under the short
  key its kills are saved as: `n` normal, `h` hard mode, `e1000` an Amascut enrage
  tier, `r12` Croesus's unique rolls, `c3f` a Barrows chest's brothers.
- **Items:** the uniques counted, each with its collection log count varbit.

How a kill finds its mode depends on the boss:

| How kills are counted | Bosses | Where the mode comes from |
|---|---|---|
| Each kill count rise | Most bosses | The kill count names its mode |
| A value read at the kill | Araxxi, Croesus, Kerapac, Arch-Glacor, TzKal-Zuk's hard mode, Barrows, elite dungeon group kills | The kill event (`src/core/kill_events.lua`) |
| Loot claimed from a chest | Amascut, Sanctum of Rebirth | The claim (`src/core/claims.lua`) |
| A chest opened from the backpack | Zemouregal & Vorkath | The container (`src/core/containers.lua`) |

Drop rates live apart from the boss files, in `src/core/rates/`: one file per game
update, each with the day it went live. A kill is rated at the rates of its own
day, so a later rate change never rewrites past luck.

## Modules

| File | Does |
|---|---|
| `main.lua` | Starts the UI and `game_vars`; stops both in `PluginShutdown`. |
| `src/bosses.lua`, `src/bosses/` | The supported bosses as data, and the format they follow. |
| `src/core/game_vars.lua` | Wires every boss to the game; reports kills, drops and all-time totals. |
| `src/core/var_watch.lua` | Watches var changes (`VarTransmit`), queues rises for the next tick, and waits out the login sync. |
| `src/core/kill_events.lua` | Kills told apart by values read at the kill. |
| `src/core/claims.lua` | Kills counted by loot claimed from a chest. |
| `src/core/containers.lua` | Kills counted by loot chests opened from the backpack. |
| `src/core/piles.lua` | The player's own loot piles that land at a kill. |
| `src/core/tracker.lua` | Each character's tallies: adding kills and drops, saving, resets. |
| `src/core/tallies.lua` | The tallies' shape, dry streaks, and their saved form. |
| `src/core/stats.lua` | Tallies to luck, dry streaks and expected drops. |
| `src/core/luck.lua` | The probability math ([Luck math](luck-math.md)). |
| `src/core/rates.lua`, `src/core/rates/` | Drop rates by game update and day. |
| `src/ui.lua` | When the views draw ([UI](ui.md)). |
| `src/ui/` | The panel, details window, settings page and the text they show. |
| `src/utils/` | Small helpers with no boss knowledge (bits, days, errors, tables). |

## Ground rules

- **Only visible information.** Kill counts, collection log counts and values the
  game shows during a fight. Hidden values, such as bad luck mitigation or loot
  waiting to be claimed, are never read.
- **No actions, no network.** The plugin sends no inputs, adds no menu entries,
  requests no permissions and makes no internet requests.
- **Errors stay contained.** Kill and drop reports, and drawing each view, run
  through `src/utils/safe.lua`, so one error can't stop the rest; each distinct
  error is printed once to the console.
- **Saved keys never change.** Boss keys and mode keys are saved per character
  ([Compatibility](../data/compatibility.md)), and `spec/saved_keys_spec.lua`
  fails if one stops loading.

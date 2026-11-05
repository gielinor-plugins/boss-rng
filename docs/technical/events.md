# Events

Every game event Boss RNG subscribes to, and what each one leads to. Boss RNG
subscribes when the plugin starts and unsubscribes everything in `PluginShutdown`
(`main.lua`). Each `game_vars` handler runs inside `safe.Call`
(`src/utils/safe.lua`), so an error in one is printed once and can't stop the others.

## Subscriptions

| Event | Subscribed by (ref) | What happens |
|---|---|---|
| `VarTransmit` | `game_vars` (`bossrng_game_vars`) | A watched kill count, collection log count or kill event var that rose is queued for the next logic tick. Values a kill event reads at the kill are kept up to date, and loot waiting for a claim is followed. |
| `Logic` (50 a second) | `game_vars` | Last tick's queued rises are reported, in a fixed order: values that rose, then kills, then drops. Once the game is ready, all-time totals can be read and the views redraw. |
| `GameStateChanged` | `game_vars` | Entering the game starts a 5 second wait before vars are trusted, so the login sync isn't taken for kills. Leaving the game stops trusting them. |
| `InventoryAdded`, `InventoryUpdated` | `game_vars` | Vorkath: a chest leaving the backpack in the same tick its reward window opens is one chest opened. |
| `ObjStackEntityAdded`, `ObjStackEntityChanged` | `game_vars` | Kerapac: the player's own loot piles that land with a kill. Piles the game marks as another player's are ignored. |
| `ContentLayerReady` | `ui` (`bossrng_ui`) | The game gave the ribbon panel a fresh layer (opened, restored or resized): the panel draws. |
| `SettingsLayerReady` | `ui` | The settings page opened: it draws. |
| `Logic`, for one tick | `ui` (`bossrng_ui_redraw`) | A redraw asked for during a change happens on the next tick, once however many changes asked for it, then unsubscribes. |

Each change is reported on the next logic tick, a fiftieth of a second later, rather
than as it arrives. A kill count and the collection log count of the drop it brought
can arrive in either order within one game tick (at Kree'arra, the drop came first),
so waiting lets every kill be counted before its drop. It also lets a kill event
read values that changed in the kill's tick, such as the players in an elite
dungeon.

Tests in game support this. One server update's events can be handled across two
logic ticks, but in 75 kills at 8 bosses, everything a kill is counted from (kill
counts, collection log counts, a chest's waiting loot, values read at the kill, and
the player's loot piles) arrived in the same logic tick. Only inventory updates came
a tick later. Reporting on `ServerLogic` instead, which the client fires as it
finishes a server packet, was considered and dropped. It usually came in the same
logic tick as an update's last event, but sometimes an event arrived after one and
the next didn't come for about 30 logic ticks, a full 600 ms game tick. So it
doesn't reliably mark the end of an event's update, and waiting for it would delay
some reports by a game tick. A drop whose collection log count arrives a logic tick
before its kill count hasn't been seen; it would be counted before its kill, or not
at all if it's the boss's first kill since logging in.

## From a kill to the screen

1. **The kill.** The boss's kill count rises (`VarTransmit`), and `var_watch` queues
   the rise, unless it's within 5 seconds of login or bigger than kills could be.
   Bosses counted by a claim or a chest start there instead.
2. **Reported.** On the next logic tick, the kill is reported with the game's date
   and its mode, the kind of kill whose drop rates it uses. For most bosses the kill
   count itself names the mode; for the rest it comes from a value read at the kill,
   the claim or the chest (see [Technical overview](overview.md#bosses-and-modes)).
3. **Tracked.** `tracker.AddKills` adds it to the character's tallies and saves.
4. **Redraw asked.** Saving calls the UI's listener, which redraws on the next tick.
5. **Drawn.** The panel and the details window redraw only if they're open and
   what they show changed. `stats` reruns only when its inputs changed
   ([Caching](caching.md)).

A drop takes the same path, through `tracker.AddDrops`, which ends that unique's
dry streak and the boss's.

## When a drop counts

A collection log count rising is a drop only:

- **after a kill of that boss this session.** The game can resend collection log
  counts long after login, so a rise with no kill isn't a drop.
- **within 10 seconds of a claim,** for bosses whose loot waits until you claim it
  (Arch-Glacor's hard mode streak).
- **for the boss killed last,** for a unique whose collection log count two bosses
  share (the Shard of Genesis Essence: Amascut and Nakatra).

## Other refreshes

Without any tally changing, the views also redraw:

- once vars can be trusted after login, so the all-time totals appear;
- when a kill count rises at a boss whose kills are counted at a chest or claim
  (Amascut, Sanctum of Rebirth, Vorkath), so its all-time kills update right away.

## UI callbacks

The views use the UI library's components, which handle their own hooks. Boss
RNG's callbacks:

| Element | Result |
|---|---|
| Boss dropdown (panel and window) | That boss is shown; redraws next tick. |
| View details button (panel) | Opens the details window, or redraws it. |
| Luck and Info tabs (window) | Remembers the tab for the next redraw. |
| Window close | Remembers the window's position until the plugin stops. |
| Reset buttons (settings) | A confirmation, then `tracker.Reset` or `tracker.ResetAll`. |

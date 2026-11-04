# Events

Every game event Boss RNG subscribes to, and what each one leads to. Boss RNG
subscribes when the plugin starts and unsubscribes everything in `PluginShutdown`
(`main.lua`).

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

Changes are reported a tick late on purpose: a kill and its drop can arrive in
either order within a tick, so waiting lets kills always be counted before the
drops they brought.

## From a kill to the screen

1. **The kill.** The boss's kill count varbit rises (`VarTransmit`). `var_watch`
   queues it, unless it's in the 5 seconds after login or rose by more than a
   kill could.
2. **Next tick.** The kill is reported with its mode: straight from the kill count,
   or from a kill event, claim or container (see the table in
   [Technical overview](overview.md#bosses-and-modes)), and with the game's date.
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

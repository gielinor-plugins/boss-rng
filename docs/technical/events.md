# Events

Every game event Boss RNG subscribes to, and what each one leads to. Boss RNG
subscribes when the plugin starts and unsubscribes everything in `PluginShutdown`
(`main.lua`). Each `game_vars` handler runs inside `safe.Call`
(`src/utils/safe.lua`), so an error in one is printed once and can't stop the others.

## Subscriptions

| Event | Subscribed by (ref) | What happens |
|---|---|---|
| `VarTransmit` | `game_vars` (`bossrng_game_vars`) | A watched kill count, collection log count or kill event var that rose is queued for the next batch (below). Values a kill event reads at the kill are kept up to date, and loot waiting for a claim is followed. |
| `Logic` (50 a second) | `game_vars` | Once 2 logic ticks pass with no new event Boss RNG watches, the queued changes are reported as a batch, in a fixed order: values that rose, then kills (from kill counts, kill events, claims and chests opened), then drops. Once the game is ready, all-time totals can be read and the views redraw. |
| `GameStateChanged` | `game_vars` | Entering the game starts a 5 second wait before vars are trusted, so the login sync isn't taken for kills. Leaving the game stops trusting them. |
| `InventoryAdded`, `InventoryUpdated` | `game_vars` | Vorkath: a chest leaving the backpack in the same batch as its reward window opening is one chest opened. |
| `ObjStackEntityAdded`, `ObjStackEntityChanged` | `game_vars` | Kerapac: the player's own loot piles that land with a kill. Piles the game marks as another player's are ignored. |
| `ContentLayerReady` | `ui` (`bossrng_ui`) | The game gave the ribbon panel a fresh layer (opened, restored or resized): the panel draws. |
| `SettingsLayerReady` | `ui` | The settings page opened: it draws. |
| `Logic`, for one tick | `ui` (`bossrng_ui_redraw`) | A redraw asked for during a change happens on the next tick, once however many changes asked for it, then unsubscribes. |

Changes are reported in batches rather than as they arrive: once 2 logic ticks (a
twenty-fifth of a second) pass with no new event Boss RNG watches, everything since
the last batch is reported. A kill count and the collection log count of the drop it
brought can arrive in either order (at Kree'arra and the Twin Furies, the drop came
first), so a batch reports kills before drops. A kill event also reads values that
changed with the kill, such as the players in an elite dungeon or Kerapac's loot
piles.

Waiting for quiet ticks, rather than reporting on the next one, covers updates the
client splits. In tests in game, one server update's events were sometimes handled
across two logic ticks: in about 90 kills at 9 bosses, ground loot and vars came
first and inventory updates a tick later. What a kill is counted from always arrived
together, but nothing promises that, and a split between a drop's collection log
count and its kill count, or Kerapac's piles and its kill count, would otherwise
count them wrong. `ServerLogic`, which the client fires as it finishes a server
packet, isn't used instead: an event sometimes arrived just after one, with the next
a full 600 ms game tick later.

## From a kill to the screen

1. **The kill.** The boss's kill count rises (`VarTransmit`), and `var_watch` queues
   the rise, unless it's within 5 seconds of login or bigger than kills could be.
   Bosses counted by a claim or a chest start there instead.
2. **Reported.** In the next batch, the kill is reported with the game's date and
   its mode, the kind of kill whose drop rates it uses. For most bosses the kill
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
- **after a kill since the last skipped claim** of that boss, or of a boss sharing a
  unique with it (Amascut and Sanctum of Rebirth share the Shard of Genesis Essence).
  A claim's uniques come with or after it, so a skipped claim's unique isn't counted.
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

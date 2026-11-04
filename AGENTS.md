# AGENTS.md

Instructions for AI coding agents working on Boss RNG. People can start from
[docs/README.md](docs/README.md), which covers the same ground.

## The project

Boss RNG is a RuneScape 3 plugin in Lua 5.4. It counts boss kills and unique drops
as they happen and shows how lucky the player has been against published drop
rates. Read [docs/technical/overview.md](docs/technical/overview.md) first: it maps
every module. The boss data format is documented at the top of `src/bosses.lua`.

## Commands

- Tests: `busted` from the project root. Run them after every change.
- Lint: `luacheck .` (settings in `.luacheckrc`) must pass.
- Beta client: `tools/sync.sh` copies the plugin into the client's `dev_plugins`
  folder (`BOSS_RNG_DEV_DIR` overrides the target). The developer then reloads it
  by running `prl boss_rng` in the game console. Agents can't run game commands.

## Jagex's plugin guidelines

The rules below summarize Jagex's
[plugin guidelines](https://developer.runescape.com/rs/submission/guidelines.html)
as of 2 November 2026. The guidelines may change: confirm against the current
version before adding a feature. Where they differ, the current guidelines apply.

- **No hidden information.** Never read a value that would reveal a reward
  before the game shows it to the player, or hidden mechanics such as bad luck
  mitigation, even to log or test.
- **Never act for the player.** No inputs to the game, no menu entries that send
  actions to the server, no automation.
- **No information about other players** is exported.
- **No code from other plugins.** Copying another developer's plugin is
  prohibited. On AI tools, the guidelines state:

  > You must not upload to any AI model any code or documentation that has not
  > been explicitly provided to you with the license to do so. The API
  > documentation contained on this website and all examples contained within
  > are permissible. However, any plugins created by other developers or the
  > documentation of those plugins is owned and licensed by their creator, and
  > you cannot upload that content to any AI model unless you have requested and
  > been granted permission by the license holder.

- **Readable code.** A moderator must be able to follow it quickly: plain,
  commented Lua. No transpiled, minified or obfuscated code. AI-written code is
  allowed only once the developer has reviewed and understood every line.

## Project rules

- **Saved keys never change.** Boss keys, mode keys and item ids are saved per
  character. Renaming one loses players' data. `spec/saved_keys_spec.lua` lists
  every boss and mode key that can be saved, and fails if one stops loading. Only
  add to it. See `docs/data/compatibility.md` before changing rates, modes, items
  or bosses.
- **Credit drop rates.** Rates come from the RuneScape Wiki (CC BY-NC-SA 3.0).
  Each doc page, and each boss file or the shared file it uses, names the source
  and the date it was checked.
- **Use dependencies only through their public API.**
- **Data stays on the device.** The plugin requests no permissions (no HTTP or
  chat access). Keep it that way.

## Testing

See [docs/development/testing.md](docs/development/testing.md). In short: specs
test behavior, not data; add or update one with every change in behavior; anything
the mock can't show is confirmed in game by the developer, through dev probes in
`dev/` that follow the same rules as the plugin.

## Adding a boss

Follow [docs/development/adding-a-boss.md](docs/development/adding-a-boss.md).

## Keeping the docs current

Update the docs in the same commit as the change:

| Change | Update |
|---|---|
| A boss added | Its page in `docs/bosses/`, the table in `docs/bosses/README.md`, `CHANGELOG.md` |
| A boss's rates, counting or vars | Its page in `docs/bosses/` (rates, how kills are counted, vars read, tests) |
| A game update's rates | The affected boss pages, `CHANGELOG.md` |
| A module added, removed or renamed | `docs/technical/overview.md` |
| An event subscribed, or what one does | `docs/technical/events.md` |
| When views draw, or a new view | `docs/technical/ui.md` |
| The luck math | `docs/technical/luck-math.md` |
| A new cache | `docs/technical/caching.md` |
| The saved shape | `docs/data/saved-data.md` and `saved-data.example.json`, `VERSION` in `src/core/tracker.lua` |
| What's read or saved | `docs/guide/privacy.md`, the Data Protection section of `docs/release/modio-listing.md` |
| What players see | `docs/guide/how-it-works.md` |
| Tools or setup | `docs/development/setup.md` |

## Style and typography

- Concise, conventional Lua. Build only what is needed now.
- Format with [StyLua](https://github.com/JohnnyMorganz/StyLua) (`.stylua.toml`):
  `stylua .` before committing, and `stylua --check .` must pass.
- Comments say what something is for or why, not what the next line does.
- Text players see, docs and comments describe Boss RNG and RuneScape on their
  own terms, clearly enough for a new player to follow.
- American English.
- "Boss log" for kill counts, "collection log" for drops and their counts.
- Use commas, colons, parentheses or separate sentences instead of em dashes and
  en dashes. Write ranges as "1 to 3".

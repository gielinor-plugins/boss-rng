# AGENTS.md

Instructions for AI coding agents working on Boss RNG. For people, the README's
Development section covers the same setup.

## The project

Boss RNG is a RuneScape 3 plugin in Lua 5.4. It counts boss kills and unique drops
as they happen and shows how lucky the player has been against published drop
rates. See the README's Development section for the folder layout; the boss data
format is documented at the top of `src/bosses.lua`.

## Commands

- Tests: `busted` from the project root. Run them after every change.
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
  character. Renaming one loses players' data. See `docs/data/compatibility.md`
  before changing rates, modes, items or bosses.
- **Credit drop rates.** Rates come from the RuneScape Wiki (CC BY-NC-SA 3.0).
  Each doc page, and each boss file or the shared file it uses, names the source
  and the date it was checked.
- **Use dependencies only through their public API.**
- **Data stays on the device.** The plugin requests no permissions (no HTTP or
  chat access). Keep it that way.

## Testing

- Tests live in `spec/`, mirroring `src/`, and run without the game:
  `spec/mock_api.lua` stands in for the game API (events, vars, saved data).
- Add or update tests with every change in behavior.
- Anything the mock can't show (when a var changes, what it holds) is confirmed
  in game by the developer.

## Adding a boss

1. Add `src/bosses/<key>.lua` and list it in `src/bosses.lua`.
2. Add its rates to `src/core/rates/base.lua`, by boss key.
3. Add `docs/bosses/<key>.md`: drop rates, how kills are counted, vars read, in-game
   tests, and what isn't counted, with the boss log ids of items left out of the
   boss file. Copy the layout of an existing page.
4. Add a case to `spec/bosses_spec.lua`, plus tests for any special counting.
5. Confirm every var in game before relying on it: when it changes relative to
   the kill, and that it holds what its name suggests. Record what was seen in the
   doc page's Tests section.

## Style and Typography

- Concise, conventional Lua. Build only what is needed now.
- Format with [StyLua](https://github.com/JohnnyMorganz/StyLua) (`.stylua.toml`):
  `stylua .` before committing, and `stylua --check .` must pass.
- Comments say what something is for or why, not what the next line does.
- Text players see, docs and comments describe Boss RNG and RuneScape on their
  own terms, clearly enough for a new player to follow.
- American English.
- Use commas, colons, parentheses or separate sentences instead of em dashes and
  en dashes. Write ranges as "1 to 3".

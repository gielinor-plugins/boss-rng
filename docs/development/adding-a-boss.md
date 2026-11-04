# Adding a boss

1. **Confirm the vars in game first.** For each kill count and collection log count
   (and any value a kill's rate depends on), check when it changes relative to the
   kill and that it holds what its name suggests ([Testing](testing.md#in-game)).
2. **Boss file.** Add `src/bosses/<key>.lua` and list it in `src/bosses.lua`, whose
   header documents every field. Start from a boss that's counted the same way (see
   the table in [Supported bosses](../bosses/README.md)). The key is saved, so pick
   it once: short, lowercase, no spaces.
3. **Rates.** Add the boss's rates to `src/core/rates/base.lua`, by boss key, from
   the RuneScape Wiki. Name the source and the date you checked it in the boss
   file's header.
4. **Specs.** Add a case to `spec/bosses_spec.lua` checking a few rates against the
   wiki, tests for any special counting (a kill event, claim or container), and the
   boss and mode keys to `spec/saved_keys_spec.lua`.
5. **Docs.** Add `docs/bosses/<key>.md` following
   [How to read a boss page](../bosses/README.md#how-to-read-a-boss-page), and add
   the boss to the tables in `docs/bosses/README.md`.
6. **Changelog.** Add a line under Unreleased in `CHANGELOG.md`.

Changing an existing boss's rates, modes or items instead? See
[Compatibility](../data/compatibility.md) first.

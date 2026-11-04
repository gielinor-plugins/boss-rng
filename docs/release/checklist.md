# Release checklist

Steps for each release on mod.io, from Jagex's
[submission process](https://developer.runescape.com/rs/submission/process.html).
Check that page for changes before each release.

## The code

- [ ] Drop rates are current. For a game update, add its rates file in
      `src/core/rates/` with the day it went live ([Compatibility](../data/compatibility.md)).
- [ ] `src/core/rates/late_game_rebalance.lua`: its day is assumed to be 30 November
      2026. Confirm the day and rates against the patch notes.
- [ ] `busted`, `stylua --check .` and `luacheck .` pass.
- [ ] Tried in the beta client: the panel, the details window, the settings page,
      and a kill at a boss.
- [ ] If the saved shape changed, `VERSION` in `src/core/tracker.lua` is raised,
      with a converter from every older version
      ([Compatibility](../data/compatibility.md#not-built-yet)).

## The version

- [ ] `plugin.json`'s `version` is raised, numbers and dots only, following
      semantic versioning: the last number for fixes, the middle for features.
- [ ] `CHANGELOG.md`'s Unreleased section is renamed to the version, describing the
      changes since the last approved version.

## The upload

- [ ] `tools/package.sh` builds `dist/boss_rng-<version>.zip`, with `main.lua` and
      `plugin.json` at its top level.
- [ ] On mod.io, upload the zip as a new file of the same plugin, with the same
      version and its changelog. Select Windows, Linux and Mac.
- [ ] The listing matches [mod.io listing](modio-listing.md), including the
      required sections.
- [ ] The UI library in `plugin.json`'s `requiredDependencies` is also added as a
      dependency on mod.io.

## First release only

- [ ] Create the mod.io listing early, to check the name is free.
- [ ] A listing image, 16:9 and at least 512 x 288.
- [ ] Tags for the plugin's categories. No permission tags are needed, since it
      requests none.
- [ ] Update the mod.io link in `README.md` to the plugin's page.

## During moderation

Once a moderator starts the review, don't change the mod.io listing or files until
they say so. Work in the repository carries on as normal.

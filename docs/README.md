# Boss RNG documentation

## For players

- [How Boss RNG works](guide/how-it-works.md): what the panel and window show, and
  what's counted
- [Supported bosses](bosses/README.md): every boss, how its kills are counted, and
  a page for each
- [Your data and privacy](guide/privacy.md): what's read, what's saved, and how to
  delete it

## Technical

For reviewers and developers.

- [Technical overview](technical/overview.md): how the plugin fits together, and
  each module
- [Events](technical/events.md): every game event subscribed to, and what it leads to
- [UI](technical/ui.md): the views and when they draw
- [Luck math](technical/luck-math.md): how luck, expected drops and dry streaks are
  worked out
- [Caching](technical/caching.md): what's kept in memory, and what it saves

## Data

- [Saved data](data/saved-data.md): what's saved and its format, with a
  [sample](data/saved-data.example.json)
- [Compatibility](data/compatibility.md): changing rates, modes, items or bosses
  without breaking players' saved data

## Development

- [Setup](development/setup.md): the repository, tools, and running in the beta
  client
- [Testing](development/testing.md): the specs, and what's checked in game
- [Adding a boss](development/adding-a-boss.md)

## Releasing

- [Release checklist](release/checklist.md)
- [mod.io listing](release/modio-listing.md): the page text, with Jagex's required
  sections

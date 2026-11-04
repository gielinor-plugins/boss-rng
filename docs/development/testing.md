# Testing

## The specs

Tests live in `spec/`, in the same folders as `src/`, and run without the game:
`spec/mock_api.lua` stands in for the parts of the game API Boss RNG uses (events,
vars, inventories and saved data). Run `busted` from the project root.

- **Test behavior, not data.** A spec checks what the code does with its input: a
  kill event picks the right mode, a rate comes out as the wiki gives it, a login
  resend isn't taken for a kill. It doesn't restate a boss file's var names or
  labels, which would only fail when someone edits them on purpose.
- **Every change in behavior** adds or updates a spec.
- **Saved keys** are listed in `spec/saved_keys_spec.lua`. Renaming or dropping a
  boss key or mode key fails it. Only ever add to that list.
- **Every boss** gets the format checks in `spec/bosses_spec.lua` automatically, and
  a case there checking a few of its rates against the wiki.

## In game

The mock can't show what the game really sends: when a var changes relative to the
kill, whether it holds what its name suggests, or which inventories open. Those are
confirmed in game before Boss RNG relies on them, and each boss's page records what
was seen in its Tests section.

Tests in game use dev probes: small read-only modules that log what the game sends.
They live in `dev/`, which is never committed or shipped. `tools/sync.sh` copies them
to the beta client and hooks them in for that copy only.

Probes follow the same rules as the plugin: they never read hidden values (such as
bad luck mitigation or loot waiting to be claimed), even to log them, and never act
in the game.

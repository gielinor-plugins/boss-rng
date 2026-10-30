# Corporeal Beast

How Boss RNG counts your Corporeal Beast kills. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/Corporeal_Beast)
(CC BY-NC-SA 3.0).

## Drop rates

Each kill gives one drop, to one player.

- **Sigils:** since the 20 July 2026 update, a 1 in 256 sigil table, for one of
  the four sigils evenly (1 in 1,024 each). Before, it was 1 in 512, with the
  spectral sigil 2/5 of it (1 in 1,280) and the arcane, elysian and divine 1/5
  each (1 in 2,560).
- **Holy elixir:** 3 in 512 (about 1 in 171).

## How Boss RNG counts your kills

- **Tracked kills** are all after the July 2026 change, so they use today's
  rates.
- **Untracked kills:** your kill count can't say when they were, so you choose
  the share from before the change on the settings page (Plugin Hub > Manage >
  Boss RNG settings). Those kills use the old sigil rates. Untracked kills are
  ones Boss RNG didn't record: from before you installed it, while it was off,
  or on another device.
- **Groups:** a kill's drop goes to one player, and your kill count doesn't say
  who you killed with. So Boss RNG assumes every kill was solo, and the "i" says
  so. If you often kill in groups, your luck reads lower than it is.
- **The holy elixir** also drops from other monsters, but players don't hunt it
  there, so it's counted.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_CORPBEAST` | Your Corporeal Beast kill count. |
| `ITEMLOG_ITEM_CORP_<ITEM>` | Your boss log count for each unique: `SIGIL_SPECTRAL`, `SIGIL_ARCANE`, `SIGIL_ELYSIAN`, `SIGIL_DIVINE` and `HOLY_ELIXIR`. |

## Not counted

- **Corporeal Beast's head** (a boss trophy, 1 in 500): it isn't on the
  collection log, so there's no count to read.
- **Spirit shield:** a common drop from other monsters too.
- **Corporeal puppy** (pet): pets aren't counted.

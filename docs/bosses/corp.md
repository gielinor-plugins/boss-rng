# Corporeal Beast

Source: [RuneScape Wiki](https://runescape.wiki/w/Corporeal_Beast) (CC BY-NC-SA 3.0), checked 28 October 2026.

## Drop rates

Each kill gives one drop, to one player.

| Item | Since 20 July 2026 | Before |
|---|---|---|
| Sigil table | 1 in 256, one of four evenly | 1 in 512 |
| Spectral sigil | 1 in 1,024 | 1 in 1,280 (2/5 of the table) |
| Arcane, elysian, divine sigil | 1 in 1,024 each | 1 in 2,560 each (1/5) |

Holy elixir: 3 in 512 (about 1 in 171).

## How kills are counted

- Boss RNG came out after the July 2026 change, so every tracked kill uses
  today's rates.
- Assumed solo (the Info tab says so): a drop goes to one player and the kill
  count doesn't say who you killed with, so group killers' luck reads low.
- The holy elixir also drops elsewhere, but players don't hunt it there, so it's
  counted.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_CORPBEAST` | Kill count. |
| `ITEMLOG_ITEM_CORP_<ITEM>` | Boss log count each: `SIGIL_SPECTRAL`, `SIGIL_ARCANE`, `SIGIL_ELYSIAN`, `SIGIL_DIVINE`, `HOLY_ELIXIR`. |

## Not counted

- **Corporeal Beast's head** (boss trophy, 1 in 500): not on the collection log.
- **Spirit shield:** a common drop from other monsters too.
- **Corporeal puppy** (pet): pets aren't counted.

| Boss log item | Id |
|---|---|
| Spirit shield | 13734 |
| Corporeal puppy | 33812 |

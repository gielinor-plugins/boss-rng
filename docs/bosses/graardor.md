# General Graardor

Source: [RuneScape Wiki](https://runescape.wiki/w/General_Graardor) (CC BY-NC-SA 3.0), checked 27 October 2026.

## Drop rates

Each kill has a 1 in 64 roll at the unique table, which gives one item at random.
Only if that misses is there a 1 in 512 hilt roll, so a kill gives at most one.
Hard mode has the same rates.

| Item | Per kill |
|---|---|
| Bandos helmet, chestplate, tassets, gloves, boots, warshield | about 1 in 384 each |
| Hilt | about 1 in 520 (63/64 x 1/512) |

## How kills are counted

- Assumed solo (the Info tab says so): the kill count doesn't say who you killed
  with, and group kills share drops, so group killers' luck reads low.
- Normal and hard mode kill counts are both counted.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_GWD_GRAARDOR` | Normal mode kill count. |
| `BSLAY_KILLS_GWD_GRAARDOR_HARDMODE` | Hard mode kill count. |
| `ITEMLOG_ITEM_GWD_BANDOS_<PIECE>` | Boss log count each: `HEAD`, `BODY`, `LEGS`, `HANDS`, `FEET`, `SHIELD`, `HILT`. |

## Not counted

- **General Graardor's head** (boss trophy, 1 in 500): not on the collection log.
- **Godsword shards:** a table every God Wars boss shares.
- **Warpriest set:** also drops from the bodyguards and the god's other monsters.
- **The Glory of General Graardor** (lore) and **General Awwdor** (pet): lore and pets aren't counted.

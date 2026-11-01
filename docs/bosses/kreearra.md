# Kree'arra

Source: [RuneScape Wiki](https://runescape.wiki/w/Kree%27arra) (CC BY-NC-SA 3.0), checked 27 October 2026.

## Drop rates

Each kill has a 1 in 64 roll at the unique table, which gives one item at random.
Only if that misses is there a 1 in 512 hilt roll, so a kill gives at most one.
Hard mode has the same rates.

| Item | Per kill |
|---|---|
| Armadyl helmet, chestplate, chainskirt, gloves, boots, buckler | about 1 in 384 each |
| Hilt | about 1 in 520 (63/64 x 1/512) |

## How kills are counted

- Hilt roll assumed to work like Graardor's and Zilyana's: the wiki doesn't say
  for this boss, and the generals share one drop system.
- Assumed solo (the "i" says so): the kill count doesn't say who you killed
  with, and group kills share drops, so group killers' luck reads low.
- Normal and hard mode kill counts are both counted.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_GWD_KREEARRA` | Normal mode kill count. |
| `BSLAY_KILLS_GWD_KREEARRA_HARDMODE` | Hard mode kill count. |
| `ITEMLOG_ITEM_GWD_ARMADYL_<PIECE>` | Boss log count each: `HEAD`, `BODY`, `LEGS`, `HANDS`, `FEET`, `SHIELD`, `HILT`. |

## Not counted

- **Kree'arra's head** (boss trophy, 1 in 500): not on the collection log.
- **Godsword shards:** a table every God Wars boss shares.
- **Warpriest set:** also drops from the bodyguards and the god's other monsters.
- **Armadyl lore book** and **Chick'arra** (pet): lore and pets aren't counted.

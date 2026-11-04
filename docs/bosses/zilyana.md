# Commander Zilyana

Source: [RuneScape Wiki](https://runescape.wiki/w/Commander_Zilyana) (CC BY-NC-SA 3.0), checked 27 October 2026.

## Drop rates

Each kill has a 1 in 64 roll at the unique table, which gives one entry at
random. Only if that misses is there a 1 in 512 hilt roll, so a kill gives at
most one. Hard mode has the same rates.

| Item | Per kill |
|---|---|
| Saradomin sword; Saradomin's whisper, hiss, murmur | 1 in 320 each |
| Armadyl crossbow, main hand or off-hand (one entry split evenly) | 1 in 640 each |
| Hilt | about 1 in 520 (63/64 x 1/512) |

## How kills are counted

- Assumed solo (the Info tab says so): the kill count doesn't say who you killed
  with, and group kills share drops, so group killers' luck reads low.
- Normal and hard mode kill counts are both counted.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_GWD_ZILYANA` | Normal mode kill count. |
| `BSLAY_KILLS_GWD_ZILYANA_HARDMODE` | Hard mode kill count. |
| `ITEMLOG_ITEM_GWD_SARA_<ITEM>` | Collection log count each: `SWORD`, `CROSSBOW`, `CROSSBOW_OFFHAND`, `AMULET_MELEE` (whisper), `AMULET_MAGIC` (hiss), `AMULET_RANGED` (murmur), `HILT`. |

## Not counted

- **Zilyana's wings** (boss trophy, 1 in 500): not on the collection log.
- **Saradomin's hum:** the wiki lists it as very rare with no rate, so there's
  nothing to compare to.
- **Godsword shards:** a table every God Wars boss shares.
- **Warpriest set:** also drops from the bodyguards and the god's other monsters.
- **Zilyana's Notes** (lore) and **Commander Miniana** (pet): lore and pets are
  never counted.

| Collection log item | Id |
|---|---|
| Saradomin's hum (log count `ITEMLOG_ITEM_GWD_SARA_AMULET_NECROMANCY`) | 61117 |
| Godsword shard 1 | 11710 |
| Godsword shard 2 | 11712 |
| Godsword shard 3 | 11714 |
| Warpriest of Saradomin helm | 28767 |
| Warpriest of Saradomin cape | 28770 |
| Warpriest of Saradomin body | 28761 |
| Warpriest of Saradomin legs | 28764 |
| Warpriest of Saradomin gloves | 28755 |
| Warpriest of Saradomin boots | 28758 |
| Zilyana's Notes | 25040 |
| Commander Miniana | 33807 |

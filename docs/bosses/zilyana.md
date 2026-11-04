# Commander Zilyana

Source: [RuneScape Wiki](https://runescape.wiki/w/Commander_Zilyana) (CC BY-NC-SA 3.0), checked 27 October 2026; changes from Jagex's [Late-Game Rebalance](https://secure.runescape.com/m=news/late-game-rebalance-design-preview).

## Drop rates

Each kill has a 1 in 64 roll at the unique table, which gives one entry at
random. Only if that misses is there a 1 in 512 hilt roll, so a kill gives at
most one. Hard mode has the same rates.

| Item | Now | From the Late-Game Rebalance |
|---|---|---|
| Saradomin sword; Saradomin's whisper, hiss, murmur | 1 in 320 each | 1 in 320 each |
| Armadyl crossbow, main hand or off-hand | 1 in 640 each (one entry split evenly) | 1 in 320 each |
| Hilt | about 1 in 520 (63/64 x 1/512) | 1 in 384 |

The rebalance doesn't say if a kill can still give only one table item; assumed yes.

## How kills are counted

- Normal and hard mode kills are both counted, and assumed solo
  ([Shared assumptions](README.md#shared-assumptions)).

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

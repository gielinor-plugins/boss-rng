# The Twin Furies

Source: [RuneScape Wiki](https://runescape.wiki/w/The_Twin_Furies) (CC BY-NC-SA 3.0), checked 27 October 2026.

## Drop rates

Each kill rolls one table for the Crest of Zamorak, Blade of Nymora, Blade of
Avaryss or a dormant anima core piece, every item at the same rate. Only if that
misses is there a roll for Zamorakian essence.

| Item | Normal | Hard mode |
|---|---|---|
| Each table item | 1 in 256 | 1 in 179 |
| Zamorakian essence | 1 in 64 | 1 in 44 |

## How kills are counted

- Assumed solo (the Info tab says so): the kill count doesn't say who you killed
  with, and group kills share drops, so group killers' luck reads low.
- Normal and hard mode kill counts are both counted.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_TWINDEMONS` | Normal mode kill count. |
| `BSLAY_KILLS_TWINDEMONS_HARDMODE` | Hard mode kill count. |
| `ITEMLOG_ITEM_GWD2_ZAMORAK_<ITEM>` | Collection log count each: `CREST`, `WEAPON` (Nymora), `WEAPON_OFFHAND` (Avaryss), `ESSENCE`. |

## Not counted

- **Wings of the Twin Furies** (boss trophy, 1 in 500): not on the collection
  log.
- **Dormant anima core pieces** (helm, body, legs): one collection log count shared
  by all four God Wars Dungeon 2 bosses. They still take table share above.
- **Nylessa** and **Ava** (pets): pets aren't counted.

| Collection log item | Id |
|---|---|
| Dormant anima core helm | 37009 |
| Dormant anima core body | 37012 |
| Dormant anima core legs | 37015 |
| Nylessa | 37184 |
| Ava | 37185 |

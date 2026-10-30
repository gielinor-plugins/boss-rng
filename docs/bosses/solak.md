# Solak

How Boss RNG counts your Solak kills. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/Solak)
(CC BY-NC-SA 3.0).

## Drop rates

Every player in the team gets their own rolls, at the same rates for any team
size. Each kill makes three rolls:

- the unique table, 1 in 100: Erethdor's grimoire (1 in 200 per kill) or a
  Blightbound crossbow, main hand or off-hand (1 in 400 each)
- Merethiel's stave, 1 in 500
- the purple mushroom, 1 in 500 (it unlocks a pet, but it's an item with its own
  rate, so it's counted)

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_SOLAK` | Your Solak kill count. |
| `ITEMLOG_ITEM_SOLAK_<ITEM>` | Your boss log count for each unique: `PRAYER_BOOK` (grimoire), `CROSSBOW`, `OFFHAND_CROSSBOW`, `MERETHIELS_STAFF` and `BLIGHTBOUND_PET` (mushroom). |

## Not counted

- **Solak's core** (a boss trophy, 1 in 500): it isn't on the collection log, so
  there's no count to read.
- **Torn grimoire pages:** a common drop.
- **Solly** (pet): pets aren't counted.

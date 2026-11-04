# Solak

Source: [RuneScape Wiki](https://runescape.wiki/w/Solak) (CC BY-NC-SA 3.0), checked 28 October 2026; crossbow from Jagex's [Late-Game Rebalance](https://secure.runescape.com/m=news/late-game-rebalance-design-preview).

## Drop rates

Every player gets their own rolls, at the same rates for any team size. Each kill
makes three rolls:

| Roll | Rate | Each item |
|---|---|---|
| Unique table | 1 in 100 | Erethdor's grimoire 1 in 200; Blightbound crossbow, main hand or off-hand, 1 in 400 each |
| Merethiel's stave | 1 in 500 | |
| Purple mushroom | 1 in 500 | |

From the Late-Game Rebalance, each Blightbound crossbow piece is 1 in 200, so the
unique table is about 1 in 67. The other rates stay as they are.

## How kills are counted

- The purple mushroom unlocks a pet, but it's an item with its own rate, so it's
  counted.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_SOLAK` | Kill count. |
| `ITEMLOG_ITEM_SOLAK_<ITEM>` | Collection log count each: `PRAYER_BOOK` (grimoire), `CROSSBOW`, `OFFHAND_CROSSBOW`, `MERETHIELS_STAFF`, `BLIGHTBOUND_PET` (mushroom). |

## Not counted

- **Solak's core** (boss trophy, 1 in 500): not on the collection log.
- **Torn grimoire pages:** a common drop.
- **Solly** (pet): pets aren't counted.

| Collection log item | Id |
|---|---|
| Torn grimoire page | 43357 |
| Solly | 42844 |

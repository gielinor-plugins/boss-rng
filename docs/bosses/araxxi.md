# Araxxi

Source: [RuneScape Wiki](https://runescape.wiki/w/Araxxor) (CC BY-NC-SA 3.0), checked 28 October 2026.

## Drop rates

Each kill makes two rolls:

| Roll | Solo | Duo |
|---|---|---|
| Spider leg piece | 1 in 40 | 1 in 70 |
| Noxious add-on (fang, eye or web) | 1 in 120 | 1 in 200 |

Which leg depends on your path and which add-on on Araxxor's attack style, so
each is one row, independent of both.

## How kills are counted

- Solo and duo share one kill count; the duo flag read at each kill gives exact
  rates. Private and public duos work the same.

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_ARAXXI` | Kill count, solo and duo. |
| `SB_DUO` | 1 in a duo fight (private or public), 0 solo. Read at each kill. |
| `ITEMLOG_ITEM_SB_<ITEM>` | Boss log count each: `LEG_TOP`, `LEG_MIDDLE`, `LEG_BOTTOM`, `FANG`, `EYE`, `WEB`. |

## Not counted

- **Araxxor's head** (boss trophy, 1 in 500): not on the collection log.
- **Araxyte pheromone:** a common drop.
- **Spider pets** (Bill, Lana, Pete, Dave, Steve, Gavin, Barry, Mallory): pets aren't counted.

| Boss log item | Id |
|---|---|
| Araxyte pheromone | 35870 |
| Bill | 31753 |
| Lana | 31752 |
| Pete | 31750 |
| Dave | 31748 |
| Steve | 31749 |
| Gavin | 31751 |
| Barry | 33809 |
| Mallory | 33810 |

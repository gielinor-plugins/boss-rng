# Araxxi

How Boss RNG counts your Araxxi kills. Drop rates are from the
[RuneScape Wiki](https://runescape.wiki/w/Araxxor)
(CC BY-NC-SA 3.0).

## Drop rates

Each kill makes two rolls:

- a spider leg piece: 1 in 40 solo, 1 in 70 duo
- a noxious weapon add-on (fang, eye or web): 1 in 120 solo, 1 in 200 duo

Which leg piece depends on the path you take, and which add-on on Araxxor's
attack style. So Boss RNG shows the legs as one row and the add-ons as one row,
whose chances don't depend on path or style.

## How Boss RNG counts your kills

Solo and duo kills share one kill count.

- **Tracked kills:** when your kill count goes up, Boss RNG reads the fight's
  duo flag, so each kill counts at the solo or duo rates exactly. This works the
  same for private and public duo encounters.
- **Untracked kills:** your kill count can't say which were duos, so you pick
  the share of duo kills on the settings page (Plugin Hub > Manage > Boss RNG
  settings). Untracked kills are ones Boss RNG didn't record: from before you
  installed it, while it was off, or on another device.

## What Boss RNG reads

| Var | What it holds |
|---|---|
| `BSLAY_KILLS_ARAXXI` | Your Araxxi kill count, solo and duo. |
| `SB_DUO` | 1 in a duo fight, private or public; 0 solo. Read at each kill. |
| `ITEMLOG_ITEM_SB_<ITEM>` | Your boss log count for each unique: `LEG_TOP`, `LEG_MIDDLE`, `LEG_BOTTOM`, `FANG`, `EYE` and `WEB`. |

## Not counted

- **Araxxor's head** (a boss trophy, 1 in 500): it isn't on the collection log,
  so there's no count to read.
- **Araxyte pheromone:** a common drop, not a rare one.
- **The spider pets** (Bill, Lana, Pete, Dave, Steve, Gavin, Barry and Mallory):
  pets aren't counted.

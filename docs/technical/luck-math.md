# Luck math

How Boss RNG turns tracked kills into the numbers it shows. The code is
`src/core/luck.lua` (the formulas) and `src/core/stats.lua` (applying them to a
boss's kills).

Most bosses' luck counts kills. Three count something else, and on this page a
"kill" means that instead: loot piles claimed at Amascut, chests looted at Barrows,
and chests opened at Zemouregal & Vorkath (`unit` in `src/bosses.lua`).

## Rolls

A boss file describes each kill as a list of independent **rolls**. A roll has a
chance per kill and a set of items with weights: when it hits, it gives one of its
items, picked by weight. So an item's chance per kill is the sum, over the rolls it's
on, of the roll's chance times its share of the weights.

For example, Rasial's kill has a weapon roll (1 in 320, two items) and an armor roll
(1 in 128, five items), so each unique is 1 in 640.

## Rate versions

A **rate version** is one set of a boss's drop rates, in effect from the day a game
update set them until the next update changes them. General Graardor has two:

| Rate version | Kills on | Each armor piece |
|---|---|---|
| Base | Days before the Late-Game Rebalance | 1 in 384 |
| Late-Game Rebalance | Its day (in `late_game_rebalance.lua`) and after | 1 in 320 |

Versions aren't numbered anywhere. They come from the files in `src/core/rates/`,
which `rates.UPDATES` in `src/core/rates.lua` lists oldest first:

- `base.lua` is every boss's first version, in effect from the start.
- Each later file is a new version, in effect from its `day`, for the bosses it
  lists. Rasial isn't in the Late-Game Rebalance file, so Rasial has only one
  version. A file whose `day` is `false`, for an update with no date yet, is
  ignored until a day is set.
- A kill uses the newest version in effect on its day.

Every kill in one version has the same chances, so kills can be added up by version
before any math: a thousand days of kills in two versions need the math twice, not
a thousand times ([Caching](caching.md#within-one-stats-calculation)). Arch-Glacor is
the exception: its rates also depend on each day's average enrage and streak (see
below), so each of its days counts as a version of its own.

## Expected drops

An item's **expected drops** are its chance per kill, added up over every tracked
kill. Each kill's chance comes from the drop rates on the day of the kill, for its
mode (such as hard mode) and what was read at it (such as Croesus contribution).
That's how many an average player would have after the same kills.

Some bosses' rates depend on values that change kill by kill, such as Arch-Glacor's
enrage and streak. Those values are added up by day, and a day's kills use their
averages. Arch-Glacor's formula is a straight line in both values, so the averages
give exactly the same expected drops as each kill on its own.

## Luck

Rare drops over many kills follow a Poisson distribution, with the expected drops
as its mean. **Luck** is the share of players with fewer uniques than you, plus half
of those with exactly as many (the "mid-p" convention, so an average result lands
near 50%):

```
luck = P(fewer than received) + P(exactly received) / 2
```

It's shown as:

| Luck | Shown |
|---|---|
| Above 60% | "top N%", where N is 100% minus luck, rounded up |
| 40% to 60% | "about average" |
| Below 40% | "bottom N%", where N is luck, rounded up |

"Spooned" and "cursed" mark the top and bottom 10%. Rounding up means the label
never makes your result look rarer than it is.

Luck shows once an average player would have one unique, or from your first unique.
Before that, a dry run is normal, so the panel says how many kills until it will
show: the expected drops still needed, divided by the expected drops per kill.

## Dry streaks

A **dry streak** is the kills since your last unique: since any unique for the boss,
or since your last of one item. An item's streak only counts kills that could drop
it, such as hard mode kills for a hard mode only unique.

**"N% go this long"** is the share of players who would still have no unique after
the same kills:

```
still dry = product over kills of (1 - chance of any unique on that kill)
```

A "+" after the streak means it may be longer: there were kills before tracking, and
no unique has been tracked since.

## Groups

Items shown as one row, such as Araxxi's leg pieces, add up their expected and
received drops. The group's dry streak is its shortest member's.

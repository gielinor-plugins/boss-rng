# Luck math

How Boss RNG turns tracked kills into the numbers it shows. The code is
`src/core/luck.lua` (the formulas) and `src/core/stats.lua` (applying them to a
boss's kills).

## Rolls

A boss file describes each kill as a list of independent **rolls**. A roll has a
chance per kill and a set of items with weights: when it hits, it gives one of its
items, picked by weight. So an item's chance per kill is the sum, over the rolls it's
on, of the roll's chance times its share of the weights.

For example, Rasial's kill has a weapon roll (1 in 320, two items) and an armor roll
(1 in 128, five items), so each unique is 1 in 640.

## Expected drops

An item's **expected drops** are its chance per kill added up over every tracked
kill, each kill at the rates of its mode and its day, and with what was read at it
(such as Croesus contribution). That's how many an average player would have after
the same kills.

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

"Spooned" and "cursed" mark the top and bottom 10%. Rounding up means you're never
placed in a smaller group than you're in.

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

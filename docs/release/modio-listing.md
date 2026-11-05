# mod.io listing

The text for Boss RNG's mod.io page. Jagex requires the Email, Feedback and
collaboration, EULA, Permissions and Data Protection sections
([submission process](https://developer.runescape.com/rs/submission/process.html)),
and the EULA statement must be copied word for word. Keep this file in step with the
live page.

## Name

Boss RNG

## Summary

10 to 150 ASCII characters, without repeating the name:

> Spooned or cursed? Compare your boss uniques and dry streaks with an average player's
> after the same kills, counted from the day you install it.

## Description

Copy everything between the lines.

---

Boss RNG shows how lucky you really are with unique boss drops. Across 31 supported
bosses, it compares your drops with an average player's after the same number of kills,
both overall and unique by unique. It also shows how unusual your current dry streak is
statistically. It never shows drop rates.

It counts your kills from the day you install it, whenever it's turned on. Each kill is
judged by the rates of the day you get it, so future drop rate changes don't rewrite
your luck. Your all-time kill counts and collection log counts for each boss are shown
too, straight from the game.

**How to use it:**

Open Boss RNG from the ribbon in the Plugins window, then kill a supported boss. Kills
and drops are tracked automatically, without any required configuration. The panel shows
your luck and dry streak, and a "View details" button opens a window showing every
unique tracked.

To start over for one boss or all of them, use Data Controls in the plugin's settings.

Supported bosses and how each is counted:
https://github.com/gielinor-plugins/boss-rng/blob/main/docs/bosses/README.md

### Email

gielinorplugins@gmail.com

### Feedback and collaboration

Found a bug, or have a question or idea? Email me at the address above. I'm not
accepting code contributions at the moment but may in the future.

### EULA

This Plugin uses software licensed by Jagex to the developer under the terms of the
Jagex End User Licence Agreement (EULA) found at https://legal.jagex.com/docs/terms/eula
(and all terms incorporated into it by reference). The development and any use of
the Plugin is at all times subject to the Jagex EULA.

### Permissions

This plugin requests no permissions.

### Data Protection

This plugin uses the following information:

- your character's display name
- your boss kill counts and collection log counts
- values that set a kill's drop rates, such as a boss's enrage, Croesus contribution,
  the Barrows brothers killed, or whether your pontifex shadow ring is overcharged
- your loot chests and the loot piles you own
- the game's date

This information is not transmitted outside of the plugin under any circumstances.

The plugin stores the following between sessions, in the game client's plugin data on
your device, under your character's display name:

- the kills it counts, and the day of each
- the uniques it counts, and the kill each one last dropped on
- some of the values that set a kill's drop rates
- the boss you killed last

Other plugins can't read this data. Data Controls in the plugin's settings deletes it,
for one boss or for every boss.

---

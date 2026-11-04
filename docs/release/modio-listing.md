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

> See how lucky you've been with boss uniques: luck and dry streaks for each unique,
> against an average player with the same kills.

## Description

Copy everything between the lines.

---

Boss RNG shows how lucky you've been with boss uniques. For each boss and each
unique, it compares the drops you got with what an average player would have after
the same kills, and shows how unusual your current dry streak is. It never shows
drop rates.

It tracks your kills from the day you install it, while it's on, and rates each kill
at the drop rates in effect that day, so a later rate change won't rewrite your past
luck. Your all-time kill counts and collection log counts are shown beside it, as
the game keeps them.

**How to use it:** open Boss RNG from the Plugins window's ribbon, then kill a
supported boss. The panel shows your luck and dry streak, and View details opens a
window with every unique. Data Controls, in the plugin's settings, resets one boss or
all of them.

Supported bosses and how each is counted:
https://github.com/<repository>/blob/main/docs/bosses/README.md

### Email

gielinorplugins@gmail.com

### Feedback and collaboration

Feedback, bug reports and questions are welcome by email at the address above. I'm
not accepting code contributions at the moment.

### EULA

This Plugin uses software licensed by Jagex to the developer under the terms of the
Jagex End User Licence Agreement (EULA) found at https://legal.jagex.com/docs/terms/eula
(and all terms incorporated into it by reference). The development and any use of
the Plugin is at all times subject to the Jagex EULA.

### Permissions

This plugin requests no permissions.

### Data Protection

This plugin uses the following information: your character's display name, your
boss kill counts and collection log counts, values the game shows during some boss
fights (such as enrage, contribution or the brothers killed at Barrows), your loot
chests and the loot piles you own, and the game's date.

This information is not transmitted outside of the plugin under any circumstances.

To show your luck over time, the plugin saves the kills and uniques it counts on your
computer, under your character's display name. Other plugins can't read it, and you
can delete it at any time with Data Controls in the plugin's settings.

---

## Before publishing

- Replace `<repository>` with the repository's address, or remove that line if the
  repository isn't public.
- Jagex's Case 1 example says game information isn't stored between sessions. Boss
  RNG does store it, locally, so the last paragraph above says so instead. Confirm
  this wording with Jagex (RuneScape Plugin Portal Discord) before the first
  submission.

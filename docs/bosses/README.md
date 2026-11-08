# Supported bosses

Boss RNG supports 31 bosses on 27 pages: Dragonkin Laboratory and the Sanctum of
Rebirth each have three bosses, with their own kill counts, on one page. Each page
has its drop rates, how its kills are counted, every value it reads from the game,
and what was tested in game.

| Boss | How kills are counted | Kills told apart by |
|---|---|---|
| [Amascut, the Devourer](amascut.md) | Each claim from the chest, with its loot piles | Normal mode or the enrage tier |
| [Araxxi](araxxi.md) | Each kill | Solo or duo |
| [Arch-Glacor](archglacor.md) (hard mode) | Each kill | The fight's enrage and the kill's place in the streak |
| [Barrows Brothers](barrows.md) | Each chest looted | The brothers killed, Linza and Akrisae included |
| [Barrows: Rise of the Six](rots.md) | Each kill | |
| [Commander Zilyana](zilyana.md) | Each kill | Normal or hard mode |
| [Corporeal Beast](corp.md) | Each kill | |
| [Croesus](croesus.md) | Each kill | Your contribution |
| [Dragonkin Laboratory](dragonkin.md) | Each kill, for each of its three bosses | Solo, or the players in the dungeon |
| [General Graardor](graardor.md) | Each kill | Normal or hard mode |
| [Gregorovic](gregorovic.md) | Each kill | Normal or hard mode |
| [Helwyr](helwyr.md) | Each kill | Normal or hard mode |
| [K'ril Tsutsaroth](kril.md) | Each kill | Normal or hard mode |
| [Kerapac](kerapac.md) | Each kill | Normal or hard mode, and your loot piles |
| [Kree'arra](kreearra.md) | Each kill | Normal or hard mode |
| [Nex](nex.md) | Each kill | |
| [Raksha, the Shadow Colossus](raksha.md) | Each kill | Solo or duo |
| [Rasial, the First Necromancer](rasial.md) | Each kill | |
| [Sanctum of Rebirth](sanctum.md) | Each boss's loot claimed | The boss, and normal or hard mode |
| [Solak](solak.md) | Each kill | |
| [The Gate of Elidinis](elidinis.md) | Each kill | |
| [The Magister](magister.md) | Each kill | |
| [The Shadow Reef](shadow_reef.md) (the Ambassador) | Each kill | Solo, or the players in the dungeon |
| [The Twin Furies](furies.md) | Each kill | Normal or hard mode |
| [TzKal-Zuk](zuk.md) | Each kill | Normal or hard mode, and checkpoints in hard mode |
| [Vindicta & Gorvek](vindicta.md) | Each kill | Normal or hard mode |
| [Zemouregal & Vorkath](vorkath.md) | Each chest opened from your backpack | Normal or hard mode |

Kills are counted only while Boss RNG is on. Where Boss RNG can't know something a
kill's rates depend on, such as who was in your group, the boss's Info tab lists
what it assumes.

## Shared assumptions

- **Solo kills.** A kill count doesn't say who you killed with, and in a group you
  get a smaller share of the drops. So at the Corporeal Beast, the God Wars Dungeon
  bosses, Nex and the Gate of Elidinis, every kill is assumed solo. If you kill in a
  group, your luck will read lower than it really is.
- **The pontifex shadow ring.** At the Elder God Wars Dungeon bosses (Arch-Glacor,
  Croesus, Kerapac and TzKal-Zuk), an overcharged pontifex shadow ring raises every
  unique's chance by 2%. Boss RNG can only see the ring once it's overcharged, so a
  ring that isn't is treated as not worn.

## How to read a boss page

Every page has these sections, in this order:

| Section | Says |
|---|---|
| **Drop rates** | Each unique's rate, with the wiki page and the date it was checked. |
| **How kills are counted** | What counts as one kill, how its mode is decided, and what Boss RNG assumes. |
| **Vars read** | Every game value read, and what it holds. Reviewers can check none is hidden. |
| **Tests** | What was checked in game, when, and what it showed. Only for bosses that needed more than their kill count and collection log counts. |
| **Not counted** | Collection log items left out of luck, why, and their item ids. |

A page can add a section for something only that boss has, such as how Barrows
chests are saved.

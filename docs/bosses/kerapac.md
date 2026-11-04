# Kerapac

Source: [RuneScape Wiki](https://runescape.wiki/w/Kerapac,_the_bound) (CC BY-NC-SA 3.0), checked 28 October 2026.

## Drop rates

Each kill gives three loot piles, each rolling for a unique. "Wraps, codex or
scripture" is Kerapac's wrist wraps, the Greater Concentrated Blast codex or the
Scripture of Jas, evenly.

| Roll, per pile | Normal | Hard mode |
|---|---|---|
| Fractured Staff of Armadyl piece | none | 1 in 400 |
| Wraps, codex or scripture | 1 in 256 | 1 in 180, only if the staff roll misses |

Staff pieces drop in order (shaft, gem, then symbol), so they're one row.

## How kills are counted

- Piles by damage over the whole fight: solo all three; duo two for the top
  damager and one for the other; trio one each.
- Each kill counts the piles you got, seen at the kill as the ground stacks you
  own that gain Resonant anima of Jas (every pile has it). Kills are saved by
  piles (`n1` to `n3`, `h1` to `h3`), and Boss RNG shows your tracked piles
  beside your kills ("40 kills (97 piles)").
- Away at the kill (teleported, left or died), your piles aren't seen until you
  come back, so the kill counts as 1 pile: you were most likely not the top
  damager. The Info tab says so.
- An overcharged pontifex shadow ring raises every unique 2%
  ([Shared assumptions](README.md#shared-assumptions)).

## Vars read

| Var | Holds |
|---|---|
| `BSLAY_KILLS_EGWD_JAS_BOSS` | Normal mode kill count. |
| `BSLAY_KILLS_EGWD_JAS_BOSS_HARDMODE` | Hard mode kill count. |
| `EGWD_PONTIFEX_RING_PASSIVE_UNLOCKED` | 1 once the pontifex shadow ring is overcharged. |
| `ITEMLOG_ITEM_EGWD_JAS_<ITEM>` | Collection log count each: `BOSS_MAGIC_WEAPON_TOP`, `_MIDDLE`, `_BOTTOM` (staff pieces), `BOSS_MAGIC_GLOVES` (wraps), `BOOK_UNLOCK_TOKEN` (scripture). The codex's is `ITEMLOG_ITEM_COMBATV2_ABILITY_CODEX_MAGIC_GREATER_CONCENTRATED_BLAST`. |
| Ground stacks you own (`ObjStackEntityAdded`, `ObjStackEntityChanged`) | Your loot piles: the tiles where Resonant anima of Jas (51804, or untradeable 51805) lands at a kill. |

## Tests

In game on 2 November 2026 by the developer, logging each kill count change and
every ground stack (added, changed or removed, owned or not) with its tile and
game tick.

| Test | Seen |
|---|---|
| Hard mode, solo, size 1 | 3 owned piles on three side-by-side tiles, each with Resonant anima of Jas (93 to 118), in the kill count's tick. |
| Normal mode, solo, size 1, left without looting | 3 owned piles with anima in the kill's tick. Leaving logged no removals. |
| Two normal mode kills, solo, size 2, not looted between | Each: 3 owned piles with anima in its tick. The first kill's piles went unowned and vanished about 2 minutes after it, before the second landed fresh on the same tiles. |
| Second kill 58 s after the first, fastest spawn rate | The new anima joined the owned stacks (44 to 100, 42 to 86, 53 to 111): still 3 tiles gaining owned anima. |
| Second kill 85 s after the first | The older items were now unowned; the new anima arrived as new owned entries on the same three tiles (0 to 60, 0 to 41, 0 to 53). Ownership is per item, not per stack. |
| Duo, top damage | 2 owned piles, on the outer tiles. The partner's pile is never visible. |
| Duo, lower damage | 1 owned pile, on the middle tile. |
| Duo, almost no damage (twice) | No kill count change and no piles: no kill credit, so nothing to count. |
| Duo, left at the phase 3 to 4 transition, back 20 s after the kill | Kill count rose at the kill while away. 2 owned piles (top damage, by the whole fight) appeared on return. They went public about a minute after the kill and could still be looted. |
| Duo, away, back 60 s after the kill | 1 owned pile appeared on return, public a few seconds later. |

Conclusions:
- Every pile has Resonant anima of Jas: tradeable (51804), or untradeable
  (51805) until the player's Pontifex shadow ring is upgraded with 1,000 anima.
- At a kill, the distinct tiles where owned anima goes up in the kill count's
  tick give the player's piles: 3 solo, 2 or 1 in a duo, in every test.
- Away at the kill, the kill count still rises, and owned piles appear only on
  return.

## Not counted

- **Kerapac's time-torn Staff of Armadyl** (boss trophy, 1 in 500): not on the
  collection log.
- **Kerry** (pet): pets aren't counted.

| Collection log item | Id |
|---|---|
| Kerry | 51861 |

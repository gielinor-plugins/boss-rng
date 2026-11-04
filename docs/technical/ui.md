# UI

Boss RNG has three views, all drawn with the UI library declared in `plugin.json`:

| View | File | Where |
|---|---|---|
| Ribbon panel | `src/ui/panel.lua` | The layer the game gives the plugin in the Plugins window (`ContentLayerReady`). Scrolls if the panel is small. |
| Details window | `src/ui/window.lua` | A movable window on the game's plugin layer, opened from the panel. Fixed size; only its tab pages scroll. |
| Settings page | `src/ui/settings.lua` | The layer the game gives the plugin in Plugin Hub, Manage tab (`SettingsLayerReady`). Data Controls only. |

`src/ui/state.lua` works out what they show, and `src/ui/format.lua` words it, so
every view says the same thing the same way. `src/ui.lua` decides when they draw.

## When views draw

- **After a change,** on the next logic tick, once however many changes that tick
  had (a kill and its drop are two).
- **Only if what they show changed.** The panel and window compare the boss list
  and the shown boss's inputs with what they last drew, so a kill at another boss
  leaves them alone, along with their scroll position and open dropdowns.
- **Always** when the details window opens, when the game gives the panel a fresh
  layer, and for the settings page, which is small and rarely open.
- **Never while hidden.** The panel isn't drawn while minimized, closed or showing
  another plugin (see below).

A failed draw falls back to one plain line ("Boss RNG couldn't draw this panel")
or closes the window, rather than leaving it half drawn.

## Knowing when the panel is hidden

The game gives no event when it minimizes the ribbon panel, closes it or hands its
layer to another plugin: it just clears the layer. So `src/ui/layer_view.lua` keeps
a 1 x 1 transparent rectangle in the layer as a marker. Once the marker is no
longer among the layer's children, the layer isn't Boss RNG's to draw in until the
game fires `ContentLayerReady` again. A layer that can't list its children falls
back to the marker's `visibleGlobal`.

Tested in game on 3 November 2026, reading the panel every half second:

| Panel | Layer's children | The marker |
|---|---|---|
| Open | 4, including the marker | A child |
| Minimized or closed | 0 | Not a child |
| Showing another plugin | That plugin's (2 to 4) | Not a child, though its `visibleGlobal` could still read true |
| Restored or picked again | `ContentLayerReady` fired, then redrawn | A new marker, a child |

Kills while the panel was minimized or showing another plugin drew nothing, and
switching back showed them. The layer's own `visible`, `visibleGlobal` and `hidden`
never changed, so the only reliable sign is whether Boss RNG's marker is still among
the layer's children.

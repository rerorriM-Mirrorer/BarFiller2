# Screen-grid snapping and local layout anchoring (BarFiller2 Test 3)

Windower renders **primitives** using its image and text APIs. An image sprite is one kind of primitive; text is another. An object’s *resource* is its underlying PNG/font, not the object's position. A grid is not a parent container by itself.

## Two distinct coordinate systems

1. **Screen/grid coordinates:** shared across addons. A grid of 10 pixels is anchored to (0,0) of Windower’s UI coordinate space. During Ctrl+drag, the parent widget’s top-left anchor is floored to grid multiples; e.g. (273,57) becomes (270,50). The grid is independent of widget scale. Both left and right Ctrl are accepted (DirectInput 29 and 157). Screen bounds are respected.
2. **Local widget coordinates:** each child position is calculated from the *single parent anchor* `(x,y)` and its own offset and scale, ideally as `pixel_x=x+round(local_x*scale)`. Internal elements must **not** independently snap to the screen grid; that would tear apart their relative layout.

BarFiller2's gauge left edge is the widget anchor; its middle track is offset by `round(8*scale)` and serves only as the mouse drag handle. The current implementation observes that image’s new position from `images.lua`, converts it back to the widget anchor, optionally grid-snaps the anchor, and repositions all children through `positioning()` and `gauge:move()`. Changing scale does not change the grid spacing.

EnemyBar2's current feature-branch drag implementation directly handles mouse movement and shifts all primitives in the selected group by a common delta. Its **first bar primitive** is the screen-grid reference. Matching 10px snapping ensures addon anchors can be aligned, but does not guarantee corresponding border or text baselines align: their *local offsets* can still be different.

## Why text and rails may not align at different scales

- Independent rounding of width, offsets, cap sizes and font sizes can create 1px gaps or overlaps.
- Text APIs use font **metrics** (ascenders, baselines, stroke widths) rather than the same rectangular pixel rules used by PNG rails.
- If some offsets are fixed pixels and others are multiplied by the chosen scale, proportions drift across scales. EnemyBar2's `bars.move` currently mixes such offsets and right-anchored text placement.
- Repeated scaling of already-scaled coordinates accumulates error; always recalculate from *unscaled* design-space values.

## Portable pattern for future draggable addons

Maintain exactly one saved parent anchor `X,Y` (or one per intentional independently movable sub-widget), one scale factor, and a source-of-truth set of **design-space** dimensions. On drag, compute a new anchor; optionally snap it to the **shared screen-origin grid** if either Ctrl key is held. On every move/scale, rebuild child positions and sizes from the same anchor and design-space offsets. Round at the final pixel boundary. Prefer a single `layout()` function rather than competing per-element moves.

This is a *position-grid feature*, not Ctrl+drag resizing or a visual grid overlay. No EnemyBar2 changes are included.

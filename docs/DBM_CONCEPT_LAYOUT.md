# DBM measured concept layout

Applied in HUD alpha.9 to native **Huge Bars**. The user's selected EllesmereUI accent replaces the concept's fixed teal and mechanic-colored spell-icon borders. DBM retains control of positions, row spacing, normal/huge dimensions, scale, timer values, priorities and number formatting. No profiles or saved settings are rewritten.

The supplied 754x88 screenshot measurements define proportions, not fixed live dimensions. For a configured native row width W and height H:

| Element | Horizontal rule | Vertical rule |
| --- | --- | --- |
| Outer panel | Full native row width | Full configured row height, centered on native frame |
| Spell icon | Center at 51.5/754 of W | Center at 43.5/88 of H from the top |
| Square icon size | Minimum of 73/754 of W and 69/88 of H | Same width and height; crop through EUI API |
| Name | Start at 110/754 of W, stop at 565/754 | Top at 19/88 of H |
| Progress track | Start at 110/754, end at 533/754 (56.1% width) | Top at 53/88, height 22/88 |
| Countdown | Width 95/754; right edge at 661/754 | Center vertically |
| Mechanic compartment | Separator at 677/754; symbols centered around 714.5/754 | Native symbols centered; multiple symbols fit in a compact grid |
| Typography | EUI font | Name 23/88 of H; countdown 34/88, adjusted by DBM font-size preference |

The supplied countdown measurements contain an inconsistency: a 95-wide region ending at X=661 starts at 566, rather than the approximate X=580. The explicit fixed right edge and region width take precedence. Square icons are centered inside the approximate 73x69 reference cell rather than stretched.

The panel uses #0B1014 at 87.5% opacity; the track uses #20262B. DBM's actual fill colors, text colors and precision remain native. The subtle fill shade from alpha.8 remains. Panel/icon/track edges use one physical pixel based on effective scale and the PixelUtil conversion factor (or physical-screen-height fallback). Coordinates snap to that grid.

Small Bars retain the previous compact look and omit mechanic symbols. Huge Bars below height 18, narrower than 150, or configured with the optional right-hand spell icon also retain the compact fallback. Normal/huge transitions reuse the same skin objects and restore text width, borders and separator state. There are no extra countdown or animation hooks. During native enlargement, anchors remain bounded; exact proportions are recalculated by DBM's final ApplyStyle callback.

Legibility floors are 6 UI units for names and 8 for countdowns. Long names use a constrained, non-wrapping native FontString; actual glyph clipping/ellipsis and live animations require client rendering and are not proven by mocks. DBM's own decimal/variance prefixes are preserved rather than formatting timer text on every update.

Validation covers exact reference geometry, 75% scaling, physical-pixel snapping, fixed countdown position without mechanic icons, square spell icons, normal/huge transitions, native return values, pooled reuse and the existing no-countdown-work checks. This is an untagged test build; no platform publication.

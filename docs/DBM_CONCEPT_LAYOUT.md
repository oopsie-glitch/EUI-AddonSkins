# DBM measured concept layout

Applied in HUD alpha.9, refined in alpha.10–12 to native **Huge Bars**. The user's Blizzard Skins+ accent-bar color (custom or linked to the overall EUI accent) replaces the concept's fixed teal and mechanic-colored spell-icon borders. DBM retains control of positions, row spacing, normal/huge dimensions, scale, timer values, priorities and number formatting. No profiles or saved settings are rewritten.

The supplied 754x88 screenshot measurements define proportions, not fixed live dimensions. For a configured native row width W and height H:

| Element | Horizontal rule | Vertical rule |
| --- | --- | --- |
| Outer panel | Full native row width | Full configured row height, centered on native frame |
| Spell icon | Center at 51.5/754 of W | Center at 43.5/88 of H from the top |
| Square icon size | Minimum of 73/754 of W and 69/88 of H | Same width and height; crop through EUI API |
| Name | Start at 110/754 of W, stop at 565/754 | Text band starts at 10/88 of H, height 34/88; vertically centered |
| Progress track | Start at 110/754, end at 533/754 (56.1% width) | Top at 53/88, height 22/88 |
| Countdown | Width 95/754; right edge at 661/754 | Center vertically |
| Mechanic compartment | Separator at 677/754; symbols centered around 714.5/754 | Native symbols centered; visible symbols fit in a compact grid; a single symbol uses the full 33/88-height target, limited by compartment width |
| Typography | EUI font | Name 23/88 of H; countdown 34/88, adjusted by DBM font-size preference |

When no right-side mechanic symbols are shown, alpha.12 reclaims the 77/754-width compartment: the name and progress strip extend by that amount, the countdown moves right by the same amount, and the separator is hidden. Appearance of a symbol restores the compartment through the existing lifecycle hooks. Timer panel and spell-icon accent edges follow Blizzard Skins+ Show accent bar; neutral track edges remain visible.

The supplied countdown measurements contain an inconsistency: a 95-wide region ending at X=661 starts at 566, rather than the approximate X=580. The explicit fixed right edge and region width take precedence. Square icons are centered inside the approximate 73x69 reference cell rather than stretched.

The panel uses #0B1014 at 87.5% opacity; the track uses #20262B. DBM's actual fill colors, text colors and precision remain native. The subtle fill shade from alpha.8 remains. Panel/icon/track edges use one physical pixel based on effective scale and the PixelUtil conversion factor (or physical-screen-height fallback). Coordinates snap to that grid.

Small Bars omit mechanic symbols. Their two-line progress strip now uses 25% of configured height without the previous six-unit ceiling; names are vertically centered between the upper padding and the strip. Compact single-line rows retain their fallback. Huge Bars below height 18, narrower than 150, or configured with the optional right-hand spell icon also retain the compact fallback. Normal/huge transitions reuse the same skin objects and restore text width, borders and separator state. There are no extra countdown or animation hooks. During native enlargement, anchors remain bounded; exact proportions are recalculated by DBM's final ApplyStyle callback.

Legibility floors are 6 UI units for names and 8 for countdowns. Long names use a constrained, non-wrapping native FontString; actual glyph clipping/ellipsis and live animations require client rendering and are not proven by mocks. DBM's own decimal/variance prefixes are preserved rather than formatting timer text on every update.

Validation covers exact reference geometry, 75% scaling, physical-pixel snapping, fixed countdown position without mechanic icons, square spell icons, normal/huge transitions, native return values, pooled reuse and the existing no-countdown-work checks. This is an untagged test build; no platform publication.

# RestedXP V2 Forever integration

Baseline is draft PR #75 at `4db0083`. Native source reviewed is RestedXP v4.11.34 at `b4a0f99a2ceac856f75a11594bcaa19886236a01`. Visual references are the supplied V2 screenshot and the approved Forever V1 guide. The [initial performance audit](RESTEDXP_PERFORMANCE.md) describes the original fixture and V1 optimization.

## Native ownership and integration

- The movable V2 guide owns its upper frame, title and controls, scroll widget and footer. The skin keeps its existing chamfered shell parented to that movable window. The legacy root remains responsible for native V2 visibility. The legacy shell and root-owned cog are still retired when V2 takes over. Existing layout anchors move the artwork with its owner, and art-only hosts remain mouse-disabled and outside EUI's direct texture cleanup.
- The Forever header uses the same compact, restrained meter material as the V1 title band. The art extends to the native header/body seam by one UI unit and ends in a thin masked divider. The existing title, subtitle and action buttons keep their native roles. The footer uses a warm label and a copper tint on the native resize glyph. The V2 scrollbar retains the native track geometry, wheel handling, thumb drag and arrow actions. Its arrows reuse the framed Forever treatment, with disabled and hover feedback. The wide native track fill is transparent over the shared material.
- Native guide rows use pooled `RXPV2GuideStepsItem` buttons with separate background, border, shadow and number-badge groups. The Forever list suppresses these cosmetic fills and outlines in favour of the shared textured background and a thin separator per row. The number and its colour, completion dimming, native visibility, any button highlight, and the row's context menu remain native. The slider changes the common background without stacking row-sized alpha. At automatic opacity, V2 intentionally uses one continuous body surface instead of the V1 per-row tint. Standard restores the native groups and spacing.
- The native item subtracts the number badge and gutters from the anchored row's width, then uses `GetStringHeight()` for its height. That metric does not account for automatic wrap, and the anchored row can be measured before its new bounds settle during resize. The Forever item uses the live scroll viewport with the native two-unit content insets and actual badge width. It measures the width-constrained label's natural region height. It retains the native minimum height, padding and list gap. RestedXP still aggregates each height into its scroll extent and current-step offset. This changes only the identified V2 list item. Older or differently shaped widgets keep the existing compatibility path.
- Independently positioned Current Step cards keep native owners, anchors, input and content layout. They use the existing chamfered card shell without the native square shadow, with a warm title and native checkmark geometry. The checkbox skin recolours the native two-stroke mark and backdrop during its normal paint, leaving checked, unchecked, hover, click and tooltip behavior with RestedXP. Targets and Items continue to use the shared auxiliary treatment. The approved V1 code path, settings and theme overrides are preserved.

Source references are [native V2 guide list, viewport and row sizing](https://github.com/RestedXP/RXPGuides/blob/b4a0f99a2ceac856f75a11594bcaa19886236a01/UI/V2/Core.lua#L747-L999), [V2 layout and guide ownership](https://github.com/RestedXP/RXPGuides/blob/b4a0f99a2ceac856f75a11594bcaa19886236a01/UI/V2/Core.lua#L1078-L1535), [native active-step checkbox and layout](https://github.com/RestedXP/RXPGuides/blob/b4a0f99a2ceac856f75a11594bcaa19886236a01/UI/V2/Core.lua#L2499-L3030) and [FontString measurement](https://warcraft.wiki.gg/wiki/API:FontString_GetStringHeight).

## Host-Lua comparison

The existing benchmark now includes a 36-row V2 viewport with the native row, badge and shadow construction order. The V2 open measurement starts after the first V1 open. The warm text workload changes a single row through the native-shaped snapshot path. The resize workload alternates 242 and 342 UI units and forces native-style measurement for all 36 rows on each change. Both warm workloads use 20 warmups and 120 measured operations. Five fresh Lua processes per configuration ran in rotating order with independent cold call probes. The control uses the same fixture without installing the adapter. See [workload runner](../benchmarks/run_rxp.py) for reproduction. Pass `--baseline 4db0083` in a Git checkout containing that commit.

All entries are native model / approved baseline / candidate. CPU and churn are workload totals. Calls, scans and queued flushes describe one cold or warm probe. The fixture models layout and adapter callbacks without running the game renderer or measuring live FPS, latency, taint or real client memory.

| Workload | CPU ms | P95 ms | Churn KiB | Total calls | Adapter calls | Child/region reads | Queued flushes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| First V2 open | 2.899 / 4.634 / 4.722 | 2.897 / 4.632 / 4.720 | 1416.6 / 1742.5 / 1762.8 | 2271 / 11395 / 15087 | 0 / 1058 / 2323 | 0 / 158 / 158 | 0 / 1 / 1 |
| V2 row text update | 0.670 / 58.868 / 1.285 | 0.006 / 0.858 / 0.014 | 14.9 / 844.2 / 33.5 | 81 / 5132 / 125 | 0 / 948 / 15 | 0 / 79 / 0 | 0 / 1 / 0 |
| V2 resize | 36.668 / 107.790 / 58.017 | 0.533 / 1.171 / 0.750 | 5062.6 / 7232.5 / 6424.3 | 1520 / 8098 / 5785 | 0 / 1229 / 1229 | 0 / 79 / 0 | 0 / 1 / 0 |
| V1 warm step | 0.483 / 19.377 / 17.441 | 0.004 / 0.273 / 0.264 | 28.6 / 570.1 / 570.1 | 59 / 1718 / 1718 | 0 / 444 / 444 | 0 / 0 / 0 | 0 / 1 / 1 |
| Theme change | 0.030 / 34.061 / 28.581 | 0.001 / 2.282 / 1.354 | 7.0 / 2257.6 / 2255.3 | 7 / 8808 / 10302 | 0 / 1378 / 2130 | 0 / 57 / 57 | 0 / 1 / 1 |
| V1 ↔ V2 | 0.232 / 19.491 / 18.506 | 0.008 / 0.790 / 0.712 | 12.4 / 584.8 / 583.2 | 96 / 5194 / 4486 | 0 / 961 / 955 | 0 / 79 / 79 | 0 / 1 / 1 |
| Opacity burst | 0.108 / 22.271 / 9.119 | 0.001 / 0.355 / 0.154 | 0.0 / 354.0 / 354.0 | 3 / 2196 / 866 | 0 / 497 / 194 | 0 / 0 / 0 | 0 / 1 / 1 |
| Closed idle | 0.054 / 0.055 / 0.055 | 0.001 / 0.001 / 0.001 | 0.0 / 0.0 / 0.0 | 2 / 2 / 2 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 |

First V2 open created 259 / 266 / 266 mock frames, 360 / 405 / 406 textures, 0 / 3 / 3 masks and 36 / 36 / 36 labels. Its post-GC heap delta was 1415.0 / 1706.5 / 1726.8 KiB. The candidate adds one header-divider texture in this fixture and does more setup calls. The fixture does not construct real header controls or active-step cards. Warm probes created no additional objects and registered no hooks. The V1 warm step recorded the same calls, scans, writes and heap churn as the baseline. Closed idle scheduled no adapter work.

Warm V2 list updates no longer need a full integration refresh once the known guide and list are attached. The native backdrop callback styles new and reused rows before height calculation. Layout and theme changes still use the native reflow, and explicit owner and theme transitions still perform an integration refresh. Theme switching does more adapter calls in the probe because it restores and reapplies the row appearance and layout. Resize remains a native all-row measurement when width changes.

## Validation and client checks

The regression suite covers width changes with stale row geometry, actual wrapped-height use in the fixture, badge clearance, pooled row release and reuse, native completion dimming, combat deferral, checkbox appearance and preserved click handler, framed scrollbar and disabled state, theme restoration, opacity endpoints, and the existing V1/V2 owner movement, resize and orphan-art tests. The package checks include Lua, manifests, full regression suite and installation archive integrity.

The first in-game comparison should capture the same long V2 step at narrow and wide widths, plus a screenshot of the independent Current Step and auxiliary panels. Check a wrapped quest warning and a long inline item link, completed/active rows, scrollbar arrows and drag, checkbox hover and skip, collapsed and expanded list, and movement at reduced UI scale. Switch Standard → Forever and V1 → V2 → V1, refresh EUI, and compare backgrounds at 0%, 50% and 100%. The WoW client is needed to confirm the wrapped FontString metric, corner seams, actual visual parity and secure interactions. This pass provides host-Lua benchmarks only.

## Current Step refinement

The follow-up at baseline `b4bf9cd` limits its runtime changes to Forever player Current Step cards. RestedXP anchors the native title nine units above each card, and starts quest content ten units below the card top. The skin seats the existing label inside the chamfer, budgets the larger of the title-frame and text heights, and reserves the remaining inset in the native AceGUI widget height. The native content-height callback receives the original budget so quest text, links, checkboxes and icons keep their existing space. The one-unit rule shares the card's warm surface, and the existing EUI rim uses 72% artwork opacity. The background slider still drives the card fill. Card ownership, positioning, native resize behavior and the approved V1 path are preserved. Standard restores the saved native title/content anchors and both height methods, including when a pooled card is reused after a theme change.

The supplied screenshot shows a partially visible row under the header and another above the footer, with full intervening rows wrapping within their separators and number gutters. The native scroll widget offsets its content behind a fixed viewport, so rows can be partial at either edge. Source review and the existing narrow/wide, pooled-row, badge-width and scroll-extent fixtures found no additional in-row clipping defect. The follow-up keeps the guide-list measurement, gaps, scroll offset and clipping unchanged. See [native viewport behavior](https://github.com/RestedXP/RXPGuides/blob/b4a0f99a2ceac856f75a11594bcaa19886236a01/UI/V2/Core.lua#L1627-L1659) and [native player card height and anchors](https://github.com/RestedXP/RXPGuides/blob/b4a0f99a2ceac856f75a11594bcaa19886236a01/UI/V2/Core.lua#L2935-L3039).

Five rotating host-Lua trials compared the same fixture with the adapter disabled, at `b4bf9cd`, and with the refinement. The existing 120-operation list and resize workloads are unchanged. The additional active-card workload updates three cards per operation for 120 operations. Timings are host CPU in milliseconds. The separate call and scan counters describe one warm operation.

Values are native / baseline / candidate.

| Workload | CPU ms | Total calls | Child/region reads | Churn KiB |
| --- | ---: | ---: | ---: | ---: |
| V2 row update | 0.606 / 0.949 / 0.948 | 81 / 125 / 125 | 0 / 0 / 0 | 14.9 / 33.5 / 33.5 |
| V2 width change | 10.933 / 34.296 / 34.388 | 1520 / 5785 / 5785 | 0 / 0 / 0 | 5062.6 / 6424.4 / 6424.4 |
| V2 update three Current Step cards | 0.256 / 1.356 / 1.703 | 29 / 221 / 245 | 0 / 0 / 0 | 36.2 / 162.9 / 162.9 |
| V1 step | 0.385 / 10.510 / 10.261 | 59 / 1718 / 1718 | 0 / 0 / 0 | 28.6 / 570.1 / 570.1 |
| Reopen | 0.078 / 8.835 / 8.420 | 7 / 1689 / 1689 | 0 / 57 / 57 | 0.0 / 940.0 / 940.0 |
| Guide switch | 2.458 / 47.104 / 46.568 | 206 / 6158 / 6158 | 0 / 57 / 57 | 1403.6 / 4116.1 / 4116.1 |
| V1 ↔ V2 | 0.214 / 11.537 / 11.159 | 96 / 4486 / 4486 | 0 / 79 / 79 | 12.4 / 583.3 / 583.3 |
| Theme change | 0.027 / 17.799 / 18.399 | 7 / 10302 / 10302 | 0 / 57 / 57 | 7.0 / 2255.3 / 2255.3 |
| Closed idle | 0.061 / 0.052 / 0.076 | 2 / 2 / 2 | 0 / 0 / 0 | 0.0 / 0.0 / 0.0 |

List, resize and V1 operation counts and heap churn match the baseline. Active cards incur an extra 24 calls per three-card operation for header sizing and height delegation, with identical warm heap churn. Each card adds one rule texture on first styling. Warm probes created zero frames or textures and installed zero hooks. No client FPS or memory measurements were made.

The added fixture checks two card owners, different label heights, reserved body space, per-card resizing, restored geometry, pool reuse, and opacity endpoints. Live verification should compare the same multi-step V2 guide at a narrow and wide width, including a screenshot while scrolled between steps. Check title and rim alignment, checkbox and quest-link interaction, the step numbers in fully visible rows, and switching to Standard and back.

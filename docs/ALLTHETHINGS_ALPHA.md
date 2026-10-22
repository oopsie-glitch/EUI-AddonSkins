# AllTheThings alpha

Branch: `skin/allthethings-initial`, based on v1.5.2. Untagged development build; no CurseForge or Wago publication. The in-game version remains the current stable base until release integration.

## Coverage

- Existing and dynamically created ATT collection windows: main list, mini list, World Quests, searches and other popouts using ATT's shared window system.
- Borderless theme panels with a restrained lighter centre, close buttons, narrow scrollbar grips and readable list fonts/hover feedback.
- ATT addon-options pages: checkboxes, action buttons, edit boxes, sliders and scrollbars. Only ATT's registered objects and owned UI children are inspected.
- ATT's multiline import/export dialog, preserving text selection, native contents and submission actions.

Collection text colours, inline icons, completion summaries, map highlights, rarity artwork, row geometry, window movement/resizing, native actions and ATT profile settings remain owned by ATT. No top accent strip is added. Checkboxes and sliders use the selected EUI accent.

## Implementation and checks

Reviewed ATT `master` at `0287e562bb244536e088430a72a38237f1046086`, especially `src/UI/Window Definitions.lua`, `src/Settings/Settings.lua` and `src/base.lua`. The separate visual background avoids changing the backdrop/colour values which ATT records to profiles.

New windows are observed through `OnWindowCreated`. Pooled rows are restyled after `DefaultRedraw`, the completed visual stage. The integration never calls `GetWindow`, iterates collection data, creates lazy rows, scans UIParent, replaces AceGUI, or installs an OnUpdate loop. Settings construction is batched; repeated enable/disable updates affect the individual control.

`tests/allthethings_spec.lua` covers lazy rows, dynamic windows and settings controls, preserved colours/backdrops/actions, multiline dialogs, theme/accent changes, disabled/protected frames, combat deferral and stable object/hook counts over 100 simulated redraws. Full regression and package checks run through `python3 scripts/package.py`.

These mocked checks do not establish in-game appearance, client compatibility or taint safety. Shared Blizzard tooltips and static popups are not independently restyled by this adapter. ATT versions using different UI internals may need additional coverage.

The linked Azilroka/AddOnSkins adapter was inspected for context only. Its restrictive `AddOnSkins/License.txt` does not grant general copying into this MIT project; no source or assets from it are included. The new adapter is original code using EllesmereUI's public API. ATT and EllesmereUI are installed separately.

## Performance follow-up (alpha.2)

The initial alpha created fresh font-hook closures on every row visit even though the shared hook guard discarded them. It also repainted checkbox textures/anchors on repeated Enable and OnShow callbacks. These paths now bind font hooks once, paint unchanged controls once per theme generation, and update label colours only when enabled state changes. A completed-construction batch still repaints newly initialized controls. Native font resets remain synchronous; theme changes repaint registered controls.

Row work is restricted to ATT's visible row budget with `rawget`, avoiding lazy pool creation. Hidden windows return immediately. Hover texture styling is applied once. ATT profile backdrops, row dimensions, collection colours and native callbacks are preserved. No shared helper was changed.

Reproduce the comparison from the repository root:

```
python3 benchmarks/run_att.py --baseline
python3 benchmarks/run_att.py
```

The baseline is the exact initial-alpha adapter from `f0e88253de6f0f077fb8ed7aace8e5c8ba965ff8`. Both recorded runs used the same source-shaped Lua 5.4 fixture and seven trials. The historical initial-alpha adapter no longer satisfies the later scrollbar assertions, so rerunning `--baseline` now requires aligning that fixture; the current adapter benchmark still runs. Table values are median elapsed times; allocation figures are GC-stopped temporary Lua growth for that trial.

| Simulated workload | Initial alpha | Optimized alpha |
| --- | ---: | ---: |
| 2,000 redraws of 80 visible rows | 320.855 ms / 45,156.656 KiB | 187.194 ms / 156.625 KiB |
| 200 bursts enabling 100 already enabled settings | 182.368 ms / 22,970.500 KiB | 13.470 ms / 1,562.812 KiB |
| 200 bursts showing 100 styled settings controls | 167.301 ms / 21,408.000 KiB | 14.702 ms / 0.375 KiB |

Both builds create zero UI objects or new hooks in these warm workloads. The optimized build also makes zero font, checkbox and colour writes in them. Fonts reset by ATT, real enable/disable changes, theme changes and newly created controls are separately covered by regression tests.

These are mock CPU/allocation measurements, not WoW memory or FPS measurements. The hook mock allocates argument/return tables (including when the skin is disabled), and UI methods are simplified. Absolute timings vary by host. No real-client profiling was available; startup is a one-time inspection of existing ATT-owned windows/settings, while the absent-target factory remains deferred. No polling or per-frame skin loop is installed.

## Scroll controls (alpha.3)

ATT's collection lists use a legacy texture-thumb slider. EllesmereUI's public `ScrollBar` primitive targets modern `Track.Thumb` frames, so the initial adapter narrowed the stock thumb without replacing its artwork. Legacy lists now use the existing legacy-slider helper: flat accent-coloured grip, thin neutral track and public EUI page-arrow buttons with subdued borders. Modern options scrollbars retain the modern primitive with visible themed steppers. Native values, thumb height, click handlers and slider hit areas remain unchanged. The stock corner grip is replaced by the collection's existing neutral resize indicator; the native window resize action stays intact.

Regression coverage includes both scrollbar families, up/down click returns, scroll values, drag-area dimensions, accent refreshes and stable warm redraw allocation/hook counts.

## Background opacity (alpha.4)

Open Options > AddOns > All The Things > EUI AddonSkins. Background opacity defaults to 65% and is adjustable from 0–100%. The choice is saved in EUI AddonSkins, applies immediately to existing and new ATT collection windows and its multiline dialog, and survives theme changes. Text, icons and controls remain fully opaque. ATT's own saved backdrop and profile colours remain unchanged.

Dragging the slider updates only the adapter's background layers, without row traversal, font writes or a full skin refresh. Changes made during combat defer until combat ends; disabled skins do not apply them. Regression coverage includes persistence when reopening the page, new windows, theme refresh, foreground opacity, unrelated settings and stable object/hook/font counts across the full slider range.

## Auction-house attachment (alpha.5)

The `Auctions` collection panel uses ATT's normal window factory and now explicitly binds its completed `UpdatePosition` stage. Retail creates `AuctionHouseTab` lazily in that stage; the Frame-based side tab receives EllesmereUI's public button surface and an isolated selected accent marker (the public Tab primitive requires Button-only methods) while retaining ATT's logo, checked state, native mouse-up handler and shared-sidebar placement. No auction query, scan, database rebuild, window factory call or sidebar-wide walk is performed by the skin. Other addons' tabs remain untouched. Existing ATT window opacity applies to the auction panel.

Regression fixtures cover late tab construction, pre-cache window events, preserved multi-value positioning/toggle returns, logo/size/sidebar geometry, selected/theme state, disabled/combat guards and 100 repeated positioning/selection calls without new objects or hooks.

Task ZIPs contain the collection from their own branch. This ATT alpha does not include unmerged RCLootCouncil, GRM or SimulationCraft skins; installing another task ZIP replaces the collection runtime. Combine selected branches on a separately validated release/integration branch before distributing one build containing them all.

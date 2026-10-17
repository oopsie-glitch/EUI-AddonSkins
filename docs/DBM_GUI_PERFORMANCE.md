# DBM GUI performance — alpha.23

The DBM skin previously hooked ShowTab, DisplayFrame, UpdateMenuFrame and ClearSelection to full synchronous refreshes. Nested navigation repeated the main-window walk, visited hidden option panels and refreshed active timers/warnings/aura previews. GUI font discovery also reapplied unchanged fonts; native FontObject shadow setup could re-enter our font hooks.

## Changes

- DisplayFrame styles only the completed page synchronously. This consumes the earlier queued OnShow request, keeping immediate styling without a second pass.
- Tab/category selection updates the existing sidebar and tab state. Sidebar scrolling stays in the sidebar; page scrolling and control callbacks coalesce within their page.
- Hidden DBM panels are excluded until first display. New controls and same-count child replacements remain discoverable through native display/construction/scroll/show callbacks.
- Ordinary navigation does not enter HUD refreshes. Explicit/manual, theme, load and enable refreshes retain HUD discovery and combat deferral.
- GUI font state is cached against actual font/size/flags and the requested EUI font. Native font-object changes invalidate it immediately. Full refreshes invalidate the generation, including shadow-only theme changes. EUI's complete Font primitive is guarded against re-entry and semantic text colors/alpha are preserved.
- Native tab artwork is discovered once; existing fade guards handle native redraws. No new polling or OnUpdate hooks are added.

Bar geometry, colors, indicator layout, saved settings and native actions are unchanged.

## Shared helper scope

Scoped.lua adds an optional controlRefresh callback and an optional exclusion argument to RefreshControlsNow. DBM is the only adapter opting into the new callback. Existing callers in Altoholic, ItemRack, Details and Gargul keep their original one-argument behavior. Other scoped adapters (including Questie, PallyPower, ThreatClassic2, AtlasLoot, Attune, BugSack, GTFO, KiwiFarm, Myslot and What's Training) retain the previous default coalesced callbacks. The full regression suite and a focused default-versus-opt-in test cover that boundary.

## Measurements

Operation counts from the Lua mock harness, using the previous alpha.22 runtime at `820e067dbae80ad7bc47f400dc683a9015f4a789` as the baseline. The navigation fixture retains 20 hidden pages with 40 controls each and simulates nested ShowTab → UpdateMenuFrame/DisplayFrame calls for ten switches.

| Work over ten switches | Alpha.22 | Alpha.23 |
| --- | ---: | ---: |
| Full main-window scans | 30 | 0 |
| Selected-page-only scans | 0 | 10 |
| Hidden-control visits | 24,000 | 0 |
| SetFont writes to one unchanged label | 90 | 0 |

Separately, 100 construction callbacks change from one full scan to zero full scans. A HUD fixture performs 100 navigation callbacks with zero timer-pool walks, zero font writes and no new objects/hooks; a subsequent manual refresh still discovers/repaints the active timers. The existing 1,000-countdown-tick and 25-new-timer tests remain intact.

## Verification and limits

`python3 scripts/package.py` passes all 19 suites, Lua syntax, manifests/version checks and the 37-file single-folder installation archive. New regressions cover hidden/first-display pages, synchronous OnShow consumption, dynamic controls, page/sidebar scroll bursts, native font/shadow resets, semantic text colors, construction bursts, combat navigation, disabled/enable transitions and explicit refreshes. Existing HUD tests cover late GUI/API arrival, theme/accent changes, timer reuse, protected/secret guards and preview actions.

These are simulated operation counts, not measured game CPU time, FPS or memory usage. DBM's own lazy page construction and layout still take time. Actual in-game smoothness, rendering and taint behavior have not been verified in this environment. The alpha remains untagged on skin/dbm-refinement and is not published to CurseForge or Wago.

## API sources reviewed

- [DBM MainFramePrototype](https://github.com/DeadlyBossMods/DeadlyBossMods/blob/master/DBM-GUI/modules/MainFramePrototype.lua): nested navigation, selected-page state and deferred resize.
- [DBM PanelPrototype](https://github.com/DeadlyBossMods/DeadlyBossMods/blob/master/DBM-GUI/modules/PanelPrototype.lua): lazy panel/control construction.
- [EUI skin API](https://github.com/EllesmereGaming/EllesmereUI/blob/main/EllesmereUIBlizzardSkin/EllesmereUIBlizzardSkin_SkinAPI.lua) and [window engine](https://github.com/EllesmereGaming/EllesmereUI/blob/main/EllesmereUIBlizzardSkin/EllesmereUIBlizzardSkin_WindowEngine.lua): Font primitive, font/shadow setup and theme callbacks.

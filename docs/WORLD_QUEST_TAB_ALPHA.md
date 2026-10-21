# World Quest Tab alpha

Branch: `skin/worldquesttab-initial`. Untagged alpha.1 based on main 1.5.2; no CurseForge or Wago publication.

## Coverage

- World Quest Tab 12.1.05, inspected at upstream commit `96690f6d6af12e9b94618f186b536b4bba40e988`. Retail layout; older layouts from the historical reference skin are not claimed supported.
- Dark list/settings panels with a gentle center lift; flat sort/filter controls, original search input/instructions, slim scrollbars/arrows and native map tab artwork.
- Pooled settings: clean checkboxes, compact slider grips/steppers, numeric/text inputs, dropdowns, confirm/cancel actions, color swatches/reset controls, category expansion arrows and quest-list previews.
- Quest rows use theme fonts, a visible hover and accent tracking wash. Native quest colours, rarity/favourite backgrounds, reward/faction/warband icons, amounts, timers, tracking visibility and click actions remain intact.
- Owner-scoped menus and texture-only owned quest/comparison tooltips. Shared Blizzard tooltips, map pins, calling/covenant artwork and mechanics remain under their existing owners.
- Flight/fullscreen container chrome uses the public panel API without changing native size, anchors, movement, visibility or saved settings.

## Existing native EUI support

World Quest Tab includes its own basic EUI integration since 12.1.02. This adapter installs after native startup, reuses idempotent public primitives and registers additional instance/ScrollBox callbacks. It does not replace the built-in integration, intercept EUI registration, alter BWQDB, shrink the map tab again, copy external integration code or manipulate its toggle. The collection toggle controls our refinements; the native integration has its own enable setting.

## Performance and verification

No added OnUpdate, polling, global AceGUI/frame factories, quest-data walks, data-provider rebuilds, native setting changes or recursive UI scans. Completed ScrollBox row initialization styles one frame; native UpdateState font resets are repaired on that settings instance. Theme changes and combat recovery enumerate only active viewport frames. Settings do not trigger collection-wide refreshes.

`python3 scripts/package.py` verifies Lua syntax, all 23 regression suites, client manifests/catalogs, version consistency, the exact MIT license and the 40-file single-addon archive. Tests include pooled frames, native callbacks/actions/returns, built-in EUI cooperation, disabled/protected frames, late combat acquisitions, semantic timer/reward colours, category state and theme refreshes.

Mock benchmark: 1,000 warm quest/settings initialization callbacks add zero UI objects, hooks, font writes, hierarchy scans or viewport enumerations. A separate 100 native font-object resets require 100 local label repairs, with no scans or UI allocations. These are simulated counts, not measured in-game CPU/FPS figures. Actual WoW appearance, taint and client rendering remain unverified.

The reference implementation was inspected for historical frame coverage. No target code, reference skin code, external libraries or third-party assets are bundled.

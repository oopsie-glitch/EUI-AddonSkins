# Gargul refinement

Untagged branch: `skin/gargul-refinement`, based on stable v1.5.0. Keep the addon version at the stable baseline on this focused branch; identify the test ZIP by branch and commit. No CurseForge/Wago tag, upload or main-branch change is part of this work.

## Scope

- Gargul-local routing through the existing Scoped control-refresh/exclusion extension. Shared Lua defaults and other integrations are unchanged.
- Completed settings sections repaint their content once before returning; construction, OnShow, click and scroll bursts are consumed/coalesced. The sidebar refreshes independently. Generic dialogs repaint their owned windows; new windows still receive an initial discovery/shell pass.
- No Interface registry walk per checkbox, global AceGUI hooks, polling or timer-update hooks. Relative `SetFont(rem, flags)` wrappers remain intact; unchanged fonts are not rewritten during navigation. Full load/theme refreshes still discover late adapters and update styles.
- One matte public-API panel per window; no top accent/header strip. Neutral sidebar selection with an accent marker, softened buttons, compact accent checkboxes and slim scroll thumbs. Scroll ranges, proportional thumb heights, settings values, callbacks and text/row geometry remain native.
- AceGUI dropdown pullouts use a non-interactive child panel. Native backdrop, font, check/arrow tint and desaturation are restored on close/release/disable or foreign-owner reuse; pooled native menu frames are not enrolled in EUI's persistent skin registry.
- Explicit `Gargul.RollerUI.draw` support outside Interface: matte roll window/buttons, square item icon and flat CandyBar fill. Native roll actions, item-link text/rarity, countdown values/threshold colours, right-click behavior and dragging remain owned by Gargul. Subsequent roll-tracker bursts refresh only the roll window.

## Source review

Gargul v8.0.1, commit `7cc1fc1713ca74375398c36fb48d4dca2c7d32a6`, matching the supplied screenshots. Reviewed Settings/Overview.lua, Interface.lua, RollerUI.lua, AceGUI dropdown/checkbox/frame implementations, lib-st Core.lua and LibCandyBarGargul's real owner-Frame/child-StatusBar structure. No upstream code or assets are bundled or copied.

- https://github.com/papa-smurf/Gargul/blob/v8.0.1/Interface/Settings/Overview.lua
- https://github.com/papa-smurf/Gargul/blob/v8.0.1/Interface/Interface.lua
- https://github.com/papa-smurf/Gargul/blob/v8.0.1/Classes/RollerUI.lua

## Automated evidence

Expanded `tests/legacy_controls_spec.lua` uses the real skin/Scoped/Widgets code and mocked native frames:

| Simulated operation | Result |
| --- | --- |
| 10 settings switches with 200 control registrations | 10 page scans; zero whole-window/unrelated-window scans; zero unchanged-label font writes |
| 100 sidebar callbacks in one burst | 1 sidebar scan; zero whole-window scans |
| 100 scroll or click callbacks in one burst | 1 active-page scan |
| 100 roll-tracker callbacks in one burst | 1 roll-window scan; zero settings-window scans or additional visual layers/hooks |

Coverage includes immediate dynamic-control styling, pooled menu close/release/foreign reuse, disabled menus/skins, native actions and returns, semantic colours/alpha, theme changes, combat deferral, missing targets and repeated hook/object reuse. `python3 scripts/package.py` validates all 19 suites, Lua syntax, manifests and the 38-file installation ZIP.

These are traversal/write counts in a mock, not measured WoW CPU/FPS improvements. Live layout, first-use timing, taint behavior and rendering cannot be established without a WoW client. Gargul still owns the cost of constructing/releasing AceGUI pages; this change removes redundant skin work rather than replacing that lifecycle. Settings are not preconstructed and no manual in-game verification is required to build this test package.

# KiwiFarm menu alpha

Based on stable 1.5.1; separate from the RestedXP arrow/options alpha. Untagged
branch `skin/kiwifarm-menu-reuse`. No automatic CurseForge or Wago upload.

## Findings and change

The old ShowMenu completion callback registered the named launcher and queued a
full stats-window refresh. Owner registration repaints only changed bindings,
so it does not guarantee a final paint after native reconstruction on reuse.

The callback now registers both the known named launcher and the actual visible
DropDownList1 owner when it is named KiwiFarmPopupMenu, then performs a synchronous
popup-only repaint. Main-window discovery is no longer requested by menu opens.
The redundant KiwiFarm combat-end full refresh was removed; the existing shared
popup event handles recovery. No shared runtime helpers changed.

The supplied KiwiFarm 2.26 source was reviewed for menu creation, submenu refresh,
text updates, layout, animation and combat callbacks. It uses legacy dropdowns,
not AceGUI. Our skin does not hook its recurring RefreshText/animation callbacks,
replace its OnUpdate handler, or alter its native stats calculations or settings.
Its showMenu function can create a launcher per open because its local caller
never saves that launcher. This alpha follows the active owner; it does not
replace native frame creation or change third-party source.

## Verification

The regression fails against the previous KiwiFarm handler. With the fix, 100
simulated close/reopen cycles retain immediate menu/submenu styling, with zero
full stats-window refresh requests, extra visual layers or duplicate hooks after
warm-up. This measures mocked callback behaviour, not in-game CPU, memory or FPS.

Checks also cover launcher recreation/stale globals, dynamic submenu rows, native
return values/actions/semantic colours, unrelated-owner restoration, disabled
skins and combat recovery. Full Lua/regression/packaging validation passes. The
archive contains the original runtime assets and MIT license in one addon folder.

Actual in-game appearance, renderer ordering on every client version, performance
and taint safety have not been independently verified in this environment.

## Visual follow-up

KiwiFarm opts into the shared menu helper's new optional `noAccent`, `chevrons`
and `isHeading` settings. Existing callers omit these options and retain their
previous appearance. The RXP confirmation helper is on a separate branch and
is not part of this change.

- Remove repeated menu/stat-window top accent strips.
- Replace gold submenu artwork with EUI's existing neutral right chevron.
- Cover legacy globally named Check/UnCheck art with the existing flat markers.
- Apply the current accent to localized menu headings only, retaining quality,
  status and disabled text colours. Restore heading colour and artwork on reuse.
- Apply EUI typography without the heavy native outline to the two stats labels.
  Preserve user-selected size, text content, native anchors and alignment.
  Native LayoutFrame SetFont calls are repaired locally; SetText/timer updates
  trigger no skin work. Native stats fonts are restored on disabling the skin.

The more restrained font treatment improves separation without resizing or
repositioning the stats window. Tests cover 100 data updates with zero extra
font writes, font-size/return preservation, native font resets and restoration,
heading-row reuse, original artwork restoration and bounded marker allocations.

## Appearance options

Right-click KiwiFarm or its minimap button, then choose **Appearance > AddonSkins**.

- Background opacity: 0–100% in 10% steps, or **Use KiwiFarm opacity** to follow the native background colour picker's alpha. Default: 90%.
- Menu background opacity: separate 0–100% choices, plus the 95% default.
- Background style: flat charcoal or soft centre highlight (default).
- Show accent line: off by default; enabled lines follow Blizzard Skins+ accent colour/visibility preferences.
- Reset skin settings: reset these KiwiFarm skin options only.

Settings are saved under EUIAddonSkinsDB.kiwiFarm. Native KiwiFarm colour values, font size, dimensions, anchors, stats, visibility and whole-frame fade handlers remain unchanged. Opacity affects only owned background layers. The root's old shell textures are suppressed so 0% is actually clear; text stays independent. Decorative layers are excluded from scans from their first creation.

A guarded initialization post-hook appends one submenu to the localized Appearance list of KiwiFarmPopupMenu only, before its native renderer displays the menu. Native menu tables and actions are retained; the submenu is hidden when the skin is disabled. Settings changes update owned backgrounds immediately and refresh the current owned native submenu's checkmarks. Combat-time visual changes wait until combat ends. No polling or stats/data-update hooks are added.

The full package check passes Lua syntax, regression suites, manifests, versions, MIT license and the single-folder runtime ZIP. Fixtures verify saved values, 0/100% opacity, untouched text/frame alpha, native colour-picker cooperation, both background styles, accent toggles, independent legacy-menu opacity, reset isolation, first-open injection/deduplication, unrelated-owner guards, menu regeneration and combat/disabled handling. Repeated opens retain zero full-window refreshes and stable background allocations. These are mock results; in-game rendering and taint remain unverified.

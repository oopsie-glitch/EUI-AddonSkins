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

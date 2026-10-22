# ThreatClassic2 integration

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

Included in stable version `1.2.0`, promoted from the tested `details-alpha` builds.

Enable or disable the ThreatClassic2 skin through the collection’s EUI third-party addon toggles. Reload after disabling it. ThreatClassic2 is installed separately.

The meter shares `MeterStyle.lua` with Details: dark body/header colours, EUI meter fonts, accent title colour and bar texture. The header gear opens ThreatClassic2’s native right-click menu. Context menus and standalone/embedded Ace options are scoped to ThreatClassic2.

Native threat values, percentages, TPS, warning/class colours, ignite indicators, sorting, visibility, column settings, row height/spacing, window size/position/scale, dragging and resizing remain native. Keeping row geometry preserves ThreatClassic2’s visible-row calculation. No configuration or saved variables are changed. Details is not required.

No threat-update hooks, skinning OnUpdate handlers, periodic timers or UIParent scans are added. Appearance setters are guarded and idempotent; combat changes are deferred. Modern pooled menus restore their original styling when hidden or transferred to another owner.

Run `python3 scripts/package.py` for Lua syntax validation, all regression suites and ZIP verification. The ThreatClassic2 suite uses source-shaped mocked frames to verify native redraws, data/actions/geometry, options, late rows, combat/toggles and repeated refreshes. The menu suite covers modern and legacy owner transfer. Actual in-game appearance has not been verified.

Source reference: https://github.com/dfherr/ThreatClassic2 . No upstream code, assets or dependencies are bundled.

Modern menus use compositor-managed AttachTexture regions and SetFontObject with cached standalone FontObjects. They never index or call SetFont on a compositor FontString or create raw regions on compositor controls. Legacy menus keep their existing adapter. Regression tests forbid SetFont lookup and raw texture creation, simulate 50 compositor resets/reopenings, and check bounded texture/font reuse, native actions and restoration.

Menu element initializers reapply the font after in-place checkbox refreshes. They are installed once per description and gated by the current menu acquisition, owner and skin toggle. Tests cover repeated checkbox responses before queued work, disabled styling and owner transfer.

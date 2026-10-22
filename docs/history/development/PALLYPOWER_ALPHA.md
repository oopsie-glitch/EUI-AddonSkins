# PallyPower beta alpha

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

Version: `1.3.0-alpha.7` on the untagged `pallypower-alpha` branch, based on `development` at `7e8eba3`. Includes the existing Altoholic alpha fixes. No CurseForge/Wago release or GitHub Release is created.

## Target

The supplied `PallyPower.zip` reports `v1.5.22-classic`, includes the Forever beta API/layout adapters and uses `PallyPower_Vanilla.xml` for interface 16001. Archive SHA-256: `1e63fe301b2a3597e5b249cc33221cc9caa494dc94ca02fc1dba76fda40cf969`.

PallyPower and its libraries/assets are installed separately. None is bundled, copied into the skin or modified. Other PallyPower versions have not been validated by this alpha.

## Styling

- Alternating assignment column fills and brighter headers add separation without outlines; their height follows the native separators.
- Assignment window: EUI shell without a top accent or native dividers, borderless buttons, fonts, close/resize controls, square spell/class icons and ordinary controls.
- Native Ace options: standalone and embedded options, no top accent, themed tabs, buttons, checkboxes, inputs, sliders and dropdowns. SharedMedia background/border selectors and their owner-scoped popups are styled while preserving previews. Horizontal slider handles are 10×16; vertical handles are 8×18. Ace checkboxes use a flat 14-pixel plate and native check visibility/value handling. Native heading/title artwork is suppressed and the status panel uses EUI styling; only PallyPower-owned frames are scanned.
- Assignment popup menus: the existing owner-scoped LibUIDropDownMenu adapter.
- Buff controls: EUI fonts and square icons, flat existing backdrop textures with softer borders. Native buff-status background colours, timer/severity colours, range/death indicators and spell icons are retained.
- Forever title strip: themed panel/accent when the frame is unprotected. Protected title strips use the conservative region/backdrop path.

## Secure controls

Buff-button styling runs only out of combat. It changes existing texture/font regions and backdrop presentation, without scanning or adding hooks to secure controls. It never changes secure attributes, click registration/scripts, frame anchors/sizes/parents, visibility/alpha, key bindings or the Forever flyout cover. PallyPower continues to manage all assignments, casting, timers, status colours, layout and settings.

Lifecycle/layout/skin/options hooks handle lazy controls and native appearance resets. No hook is added to the recurring buff-status updater or assignment grid OnUpdate. Theme refreshes use EllesmereUI's public skinning API and getters. The existing combat-recovery event defers styling until combat ends.

## Checks

`python3 scripts/package.py` validates Lua syntax, runs fourteen regression suites and inspects the install ZIP. The PallyPower fixture covers optional loading, lazy Ace options, menu ownership, icon/colour preservation, native calls/returns, protected controls/attributes/layout/flyouts, combat deferral, missing libraries, theme changes and repeated refreshes. Automated checks cannot establish actual in-game taint or appearance; no in-game verification is claimed.

## Options performance

Checkbox SetType/SetDisabled callbacks repaint only their own control. Tab construction refreshes coalesce; the completed SelectTab callback still styles the page immediately. A regression test performs 100 checkbox reset callbacks with zero assignment-window region reads. This is a mock-environment count, not an in-game timing measurement.

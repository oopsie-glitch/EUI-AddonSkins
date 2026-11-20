# Details cosmetic ownership audit

Baseline main `3553aca8e386c77be2c1af20a719117c14199df2`. Related drafts #87 at `9dfee943a69800f873f27525e0ed1453b8a6fc62` and #88 at `f28ada14300cd075ba859bb751d0514402aa7d9e` remain independent. This branch carries #88's geometry-free Cooltip correction and #87's native toolbar geometry ownership into a cosmetic-only adapter.

## Ownership

| Source area in the old implementation | Classification | Refactored responsibility |
| --- | --- | --- |
| Details.lua Meter, native window decoration and fills | Essential cosmetic styling | EUI body/header materials inside existing native frame bounds |
| DetailsLayout Window fixed header, replacement labels and Title timer formatting | Unnecessary interference | Native header height, font, title content, enabled state and timer |
| DetailsLayout Row and Details.lua Row/Rows | Unnecessary interference | Native damage/healing bar texture, fonts, size, alignment and data |
| Details.lua Meter SetBarSettings/SetBarRightTextSettings | Unnecessary interference | Native height/spacing/format, with no skin calls to those setters |
| DetailsLayout Align/button geometry observers | Unnecessary interference | Native toolbar dimensions, anchors, scale, visibility and hitboxes |
| Toolbar icon textures | Optional cosmetic styling | Existing native texture regions, retaining native fade, hover, pressed and disabled handling |
| Native title accent | Optional cosmetic styling | Concrete text color only, following EUI's header accent setting |
| Details.lua Backup/RestoreSettings/Recover | Unnecessary interference | No automatic native setting writes or stale backup restoration |
| Menus, options, dialogs, designer label and control art | Optional cosmetic styling | Existing menus module, with native callbacks, semantic colors and owned layout retained |
| Raid menu receiver correction and menu ownership restoration | Compatibility handling | Existing scoped adapter retained |
| Cooltip SetBackdrop during show/hide | Safety handling | #88 tint-only restoration, no backdrop reconstruction |
| Tiny Threat font and texture art | Optional cosmetic styling | Existing independent Tiny Threat opt-in; latest native cosmetic snapshots restored conditionally |
| Tiny Threat host instance formatting and geometry | Unnecessary interference | Native host settings |
| Generic input/slider cosmetics and value-editor compatibility | Optional cosmetics and compatibility | Existing options module retained |
| Protected/forbidden/secret checks and combat recovery | Safety handling | Retained; no secret geometry calculations |

## Timer and native settings

The removed DetailsLayout.Title generated ` (%d:%02d)` from the selected combat even when Details' native timer was disabled. It also hid the native title and created two replacement FontStrings. The new adapter creates no title text and reads no combat time.

Current Details source `2efa4b10628e0e4a91c346138cf8325e81d0a43c` registers **Options > Designer > Title Text > Show Encounter Timer**, backed by `attribute_text.show_timer`. The same Title Text object exposes native enabled state, font, size, offsets and color. Details also owns separate arena, battleground and always-show timer fields; their semantics remain native.

The Designer Title Bar object exposes native height and toolbar icon size, spacing, anchor side, offsets and visibility. Its size callback calls ToolbarMenuButtonsSize, which stores menu_icons_size and invokes ToolbarMenuSetButtons. Those native functions own actual geometry.

## Settings compatibility

Existing menus, meter and tiny keys retain their saved booleans. The new toolbar key initially follows the old meter or Tiny Threat preference when absent; an explicit false is retained. Reading the central settings page does not materialize defaults. All four controls share setters with the legacy page and quick menu.

The meter preference now affects surfaces and optional native title accent, without changing bar settings. Existing legacy backups are retained inert in EUI AddonSkins SavedVariables. Their values are ambiguous after later user edits, so the adapter neither reapplies nor deletes them. Users can choose their desired native bar settings in Details. No Details SavedVariables migration is performed.

MeterStyle.lua is shared with ThreatClassic2 and remains unchanged. The Details adapter stops using its bar geometry/font fields for ordinary meter rows. Tiny Threat retains its separate optional cosmetic treatment.

## Verification boundaries

Automated fixtures cover independent preferences, native customization across refresh/toggles, native title and disabled timer, independent windows, no ordinary row-update hooks, native toolbar geometry, old backups remaining inert, pooled menu ownership, secret-width hide, combat recovery, and bounded artwork. Pinned source checks and package checks run in GitHub Actions. Actual WoW rendering, secret-value taint, saved preferences after a real client reload, and long-session behavior require in-game verification.


## Surface restoration and recommended setup

The visual restoration pass corrects three independently verifiable paths. PR #90 parented its header material to UPFrame, whose alpha Details.InstanceColor controls, so native skin decoration transparency could erase the material. It painted the body on baseframe beneath the native background canvas and did not mask the fullWindowFrame rounded fill pieces. Its one-time title tint could be overwritten by AttributeMenu's delayed SetFontColor callback; hdrTextUseAccent=false also incorrectly disabled all EUI title coloring instead of using EUI's configured custom title color.

The header material now stays on the owned meter, anchored to the native header bounds. The body material lives on the owned native background canvas, with named native backdrop and rounded fill regions faded while surfaces are active. Neither geometry nor native labels are replaced. A guarded hook on the instance's native title color setter handles the delayed native color reset. It updates the native restoration snapshot and applies the configured EUI title tint without touching text, font, size, alpha, visibility or timer state. Toolbar textures use the approved artwork and restrained normal/highlight/pressed/disabled tint on their native regions.

New, absent addon settings default to meter surfaces and toolbar artwork enabled, menus enabled and Tiny Threat disabled. Existing saved booleans are preserved. Tiny Threat now uses native row settings too; its optional cosmetic switch controls its host surfaces. It no longer has a RefreshRow skin hook.

The recommended preset is always an explicit opt-in. No reliable native untouched-profile indicator was found. Creating or importing a native profile, or changing a native skin, can copy or reset unrelated settings, so this implementation uses the documented per-window SetBarSettings and SetBarTextSettings methods, plus native SetBarRightTextSettings and optional SetSimpleFormattingSettings. A native StaticPopup confirmation lists the current profile, live target window numbers and affected settings. Profile identity, target availability, SharedMedia and combat/protected state are rechecked at acceptance.

The preset initializes the EUI texture, common EUI font and shared size, EUI bar height and spacing, native total/per-second values, no percentage, parentheses, no separator, and disabled custom right text. It preserves class/status color preferences, name/value font overrides, aligned-column mode, title/timer, toolbar geometry and window layout. The current native API has one shared base font size; it cannot reproduce independently forced left/right font sizes through that setter. Native per-column overrides remain authoritative.

SharedMedia names are content-specific. Only explicitly applied media references are recorded in EUI AddonSkins' own settings and registered on the normal addon lifecycle. This keeps native saved media choices resolvable after reload, without changing native preferences or reapplying a preset on theme/profile changes. Native Details profile saving owns persistence. No native profile is created, renamed, imported, restored or selected by this integration.

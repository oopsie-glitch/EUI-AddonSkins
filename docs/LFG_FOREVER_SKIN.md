# LFG Forever Standard skin — isolated test integration

This branch is not selected for v1.6.8. Visual, interaction and taint acceptance in WoW Forever is pending.

## Source and ownership

Authoritative source: https://github.com/user-attachments/files/35335139/LFGForever.zip

- LFG Forever 2.6.0, Interface 16001.
- Archive SHA256: 68529acce2de99476226522242daacd9d277ffecd5b1a8b2d9c12c99febe6a6e.
- Source inspected in GitHub Actions using symbolic constructor, ownership and callback reports; original file contents are not printed or committed. No upstream source or media is redistributed.
- The addon uses its private Lua addon namespace, native Blizzard templates, TabSystem, Menu/DropdownButton and ScrollBox list/tree views. No embedded AceGUI framework is present in this archive.
- Its private BuildWindow/Prepare paths create the named LFGForeverFrame lazily. Content owns FilterPanel and ListPanel; FilterPanel owns TabSystem, WhisperLog, PlayerRatings and SettingsGear.
- Filters build role/class checks, level range, Playstyle/Languages selectors, activity/category selectors, saved-filter actions and the native Search/Role Check controls.
- Lists use completed native view initializers; player ratings retain earned/unearned stars and native mouse handlers.
- The main template's portrait, chrome and inset artwork belong to LFG Forever instances. Blizzard Group Finder, the global Settings canvas, shared tooltips and shared StaticPopup dialogs do not belong to this adapter.

## Implementation

Public EUI Shell, Panel, Button, Tab, Dropdown, Checkbox, EditBox, ScrollBar, CloseButton and Font primitives provide the theme. CreateSoftSkin supplies the established subdued borders; CreateSkinHelper supplies safe, idempotent script/method hooks. Fonts retain native valid point sizes and semantic colors. No EUI/Blizzard global font objects or addon SavedVariables change.

Main content gets one shell, list/filter insets receive panel styling, portrait chrome is hidden, tabs use the EUI selection treatment, and ordinary controls receive flat artwork. Checkbox artwork is compact while native click rectangles stay unchanged. Class/role icons and earned/unearned rating artwork remain native and interactive. Native DropdownButton input is retained for full-field clicks.

The private addon namespace is not extracted with debug APIs. Discovery observes only named addon launchers: keybinding wrapper, slash command, minimap/search buttons, addon-compartment function and the owned Blizzard-side tab. One listing event covers the native auto-open path until the root is discovered, then unregisters. Once bound, warm OnShow uses the cached root; completed view OnInitializedFrame callbacks style only current rows and newly constructed descendants. No native data/communication/rating/profile callback is replaced.

The existing reversible BindPopupList helper handles demonstrably owned root menus. The same public manager post-hook pattern as Myslot observes OpenMenu/OpenContextMenu; foreign owners are rejected before styling. No generic CreateFrame hook, prototype override, UIParent traversal or second menu framework is introduced.

## Deliberately native / remaining limitations

- Shared Blizzard confirmation, save-filter, report-bug and rating-clear popups remain native rather than changing reusable global dialogs.
- Shared GameTooltip and Blizzard Settings content remain under their existing owners.
- Rating stars, class/status/role artwork, action semantics and compact-toggle directional artwork stay native.
- Nested menu frames without a verifiable owner are not styled. Native positioning, checkbox/radio states, dismissal and callbacks are retained. Root Filter/Activity/Playstyle/Language/My Filters/settings/context menus receive the shared treatment.
- Direct private future launch paths are not monkey-patched. Verify automatic opening after posting a native listing, late Blizzard tab loading and first-show order in the actual Forever client.
- Disable uses the collection's established reload requirement, not a new independent restoration system.

## Verification

The full package suite includes the new source-shaped UI fixture and catalog checks for generic/Mainline/Camelot manifests. The checksum-pinned source-contract check verifies actual native constructors, ownership fields, launchers, templates and all three view initialization paths without executing target business logic.

The UI fixture covers dormant/late activation, native lazy construction, return values, three tabs, whole-field dropdown input, native checkbox/star/click behavior, semantic artwork/colors, rows and same-count replacements, owned/foreign menus, theme, combat recovery, disabled state and bounded warm reuse. Hosted medians and object/write counters are recorded in the PR after CI passes. These fixtures are not live WoW rendering, FPS or taint proof.

The install ZIP contains only the EUIAddonSkins runtime collection. The target addon, source archive, docs, tests and inspection scripts are excluded. It does not contain PR #92 or other task branches.

## In-game acceptance

1. With only the normal skin requirements enabled, open from minimap, slash command, keybinding, addon compartment and the Blizzard-side tab; also post a listing. Repeat after /reload.
2. Check Filters, Whispers and Player ratings at ordinary/narrow widths and several UI scales; resize and use compact mode.
3. Open all selectors across their entire fields, choose values, scroll long menus, close with Escape/outside clicks, then open another addon's menu.
4. Search, Role Check, class/role/level filters, saved-filter save/reset/delete, language/playstyle and new/recycled results.
5. Receive/select/remove whispers; change ratings, hover stars, clear ratings and verify class/status colors and history.
6. Open gear Settings, tooltips, context menus and report/save/confirmation dialogs; native borrowed dialogs are intentional.
7. Change EUI theme/accent, disable the skin and reload, test combat entry/recovery and check Lua errors/taint logging.

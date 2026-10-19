# Details integration

Included in stable version `1.2.0`, promoted from the tested `details-alpha` builds. Development history is retained in [ALPHA_CHANGELOG_1.2.0.md](ALPHA_CHANGELOG_1.2.0.md).

## Included

- Meter backgrounds, an independent dark header, EUI title/timer styling, native toolbar controls, row fonts, bar textures, height and spacing.
- Native total (DPS/HPS) formatting with the value column at the right edge; header and footer art suppressed without removing native actions.
- Options, breakdown and report windows; ordinary buttons, switches, dropdowns, inputs, scrollbars and sliders.
- Details-owned Cooltip menus and submenus. Shared popup backdrops/fonts are restored when ownership changes.
- Optional EUI meter appearance matching, without a dependency on its renderer.

Install the release ZIP's `EUIAddonSkins` folder in `Interface/AddOns/`, replacing the previous folder. Details, EllesmereUI and EllesmereUIBlizzardSkin are installed separately. The Details! master toggle appears with the other third-party skins in EllesmereUI. Open `/euidetails` (or Settings > AddOns > EUI AddonSkins: Details) for three independent switches. Quick access is also available by hovering Details' settings icon > **EUI AddonSkins**:

- **Skin menus and options**: enabled by default; reload after changing it.
- **Style Tiny Threat**: independent of normal Details meters; controls the active Tiny Threat host window and plugin row fonts/texture. New installs default to off. Existing alpha users inherit their previous meter setting once to preserve their appearance.
- **Match EUI meter appearance**: disabled by default. Enabling it captures the current managed appearance settings. Disabling restores those settings; UI work waits until out of combat.

Backups are scoped to character, realm, Details profile and window ID. A recovery path restores saved row settings even if EUI does not dispatch the disabled skin after a reload. Settings captured by an older alpha cannot be reconstructed retroactively. The original first alpha changed cosmetic row settings without a backup; this version captures the current settings when first enabled.

## Boundaries

Details retains its own renderer. Additional plugin windows and exact pixel parity with EUI's meter are not guaranteed. Native button visibility and actions are preserved, so the toolbar can have different controls. The combat timer uses the selected Details segment; unavailable/secret times are left blank. Installed EUI meter icons are referenced only when that module is loaded; otherwise native icons are retained. Details retains its class/spec icons, combat data, window positions and actions. Matching temporarily supersedes right-hand custom formats; they are backed up and restored when it is disabled. While meter matching is enabled, the skin manages row height, spacing, texture and native combined-number formatting, plus runtime fonts/header decoration and toolbar positions. Those settings follow EUI until matching is switched off. Other Details appearance settings remain native. 

Fonts use EUI's public font getters. The optional `_EDM_DB.profile.dm` and `_EDM_BarTextures` exports are read only and guarded; these are compatibility reads, not a promised public skinning contract. If unavailable, the skin uses EUI fonts with conservative meter defaults. No EUI or Details code/assets are bundled. The meter's special Blizzard/Classic/Forever border renderers are not copied. Meter-only setting changes can be picked up with `/euiskins refresh` if EUI does not broadcast a theme refresh.

Source inspection used the supplied upstream repositories' current default branches. Automated tests simulate WoW frames, Details events and styling APIs; they cannot verify the actual client appearance. No in-game verification is claimed.

## Verification

Run `python3 scripts/package.py`. It validates Lua syntax, executes all regression suites, checks TOC paths and includes all twenty skins and the MIT license in the install-ready ZIP. Development files and upstream reference sources stay outside the package.

The Details suite covers optional loading, new windows/rows, native return values/actions, untouched data/positions, theme changes, combat deferral, disabled skins, shared menu restoration and warm refresh reuse, independent modes, restoration after repeated toggles and disabled-skin reload recovery, hidden native title bars, toolbar redraws and late startup width/height changes, timer changes and secret-value guards. No polling or combat parser hooks are introduced.

Header icons are drawn on the matching header independently of native button opacity. Native visibility, hover tooltips and click actions remain in use.

Details-owned Cooltip pop-outs and submenus use flat EUI panels, accent hover fills and subtle separators. Native rounded/background layers are suppressed only for Details; warning icons, arrows, status values and actions stay native. Original artwork, fonts and corner mode are restored on hide, owner transfer or disabling menu styling.

Options category buttons use EUI tabs with native page visibility as their selected state. Scoped hooks on category template/icon updates and the native page-selection method keep navigation consistent during page switches. The regression suite simulates template resets around page OnShow and queued refreshes.

DF text entries keep their native layout without Blizzard input expansion. The lazy Designer editor is bound only once it exists: its native selector populates once, selector refreshes style pooled labels directly, and object-selection/disabled-state refreshes synchronously style new controls. Input values, commit functions, editor actions and native lazy construction are retained.

Tiny Threat uses its native plugin ID and host window to select the appropriate styling switch. Native threat text, colours, row anchors and actions remain unchanged. Switching a host between a normal meter and Tiny Threat restores its captured appearance before applying the selected style. Quick controls append to the native settings pop-out; they do not replace its entries. Regression tests cover independent combinations, plugin redraws, view changes, repeated menu builds, restoration and combat deferral.

Header buttons anchor independently to the EUI header, preventing sibling dependency cycles during native redraws. Restoration clears all managed anchors before restoring the original graph, ahead of native skin resets. A scoped adapter corrects Cooltip's receiver for exact native raid-plugin switch callbacks produced by `MontaRaidOption`; plugin selection logic and menu parameters remain native. Regression fixtures reproduce the previous anchor cycle and callback receiver failure.

Raid-menu dispatch supplies the plugin manager explicitly, avoiding the legacy `ExecFunc` refresh that requires absent `CoolTip` metadata on modern toolbar buttons. After switching, the existing attribute button's OnEnter handler rebuilds only the same owned menu. If the handler is unavailable, the stale popup closes. Other owners are left untouched. Tests include the legacy follow-up failure, repeated modern menu refreshes, missing handlers, ownership changes and nil-containing return values.


## Options refinement alpha

Untagged branch `skin/details-options`, based on v1.5.1. Shared helpers, meter styling, settings and release versions are unchanged.

- DF checkbox switches use solid inset accent squares; native value, checked visibility, disabled state and callbacks remain in control. Native toggle widgets keep their knob and visibility model.
- Standalone gold/orange option headings and known window captions follow the selected accent. Warning/description colours and inline colour codes are preserved. Available section labels have clearer contrast; disabled sections stay muted.
- Options/container shells omit the top accent line; active sections retain theirs. The named native options close button uses the EUI close treatment without replacing its action. Ordinary option buttons use softer surfaces, preserving their icons.
- Native dropdown arrows become neutral chevrons. Selected-option artwork and dropdown actions are retained; pooled popup contents are scanned only within that popup on show.
- On DF versions with `SetValueBox`, eligible horizontal sliders use the native numeric editor, reserving 40 UI units inside the existing row footprint. Existing native value-box layouts retain their side/size. Narrow controls and versions without the API keep their native value presentation. Input commit, range clamping and drag callbacks remain native.
- Registered hidden option sections are excluded from scans. Native section selection still applies the completed visible page synchronously. Switch/dropdown/slider template callbacks repaint their own controls rather than scheduling a full-window pass. There is no polling or global framework replacement.

Sources reviewed: Tercioo/Details-Damage-Meter `Libs/DF/slider.lua`, `dropdown.lua`, `label.lua`, `buildmenu.lua`, `frames/window_options2.lua`, `frames/window_options2_sections.lua` and `core/plugins.lua`. No upstream code or assets are bundled.

Validation: `python3 scripts/package.py` runs all regression suites, Lua syntax, manifests and the 39-file single-folder package checks. Source-shaped cases cover native switch values/visibility, disabled/theme/ownership guards, template returns, legacy sliders, existing numeric-editor layouts, unchanged commit handlers, selected icons, hidden-page activation and reusable editors. One hundred switch, dropdown and slider template updates each produce zero full-window scans or additional numeric editors in the mock. Existing meter, Tiny Threat, designer, menu-restoration and combat tests remain in the suite. Automated checks do not establish actual WoW rendering, FPS or taint behaviour.

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


### Options readability follow-up

- Give only the Details options canvas a charcoal base with a broad centre highlight and darker edges. Existing shell texture remains visible underneath; the public panel colour informs the base. Both modern colour-object gradients and legacy alpha gradients are supported, with no extra asset.
- Slightly lift unchecked checkbox fills and add muted one-unit outlines to switches, dropdowns and numeric/text inputs. Visual children do not accept mouse input or alter native control geometry, marker visibility or focus handlers.
- Soften the existing DF row background where a native highlight row is available; its hover visibility and click handlers remain native. No new clickable rows are introduced.
- Create visual layers once, exclude them from control scans immediately (including their construction pass), and repaint the background only when its colour changes. Native resizing handles their anchors; there is no animation, polling or added show-refresh path.

Regression cases check centre/edge alpha continuity, both gradient APIs, theme repaint, non-interactive visual layers, checkbox/dropdown/input contrast, native row actions, unchanged selected icons/marker state, and no repeated visual allocation during template bursts. The complete package checks pass. OLED readability and actual client rendering remain a visual judgement, not something established by mocks. Meter and Tiny Threat appearance are unchanged.


### Tab refresh follow-up

Details hides every section and reapplies every category template during selection, even when reselecting the active category. Keep the last completed selection while those templates reset; reconcile navigation after the native method finishes. Replace its full-window refresh with a synchronous scan of the selected page, including controls created by native RefreshOptions after OnShow. Page show/interaction bursts coalesce within their section; the completed selection cancels its pending show pass. Other windows retain their existing refresh route. No native tab callback is replaced or skipped.

Regression fixtures reproduce the native hide/template/show/RefreshOptions order. Fifty repeated clicks produce fifty selected-page scans, zero full options scans and no transient deselection of the active tab in the mock. One hundred page-show callbacks coalesce to one page scan. Newly created post-OnShow controls are styled before native selection returns. These are simulated callback/scan counts, not client rendering or FPS measurements. The approved readability layers and meter styling are unchanged.


### Performance audit after 8aaf3b9

The prior scan-count tests missed repeated primitive/font work inside each scan. Review of the public EllesmereUI font helper and Details DF page refresh, enable/disable, switch and template code identified these adapter costs:

- Unchanged show/enable/value callbacks reran button setup and label fonts. Keep base button setup once, use a state-only path for unchanged controls, and let native checkbox value changes retain their own marker visibility. Template/marker setters still force a visual repair; geometry, marker, row or full-theme changes invalidate the warm path.
- Category template resets repeatedly called SetTabSelection and restyled the hidden native label. Keep category selection updates for actual selection/disabled/theme changes, repair visible-label colours only when needed, and leave the hidden native label's font alone. DF measures that native label in SetIcon.
- Cache public Font outputs within Details using weak keys and actual font/size/flags comparisons. Full integration refreshes invalidate the cache; native font resets are still repaired. Public API calls remain responsible for applying fonts/shadows; no private EUI state is accessed.
- Bar-setting bursts coalesce into meter-only styling. Mode/display changes and raid-mode activation retain synchronous meter styling without scanning the options. Profile/skin/window creation still use full refreshes. Designer EditObject refreshes its owned editor subtree.

The same strengthened fixtures were run against the exact previous alpha (8aaf3b9) and the updated source:

| Mock scenario | Previous alpha | Updated |
| --- | --- | --- |
| 50 same-category clicks: selection writes / public Font calls | 550 / 1650 | 0 / 0 |
| 300 unchanged value/enable/show callbacks: Button calls / label font writes | 300 / 300 | 0 / 0 |
| 20 warm selections: Button calls / label font writes | 20 / 40 | 0 / 0 |
| 100 bar-setting callbacks: full options scans | 1 | 0 |
| 40 mode/display callbacks: full options scans | 40 | 0 |

These are simulated operation counts, not CPU timings, memory totals or FPS claims. Regression coverage retains dynamic controls, theme updates, template repair, native values/actions/returns, disable/combat guards and reusable visual layers. No polling, global DF/AceGUI changes, eager hidden-page scans or shared runtime changes were added. First-time controls still require initial setup; actual client render timing and whether this eliminates the reported visible flicker cannot be established here.

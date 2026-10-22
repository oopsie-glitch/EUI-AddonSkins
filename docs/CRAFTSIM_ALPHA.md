# CraftSim alpha

Branch: `skin/craftsim-initial`, based on stable 1.5.2. Untagged; no CurseForge/Wago upload.

## Alpha.4 content-layer audit

The author overview image was cross-checked against the source creation paths, including panels requiring professions, recipe data or other character prerequisites. Anonymous child backdrops no longer qualify for a skin fill. Only confirmed GGUI windows and actual controls receive new backgrounds. Generic filled decorations retain their original fill texture, colour and opacity while losing their decorative edge; their existing region art is not faded. Border-only frames remain unfilled. Input validation frames exposing GGUI's `SetValid` contract remain completely native, preserving the red invalid-value indicator and its visibility changes. No shared skin helper changed.

| Source area | Content/layer checks |
| --- | --- |
| Recipe scan, concentration, cooldowns, queue, pricing, customer history | Scroll borders and list columns/rows cannot acquire anonymous covering fills; native selection, click targets and semantic values remain owned by CraftSim. |
| Simulation, specialization, reagent optimization, queue editing and TSM controls | Numeric/currency input validation remains native; input geometry, values, native actions and quality-meter progress/art are preserved. |
| Statistics, profit, top gear and work-order variants | Confirmed window backgrounds sit on their own window frame; child data, graphs, gear and status artwork are not generic panel decorations. |
| Craft logs and buffs | Scrolling message frames and selectors use owned control paths; log text, item results, buff/status artwork and native state remain intact. |
| Shopping, import/name/export, rewards, support/help/debug | Constructors/registry or explicit scoped utility calls supply ownership; no blanket traversal of Blizzard profession windows or UIParent. Shared exports, menus and Settings release cosmetics on reuse. |

Added regressions cover nine frame-level/opacity combinations with native data art, unchanged positions/dimensions/hit callbacks, unmodified shared backdrop tables, native input validation, quality-meter values/colours and repeated theme refreshes. The late-list regression now asserts the stronger rule that no covering skin fill is created even before the wrapper is known. Existing first-show, dynamic/lazy control, menu reuse and warm-path checks remain in place.

CraftSim 19.9.0's slash handler has no single show-all-windows command. Most panels are created/shown through recipe/profession module flows. This audit did not execute every CraftSim function in a live client or simulate crafting transactions. Static source review and automated frame mocks support the coverage assessment; they do not establish pixel rendering, taint safety or absence of all client-specific visual faults.

## Alpha.3 queue-overlay follow-up

The queued-recipe rectangle can retain a skin fill when a raised decoration is classified before its completed FrameList wrapper becomes available. Alpha.3 identifies the scroll-border sibling from the completed list structure and retires any previously created fill. Later theme refreshes keep that fill hidden. Native rows, hover/click behavior, list stacking, dimensions and scroll targets are unchanged. Blizzard's shared HelpPlate/tutorial-tooltip subtrees are excluded from discovery even when reparented into a CraftSim window.

Regression coverage reproduces the already-painted overlay, attaches its completed list wrapper, and verifies that both immediate repair and subsequent theme refreshes leave the contents visible. Ordinary filled panels and native tutorial text/art remain intact. The full automated package checks pass; live rendering remains unverified outside WoW.

## Alpha.2 corrections

- Queue/list and quality-meter border-only frames remain transparent. GGUI raises these frames above their contents; alpha.1 incorrectly added an opaque panel fill over the rows. Real filled panels retain their background, and native row selection colours remain intact.
- Scrollbars support `Track.Thumb`, `GetThumb()` and the direct-thumb fallback. Native tracks/thumb artwork is replaced without resizing drag targets; vertical arrows point up/down.
- Modern popout check/radio markers use compact square art and the selected accent. Native checked state, callbacks and compositor fonts remain untouched. SetupMenu-based selectors/filter menus and submenus are covered; embedded queue-amount/TSM-expression inputs receive scoped styling. Cosmetics restore when shared menu controls are released.
- Added explicit coverage for craft-list name/import dialogs, item selectors, spell icons and scrolling craft logs. CraftSim's shared text-copy/export window receives temporary styling; export strings, selection and multiline font stay native. Other addons regain its original cosmetics on reuse.
- First show checks the completed window once for native controls added after its constructor. Completed module UI initializers invalidate cached discovery; repeated warm window/tab and native data updates do not trigger full scans.

Source coverage review: inspected UI creation/lifecycle paths across all 121 CraftSim-owned Lua files outside bundled libraries, data, locales and developer tools, at source tree `e15fb18c1004b2f373ee3247b2ade0b917fbea69`, plus the screenshot version 19.9.0 and pinned GGUI implementations. This includes recipe info/scans, statistics, top gear, pricing/reagent optimization, simulation/item selectors, queue/list/edit/import/export tools, patron rewards, work orders, shopping, customer history, craft logs, buffs, concentration/cooldowns, settings/TSM, support/patch-note/explanation windows and debug tools. Tutorial/help/quality/acquisition artwork and interactive graphs keep their semantic appearance. This is source-path coverage, not a claim that every live window was visually exercised.

The adapter follows CraftSim's GGUI frame registry and owned constructors rather than a fixed list of screenshot windows. This covers statistics, top gear, cost/reagent tools, recipe scans, craft queues/logs, buffs, concentration/cooldown tools, other registered modules and their lazy controls. Legacy canvas options and current Retail native Settings initializers are supported. Buttons, tabs, input fields, checks, sliders/scrollbars, dropdowns, close/minimize controls and item icons use the existing theme. Main windows use `S.Shell` (including EllesmereUI's own selected backdrop) with a restrained lighter centre and darker top/bottom edges. Meaningful warning/profit/loss, selection and item-quality colours are retained.

Graph canvases, grid lines, axes, data series, money strings, native crafting/simulation actions, configuration, input geometry, module positioning and collapse behavior stay controlled by CraftSim. The surrounding Blizzard profession interface is not traversed. Modern context menus receive scoped texture styling without registering UIParent as a menu owner or modifying compositor fonts. Shared Settings controls restore their cosmetics through their own initializer reset; unrelated GGUI users are excluded.

GGUI constructor completion hooks style new owned widgets and rows. Native recipe calculations, price updates, FrameList Add/UpdateDisplay/UpdateRows, and module Update functions are not hooked. Window shows use cached child counts; tab state changes repaint selection only. There is no OnUpdate, polling, global CreateFrame replacement or database/provider query. Addon-load events check library identities before rebinding. Completed UI construction callbacks coalesce discovery. Theme changes and combat recovery refresh the owned windows.

Validation: `python3 scripts/package.py` passes Lua syntax and all 23 regression suites, then verifies a 40-file install ZIP with one EUIAddonSkins folder, the new adapter and unchanged MIT license. Tests cover pre-existing/lazy registry windows, constructor ownership, rows, icons, graph exclusions, native return values/data/actions, protected and macro controls, modern Settings reuse/restoration, context menus, hover/font repair, themes, combat and disabled skins.

Alpha.2 regressions additionally model raised border-only and transparent-background siblings, three scrollbar variants, arrow direction and unchanged hit areas, managed check/radio marker repaint/restoration, ownerless submenus, forbidden compositor font access, foreign menu reuse, embedded menu inputs, first-show native descendants, completed UI initialization, craft-list dialogs, composite widgets and shared export reuse. Reopening menus and export windows 100 times adds no UI objects or hooks in the mock.

Mock results: 1,000 row-data/display/module-update cycles and 1,000 warm window/tab cycles each add no skin hierarchy reads, font writes, UI objects or hooks. Reusing a Settings row 100 times creates no additional UI objects or hooks; unrelated addon-load events do not traverse windows. These counters do not measure in-game CPU, memory, GC pressure or FPS. Actual rendering, client taint and live module coverage remain unverified without WoW.

API/lifecycle references inspected: [CraftSim 19.9.0](https://github.com/derfloh205/CraftSim/tree/19.9.0) (the screenshot version), [current CraftSim](https://github.com/derfloh205/CraftSim), and their pinned GGUI revisions. No CraftSim, GGUI or third-party source/assets are bundled. CraftSim and EllesmereUI are installed separately. Tests and reference sources are excluded from the player ZIP.

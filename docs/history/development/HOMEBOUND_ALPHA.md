# Home Bound alpha

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

Branch: `skin/homebound-initial`, based on stable 1.5.2. Untagged; no CurseForge/Wago publication. Sources inspected: the supplied HomeBound 1.60 and HomeBound_Blueprints 1.05 ZIPs. Neither addon, its data nor its artwork is bundled.

## Coverage

- Main window, bottom navigation tabs, search and filter dropdown.
- Compact accent checkboxes, flat action buttons, close buttons and scrollbar/page-arrow styling.
- Retail Settings canvas, including its scale slider and keybinding control.
- Vendor/reagent popup, reward/model and thumbnail previews, link-copy, support/upload windows and native addon note/cost tooltips.
- Optional Blueprints gallery/cards, selection accent, detail/import/share-code controls, material manifest and fullscreen screenshot controls.

Main-window top accent stripes are omitted. Accents identify active navigation and selected blueprint cards. Collection/faction/favorite markers, item rarity borders, buildability/missing-material colours, screenshot crops, 3D models and all input/drag/tooltip/action handlers remain native. Anonymous raised frames never receive a new filled background; known panels use same-frame background art below their content.

## Lifecycle and performance

Uses HomeBound's exported completed `BuildUI` callback, owned scroll-child `SetHeight` completion points and cached first-show discovery. List updates walk only changed subtrees. Repeated row-show callbacks share one coalesced flush key. No global CreateFrame replacement, global AceGUI hooks, polling, OnUpdate hooks, item/currency/collection queries or blueprint import/verification API calls are added. The data pack is optional and uses HomeBound's existing Blueprints availability checks.

Blizzard filter/submenu styling is scoped to HomeBound's filter-owner chain and changes compositor selection textures only. Restricted menu FontStrings and shared FontObjects are untouched. Combat defers changes; disabled skins stop processing.

## Validation

`python3 scripts/package.py` passes Lua syntax, all 23 regression suites and an install-ready 40-file package with one EUIAddonSkins folder and the exact MIT license. Tests cover target absence, late optional Blueprints creation, the Settings canvas, numeric close textures, disabled import, native callbacks/returns, search/share-code values, previews/models/fullscreen artwork, rarity borders, semantic colours, asynchronous manifest rows, menu ownership, themes, combat and disabled skins.

In a mock, 1,000 warm BuildUI/manifest cycles, including pooled row hide/show reuse, add zero skin UI objects, hooks, font writes or child/region enumerations. The show burst queues at most one timer batch. These are simulated work counters, not in-game CPU/FPS measurements. Actual rendering, protected-client behaviour and housing API availability remain unverified outside WoW.

The alpha filename identifies this untagged branch build. Core and TOC version remain 1.5.2 until release integration. Blueprints assets must be installed separately to use HomeBound's Blueprints content.


## Alpha.2 compact Settings controls and performance review

The native UICheckButtonTemplate hit rectangle is larger than the desired visible box. Checkbox artwork now lives on a mouse-disabled 22-unit host, giving a 14-unit visible box/highlight and 8-unit accent mark. The native control dimensions, label anchors and click area remain unchanged. Click, checked and enabled-state callbacks update this control only, including grey disabled marks and native automatic click toggles.

The horizontal scale slider now uses a 6 x 14-unit accent grip anchored to the existing native thumb, with a 2-unit track and themed stepper arrows. The original thumb dimensions, drag target, slider range/steps/value callbacks and scale setting are retained. No OnUpdate or OnValueChanged skin handler is added. Native scrollbar handling remains separate.

Review found no skin polling, OnUpdate hooks, collection/data calls or global construction/AceGUI hooks. The previous checkbox handler did reset two texture anchors/sizes/colours on each state setter; it now updates mark visibility and changes colour only for enabled/theme changes. A new 1,000-cycle mock requires zero hierarchy reads, UI allocations, hook registrations, geometry writes, texture-colour writes or font writes for stable checkbox/slider state. Hover bounds, native hit areas, click toggles, disabled state and thumb visibility are covered. The existing 1,000 warm list/reuse benchmark still passes.

All 23 suites, Lua syntax and the 40-file package check pass. These counters demonstrate bounded/reduced skin work; in-game CPU/FPS and live appearance remain unmeasured.

# Decor Vendor alpha

Branch: `skin/decorvendor-initial`, based on stable 1.5.2. Independently written integration for Decor Vendor 2.14, reviewed at upstream tree `72c57ca59c1bdf9a0e48df900ec7a5b37cfc6226`.

## Scope

Main browser, source tabs, sidebar filters, accordion headers, vendor/decor tiles, preview and item panels, vendor/reagent popups, home panel, gallery, search/action controls and the Settings category/subcategories. Soft charcoal surfaces with a restrained centre lift, quieter outlines, compact checkbox artwork and horizontal slider grips. Active tabs use EllesmereUI's selected accent. No main-window top accent stripe.

Changes are runtime cosmetics in this addon's own Lua module. Native item/portrait textures, 3D models/camera controls, collection and faction markers, split-status strips, progress/status colours, rarity borders, search/share values, import/source/waypoint actions and credits remain native. Native settings, layout dimensions, anchors and hit/drag areas are not rewritten. The alpha includes no Decor Vendor source, layouts, data, records, images, fonts or other target assets; users install the target separately.

## Lifecycle and verification

Completed native UI build/show callbacks discover only owned frames. Main lists use the public active-widget list; gallery updates use its current cards, not a UIParent or historical-frame scan. Static subtrees cache child/region counts and theme generations. Native collection/catalog/model/animation loops are neither called nor hooked. There is no polling, OnUpdate, global CreateFrame or global AceGUI replacement. Native font objects are never captured or assigned by the skin; concrete fonts are applied only to owned UI. Protected/model frames are excluded, with combat deferral and target/toggle gating.

The native gallery rebuilds cards and filters rather than pooling all of them. New native controls therefore need their initial styling; this integration does not change that target lifecycle or claim zero allocations during a real native rebuild. Warm stable-control tests distinguish those initial allocations from repeated skin work.

Lua syntax, all 23 suites and the one-folder 40-file install package pass. Regression coverage includes absent/wrong targets, late gallery creation, explicit model/control exclusions, untouched foreground/marker/credit content, disabled actions, native clicks/returns/settings, compact controls, search, active tabs, scoped Settings subcategories, live themes and combat/disabled handling. In a mock, 1,000 warm native list/gallery/state refreshes add zero skin objects/hooks, hierarchy reads, font writes or geometry writes and do not scan unrelated windows. Actual in-game rendering, taint and CPU/FPS remain unverified.

## Alpha 2 performance review

Scoped Settings navigation to Decor Vendor categories; unrelated category changes no longer enumerate this addon's layouts. Completed filter builders now perform one discovery pass instead of a cached pass followed by a forced pass. Disabled skins also skip new root-hook registration. A direct-region cache invalidation fixes newly created labels on an existing canvas without refreshing the entire window. No shared helper or native data, layout, input or model behavior changed.

Expanded mock regressions cover 1,000 unrelated Settings category changes with zero layout/hierarchy reads, 100 same-count sidebar replacements with exactly one root traversal each, 100 fresh gallery card batches with zero additional skin objects/hooks, new help labels, and disabled-root discovery. The existing 1,000 warm refresh test still records zero added skin objects/hooks, font/geometry writes or hierarchy reads. All 23 suites, Lua syntax and the install-package check pass. These are simulated operation counts, not measured in-game CPU/FPS or crash guarantees.

Remaining cost: first-time controls require styling, and the native gallery recreates cards/sidebar controls during refresh. Redesigning that target lifecycle is outside the skin's scope. No polling or per-frame skin callbacks were found.

## Publication status

Untagged development branch and local test ZIP only. No CurseForge/Wago release, tag or merge into main. Public distribution/permission decisions remain with the project owner; this document does not establish licence compatibility or a fair-use determination. Retain this exclusion when assembling a release until the owner expressly selects this skin for publication.

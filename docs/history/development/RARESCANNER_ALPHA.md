# RareScanner alpha

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

Branch: `skin/rarescanner-initial`. Untagged test build based on v1.5.2.

Reviewed the supplied `RareScanner_12.1.5.3.zip` (Retail interface 120105). Original adapter using EllesmereUI's public skinning API; RareScanner, its libraries, data and assets are not bundled or copied into the project.

## Coverage

- Matte alert surface, close/filter controls and themed previous/next navigation.
- Explorer window with a subdued centre lift, panels, buttons, dropdowns, compact checks, inputs and scrollbars.
- Recycled rare/group list rows with soft hover and accent selection, preserving native selected visibility and status colours.
- Explorer loot icons, with portraits, map tiles, collectible symbols, item overlays and model displays retained.
- RareScanner's AceConfig settings pages, including pooled checkboxes, dropdowns, sliders, tabs and action labels.
- Texture-only confirmation styling for the addon's `RARESCANNER_` dialogs and owned AceConfig confirmations. Native fonts and callbacks remain unchanged in those dialogs.

Enable RareScanner's skin in EllesmereUI's Blizzard Skins+ third-party skin list. Install RareScanner separately.

## Safety and lifecycle

The alert is a SecureActionButton. Only its known cosmetic surface/control art is styled outside combat. Its secure attributes, scripts, targeting macro, dragging, positioning, scale and model are not replaced. The secure alert hierarchy is never recursively traversed. Protected/forbidden unrelated controls are excluded; combat defers new styling until combat ends.

Explorer uses completed list initialization callbacks for new virtualized rows and local active loot pools. Its map/model regions are excluded. Existing controls use theme/child-count guards. There is no scanning-engine hook, map/minimap traversal, bag event, polling or additional OnUpdate handler.

AceGUI controls receive reversible, same-frame artwork. Native appearance and fonts/anchors are restored when controls are released or popup menus change ownership, including after the skin is disabled. No global AceGUI factory replacement or AddChild hook is installed. FeedGroup is observed only for RareScanner's application IDs; button/check state changes repaint their own control.

## Validation

`python3 scripts/package.py` passes Lua syntax validation, all 23 regression suites, manifest/version checks and one-folder archive inspection. LICENSE matches the root MIT license; development files and target-addon files are excluded.

Targeted mocks verify secure macro/model/click preservation, skipped map/secure hierarchies, native status colours, dynamic rows, current loot, warm reuse, checkbox/dropdown/scrollbar actions, shared pool restoration/foreign reuse, dialog scoping, theme updates and combat/disabled handling. In 100 simulated warm alert/Explorer opens and row callbacks, additional hierarchy reads, font writes, UI objects and hooks are zero. These are mocked operation counts, not actual game CPU, memory or FPS measurements.

No WoW client is available here. Automated checks do not establish in-game appearance or taint safety. Runtime version stays 1.5.2 until release integration; the ZIP filename identifies this alpha.

This build excludes other unmerged task alphas. No release tag or CurseForge/Wago publication is created.

## Alpha.2 — options pass

- Bind RareScanner's own Blizzard options canvases after native OnShow construction and after SetupOptions/AddToBlizOptions. This also recovers when a shared Ace library replaces its methods after startup. Completed feeds avoid a duplicate canvas paint.
- Observe method identity changes on ADDON_LOADED; unchanged libraries trigger no option traversal or repaint. Pool-release cleanup also rebinds after disabling the skin.
- Add the SharedMedia sound selectors and their separate, opaque popup lists, including their scrollbars. Speaker previews, selected ticks and sound values remain native; popup art/fonts/slider geometry restore on hide and reuse.
- Flatten keybinding controls and texture-style their capture hint without replacing keyboard handlers. Refine field captions to soft white while headings follow the accent; retain the existing settings-window background.
- Scrollbars, slider tracks/grips, numeric fields, inputs, standard dropdowns and clean checkboxes use the existing pooled control treatment once the page activates.

Regression fixtures now reproduce a native canvas opening after FeedGroup replacement and a Release replacement while the skin is disabled. They also cover sound selection/preview, keyboard capture, popup cleanup/reuse and prevention of duplicate page paints. In mocks, 100 unchanged-library addon-load events perform zero hierarchy reads/font writes, and 20 media popup reopen cycles add zero UI objects/hooks. All 23 suites and packaging validation pass. In-game appearance is unverified.

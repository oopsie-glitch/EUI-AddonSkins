# RareScanner alpha

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

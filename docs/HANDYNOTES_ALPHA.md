# HandyNotes alpha

Branch: `skin/handynotes-initial`, based on stable 1.5.2. Untagged; no CurseForge/Wago upload.

Covers **Options > AddOns > HandyNotes**, the standalone `/handynotes` options window, the Alt-click map note editor and its icon selector, and the note right-click context menu. Matte charcoal panels, a subtle centre lift in standalone windows, readable neutral labels, compact accent check marks, flat sliders/scrollbars and restrained button/dropdown outlines follow the existing skin theme. Sidebar selection and collapse/expand indicators remain native in behavior. The bottom Close action retains its text.

Map pins, icon art/colours, plugin data, coordinates, note editing/saving/deletion, profile actions, dragging and keyboard behavior remain controlled by HandyNotes. No map-pin traversal, map update callback, global widget replacement, OnUpdate polling or data/provider operation is added. The supplied HandyNotes 1.6.31 code was inspected for lifecycle contracts; no upstream code, library or assets are bundled. HandyNotes and EllesmereUI must be installed separately.

AceConfig FeedGroup completion styles only HandyNotes-owned widgets. Already painted widgets skip hierarchy scans until released or the theme changes; newly built children remain supported. Sidebar refreshes repaint their own owned widget. Pooled cosmetics are restored on release, including when this skin is disabled; pullout item art is restored on hide. Unrelated addon-load events check library method identity without scanning frames. Existing shared popup ownership/restoration handles legacy map menus.

Validation: `python3 scripts/package.py` runs syntax validation and all 23 regression suites, then verifies a 40-file ZIP with exactly one EUIAddonSkins installation folder, every referenced runtime file and the unchanged MIT license. Development/reference files are excluded. New tests cover both options roots, native return/action/data preservation, dynamic controls, editor/icon/menu ownership, pooled release and reopen, disabled skins, combat deferral and theme changes.

Mock measurement: 1,000 warm options-feed/editor-show cycles add zero UI objects, hooks or font writes; 100 unrelated addon-load events perform zero hierarchy reads. These do not measure actual WoW CPU, memory or FPS. Actual rendering, client taint and in-game behavior cannot be established without a WoW client.

## Alpha.2 performance review

Expanded stress tests cover 500 pullout reopen cycles, 250 pooled-control rebuilds, 250 sidebar refreshes and 25 theme refreshes with zero additional UI objects or hooks. Another 1,000 checkbox/action-state cycles produce zero hierarchy reads or font writes; 1,000 disabled options/editor callbacks perform zero hierarchy reads or font writes. Sidebar refresh does not walk unrelated action controls. Native note data and save action counts remain unchanged.

The review also corrected duplicate font snapshots for widget-backed menu items: each pooled item now restores its own native font, instead of a parent snapshot restoring the already-skinned font afterward. A regression first reproduced this failure and now verifies native restoration on hide. No broad refresh or map-processing performance issue was found. Temporary Lua tables during real widget construction/restoration remain normal; caches reuse cosmetic objects across native pool acquisitions. No polling or global AceGUI construction hooks are installed. Mock counters do not establish in-game CPU, FPS, GC pressure or long-session memory use.

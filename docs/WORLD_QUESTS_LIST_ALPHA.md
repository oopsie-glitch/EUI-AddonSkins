# World Quests List alpha

Branch: `skin/world-quests-list-initial`, based on stable v1.5.2. Untagged; no CurseForge or Wago upload.

Source reviewed: user-supplied `WorldQuestsList127.zip`, addon version 127 (Retail). Reference code/assets are not bundled or copied into this project.

## Coverage

- Quest table: matte background with a restrained brighter centre, softer header/footer, readable EUI fonts and hover highlight.
- Sort, filter, options, expansion and move-header menus: flat surfaces, chevrons, clean square checks/radios and slim sliders.
- All three private ELib popup levels, including reused rows and post-Show font resets.
- Blacklist and custom sorting windows: native lazy construction, flat action buttons, scrolling and reorder arrows.
- Close controls and the map visibility checkbox.

Quest/reward colours, inline icons, sorting indicators, data, click actions, drag/drop, map pins, navigation arrow, anchoring and dimensions remain native. The table's native hidden-background/opacity behaviour is preserved. Disabling this skin follows the collection's existing reload-to-restore behaviour.

## Performance and verification

Private list updates do not all call the exported `UpdateList` alias. Discover new rows after the owned content frame's completed `SetHeight` instead. Warm calls compare pool length and do not traverse the window or existing rows. No polling, global UI factories or native update callbacks are added/replaced.

Menu labels are repaired locally after native FontObject setters; new rows are bound before the private Reload populates them. Existing menus and dialog row pools reuse their layers/hooks.

`python3 scripts/package.py` runs syntax validation, the full regression suite and one-folder/license/manifest checks. The focused mock covers native private updater calls/returns, new rows, 300 warm updates with no hierarchy walks/UI allocations/font writes, repeated/rebuilt menus, checked-state visibility, filters/actions, lazy dialogs, native opacity, theme changes and combat/toggle recovery.

No in-game rendering, FPS or taint verification has been performed.

## Dedicated performance review

ELib retains its largest popup pool (`MaxLines`) when a shorter menu is opened. Limit per-open styling to the current `LinesNow` budget, which native code sets before Show and uses during Reload. Previously the skin revisited every historical pooled row. Existing fonts, callbacks and current-row construction remain synchronous.

The new regression expands a menu to 12 rows, reopens it at 2, verifies the other 10 rows remain untouched, and expands again to confirm reacquired rows are skinned. The full suite and install archive checks pass. No new polling, global hooks or runtime dependencies are added. Main/background/quest colours and actions remain unchanged.

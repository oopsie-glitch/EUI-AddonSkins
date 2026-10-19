# AllTheThings alpha

Branch: `skin/allthethings-initial`, based on v1.5.2. Untagged development build; no CurseForge or Wago publication. The in-game version remains the current stable base until release integration.

## Coverage

- Existing and dynamically created ATT collection windows: main list, mini list, World Quests, searches and other popouts using ATT's shared window system.
- Borderless theme panels with a restrained lighter centre, close buttons, narrow scrollbar grips and readable list fonts/hover feedback.
- ATT addon-options pages: checkboxes, action buttons, edit boxes, sliders and scrollbars. Only ATT's registered objects and owned UI children are inspected.
- ATT's multiline import/export dialog, preserving text selection, native contents and submission actions.

Collection text colours, inline icons, completion summaries, map highlights, rarity artwork, row geometry, window movement/resizing, native actions and ATT profile settings remain owned by ATT. No top accent strip is added. Checkboxes and sliders use the selected EUI accent.

## Implementation and checks

Reviewed ATT `master` at `0287e562bb244536e088430a72a38237f1046086`, especially `src/UI/Window Definitions.lua`, `src/Settings/Settings.lua` and `src/base.lua`. The separate visual background avoids changing the backdrop/colour values which ATT records to profiles.

New windows are observed through `OnWindowCreated`. Pooled rows are restyled after `DefaultRedraw`, the completed visual stage. The integration never calls `GetWindow`, iterates collection data, creates lazy rows, scans UIParent, replaces AceGUI, or installs an OnUpdate loop. Settings construction is batched; repeated enable/disable updates affect the individual control.

`tests/allthethings_spec.lua` covers lazy rows, dynamic windows and settings controls, preserved colours/backdrops/actions, multiline dialogs, theme/accent changes, disabled/protected frames, combat deferral and stable object/hook counts over 100 simulated redraws. Full regression and package checks run through `python3 scripts/package.py`.

These mocked checks do not establish in-game appearance, client compatibility or taint safety. Shared Blizzard tooltips and static popups are not independently restyled by this adapter. ATT versions using different UI internals may need additional coverage.

The linked Azilroka/AddOnSkins adapter was inspected for context only. Its restrictive `AddOnSkins/License.txt` does not grant general copying into this MIT project; no source or assets from it are included. The new adapter is original code using EllesmereUI's public API. ATT and EllesmereUI are installed separately.

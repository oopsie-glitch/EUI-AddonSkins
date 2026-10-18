# Myslot visual alpha

Branch: `skin/myslot-refresh`, based on stable v1.5.1. Untagged; no CurseForge or
Wago publication. RXP and KiwiFarm alpha changes remain separate.

## Scope

- Discover the Myslot Settings canvas through its category layout, or the legacy
  category list. Observe late Myslot-only registration and category display.
- Style options buttons/checkboxes and main-window actions with soft controls and
  quiet outlines. Preserve native danger/CLEAR warnings, disabled states and actions.
- Remove the main top accent strip; accent the title, Unsaved and Talents captions.
- Restore visible EUI glyphs for the empty-label Import/Export split buttons and
  profile dropdown. Preserve scroll/share artwork and disabled-icon opacity.
- Style the editor panel and legacy scrollbar, using a compact visual grip while
  preserving the native thumb's hit area, movement and visibility.
- Bind owned modern profile/import/export menus to the existing shared menu helper.
  Keep native menu selection/radio signals and supported compositor behaviour.
- Replace click-triggered full-window refreshes with menu-only completion handling.
  Do not scan on editor text changes, import callbacks or coroutine progress.

The supplied Myslot 6.2.0 gui/options/event files were reviewed. Settings canvas
lookup follows Blizzard's category/layout API (`Settings.GetCategory`,
`SettingsPanel:GetLayout`, canvas `GetFrame`); it does not scan UIParent or modify
Blizzard's Settings host. No shared runtime helper changes or new assets are needed.

The private UIParent-owned import progress dialog has no stable public handle and
is left native. Shared Blizzard confirmation dialogs retain their existing styling.
No import, export, clear, talent, profile, settings or saved-variable logic changes.
Editor contents, limits, selection, focus, key handlers and geometry are preserved.

## Verification

All 21 automated suites, Lua syntax and one-folder package validation pass. New
source-shaped tests cover the modern options canvas/late registration, button
and split glyphs, warning colours, late Unsaved text, native action/return values,
editor bytes/callbacks, sharing icons, scrollbar visibility/hit area, menu ownership,
reopening, disabled skins, missing targets and combat recovery.

In mocks, 100 simulated button/text callbacks request zero scans, allocate zero
skin frames and execute zero profile operations. Warm reopen/refresh does not
allocate extra frames. These are simulated callback counts, not real CPU/FPS or
memory measurements. WoW rendering, client-specific taint behaviour and private
import-progress appearance have not been independently verified here.

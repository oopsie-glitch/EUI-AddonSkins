# Myslot visual alpha

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

Branch: `skin/myslot-refresh`, based on stable v1.5.1. Untagged; no CurseForge or
Wago publication. RXP and KiwiFarm alpha changes remain separate.

## Scope

- Find the Myslot Settings canvas through category/layout lookup when available,
  or its named frame under the current Settings canvas/legacy panel container.
  Observe completed layout/display/show and late Myslot-only registration.
  Never walk UIParent or modify the Settings host's layout.
- Render borderless action controls through owned, mouse-transparent public
  skinning-API Panel layers with a readable hover fill. Keep backgrounds below
  text after reparenting/frame-level changes. Preserve native button states/actions.
- Add a subtle one-unit grey outline only to action buttons descended from the
  Myslot Interface options canvas. Main-window and menu controls remain borderless.
- Remove both top and bottom window strips. Use a non-inset editor panel so the
  editor does not become a large black block against the shell.
- Accent the title, Unsaved and Talents captions. Keep danger/CLEAR, talent-status,
  class and disabled-state colours. Do not modify encoded profile contents.
- Identify split/profile/share controls by their native fields and anchors, not
  texture filenames: GetTexture may return file IDs. Use proper chevrons for the
  split buttons and scrollbar steppers, including legacy globally named steppers.
  Preserve native sharing textures and disabled-icon opacity.
- Give the legacy scrollbar a thin track and compact visual grip while preserving
  native thumb geometry, drag hit area, movement and visibility.
- Bind only owned modern menus to the shared helper. Theme existing submenu,
  checkbox and radio textures through supported setters and guarded description
  initializers. No compositor CreateTexture or FontString:SetFont calls are added.
  Native selection, responders and refresh behaviour remain intact.
- Keep button completion menu-local. Do not scan on editor text changes, import
  callbacks or coroutine progress. No shared runtime helper changes are required.

The supplied Myslot 6.2.0 gui/options/event files and Blizzard Settings/Menu source
were reviewed. The private UIParent-owned import-progress dialog has no stable
public handle and remains native. Shared Blizzard confirmation dialogs retain
their existing styling. No import, export, clear, talent, profile, settings or
saved-variable logic changes. Editor bytes, limits, selection, focus, key handlers
and geometry remain native.

## Verification

All 21 automated suites, Lua syntax and one-folder package validation pass. The
fixtures include an inaccessible category-layout API, visible named-canvas
fallback, numeric texture IDs, native anchor relationships, empty template labels,
sharing opacity and legacy global scrollbar fields. The earlier fixtures lacked
those client-shaped cases and did not establish actual options-page coverage.

Additional checks cover menu texture rebuilds and initializer reuse, foreign-owner
rejection, late canvas/Unsaved captions, matte fills/hover feedback, warnings,
editor bytes/callbacks, native actions/returns, thumb visibility/hit area, warm
reopening, disabled/missing targets and combat recovery.

In mocks, 100 simulated button/text callbacks request zero scans, allocate zero
skin frames and execute zero profile operations. Warm reopen/refresh does not
allocate extra frames. These are simulated counts, not in-game CPU/FPS or memory
measurements. Actual WoW rendering, taint behaviour and client-specific Settings
routing have not been independently verified in this environment.

Reference APIs (no source copied into the addon):
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_SettingsPanel.lua
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Menu/MenuTemplates.lua
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Menu/Compositor.lua

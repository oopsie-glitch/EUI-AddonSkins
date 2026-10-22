# LiteMount alpha

Branch: `skin/litemount-initial`, based on stable 1.5.2. Untagged; no CurseForge/Wago upload.

Open **Options > AddOns > LiteMount**. The adapter covers General controls, mount list/model views, Rules, Groups, Macros, Falling, Advanced Options, Profiles, Report Bug and LiteMount's picker/import/export/rule popovers. Content surfaces use matte neutral shades with lighter rows, readable labels, visible hover states and restrained accent-coloured check marks/tab indicators. Editors keep their native text, monospaced fonts, insets and selection behavior.

Class/group markup, warnings, priority backgrounds, modified-flag indicators and collection/desaturation state remain meaningful. Mount cast/drag icons, secure actions, models/cameras, key bindings and configuration setters stay native. Shared Blizzard confirmation dialogs receive texture-only styling only for `LM_OPTIONS_` dialogs. Other addons' popups are left alone.

Owned scroll views use completed `OnInitializedFrame` callbacks; existing discovery visits realised frames only. General's shared Blizzard Settings rows are scoped by LiteMount's own initializer objects and restore their original cosmetics on reset, including when this skin is disabled. No global widget factory, OnUpdate, scrolling scan, mount-provider/database query, action invocation or editor-text hook is added.

Validation: `python3 scripts/package.py` passes Lua syntax, all 23 regression suites, catalog/client-manifest checks and a 40-file one-folder ZIP with the original MIT license. The LiteMount fixture checks dynamic/recycled list and model rows, native action/return preservation, status colours, editor data/geometry, shared Settings restoration, popup/menu ownership, protected controls, themes, combat and disabled skins. 1,000 warm mock row/refresh callbacks with unchanged native data/fonts add no UI objects, font writes, hooks, provider reads or cast operations. This does not measure in-game CPU/FPS or prove visual/taint behavior.

LiteMount's source was inspected for UI lifecycle/API contracts; no LiteMount code, data or assets are bundled. LiteMount and EllesmereUI must be installed separately. Actual appearance, 3D rendering and live behavior remain unverified without a WoW client.

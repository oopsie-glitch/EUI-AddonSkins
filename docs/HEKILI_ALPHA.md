# Hekili alpha

Branch: `skin/hekili-initial`. Untagged; no CurseForge or Wago publication.

## Scope

- Hekili recommendation icons use the EllesmereUI public border API; caption, keybinding, target-count and delay fonts follow the selected theme.
- Native display dimensions, position, zoom/aspect coordinates, texture colours, cooldowns, target-swap/interrupt indicators, glows and recommendations remain controlled by Hekili. Existing Masque-owned icons are left alone.
- Hekili-only AceConfig windows use matte surfaces with a subtle centre lift, readable action labels, compact checkboxes, dropdowns, sliders/scrollbars, close buttons and active-navigation accents.
- The native minimap dropdown is registered with the existing scoped menu helper. Shared Ace controls and popup art are restored on release/hide before reuse by another addon.
- Options painting follows completed Hekili page construction. Checkbox/button changes repair only that control; tree refreshes touch navigation rows without repainting content.

## Reference and compatibility

Inspected Hekili/hekili `thewarwithin` at `36daec382e6557fd57a263bbfb060856ef9fe9d8`, including UI.lua, Hekili.lua, Options/Options.lua and Options/ChatCommands.lua. The supplied repository TOC declares Interface 110205. The skin does not make this upstream version compatible with later clients or change its rotation engine.

The older reference skin predates named displays and was used only to identify historical coverage. No upstream addon code, assets, third-party skin code or libraries are bundled. Implementation uses this project's existing MIT-licensed control styling and EllesmereUI's public API.

## Validation

`python3 scripts/package.py` checks all Lua syntax, 23 regression suites, loader/catalog/TOC consistency and the 40-file, single-folder ZIP, including the exact MIT LICENSE. Hekili fixtures cover named/custom display creation, native returns and geometry, semantic indicators/cooldowns, Masque markers, tree navigation, dropdowns, shared-media menus, keybinding capture, pooled restoration, library replacement, theme changes, combat deferral and disabled skins.

Mock results: 1,000 recommendation updates cause no extra hierarchy reads, font writes, UI objects or hooks; 100 unchanged-library addon-load events cause no options traversal or font writes; 20 shared-media popup reopenings create no extra UI objects or hooks. Repeated page builds reuse objects/hooks but still inspect rebuilt controls. These counts are simulated, not in-game CPU, memory or FPS measurements.

No skin OnUpdate, polling loop, recommendation-engine hook, global frame enumeration or global AceGUI factory replacement is added. Actual WoW appearance, taint and performance cannot be established by these mocks.

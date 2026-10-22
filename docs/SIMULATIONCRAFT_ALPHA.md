# SimulationCraft alpha

Branch: `skin/simulationcraft-initial`, based on stable 1.5.2. Untagged; no CurseForge or Wago publication. The ZIP filename identifies the alpha; runtime version and changelog remain at the stable base until release integration.

## Coverage

Open the native export window with `/simc` or SimulationCraft's minimap button. The adapter applies a consistent matte surface, a small title, readable export text, a soft action button, flat accent checkboxes, themed scrollbars/arrows and a neutral resize indicator. No top accent strip or logo is added.

The native export string, selection, focus, copy/close behaviour, offspec-loadout toggle, drag/resize actions and saved profile values remain controlled by SimulationCraft. Older versions missing optional controls are handled with presence checks. Both legacy texture-thumb and modern scroll controls are supported. There is no separate SimulationCraft options window in the inspected source; its two appearance-relevant controls are on the export frame.

## Implementation and verification

Source review: simulationcraft/simc-addon commit `b0cce8ecfccd0c5ff2fb4942135e9c0589c2c5d7`, version 12.1.5-02, which declares Retail and Forever interfaces. The AddOnSkins adapter was reviewed for integration points only. The adapter is original code using EllesmereUI primitives; no SimulationCraft or AddOnSkins source/assets are bundled.

The completed `GetMainFrame` method is observed without replacing native methods or changing return values. No profile generation, async spell loading, global frame factory, AceGUI, OnUpdate or polling callback is hooked. The first open styles only the known owned controls; subsequent opens return through a generation guard. Theme/accent changes repaint once, and combat defers styling until combat ends. Generic global names, such as AutomaticClose, are checked for ancestry before styling.

`tests/simulationcraft_spec.lua` covers deferred activation, lazy creation, return values, unchanged export contents and selection, copying/close behaviour, offspec updates, saved window position/size, legacy and modern scroll controls, optional controls, foreign/protected frames, theme refresh and disabled/combat guards. A 1,000-open simulation creates zero additional UI objects/hooks and performs zero font writes or checkbox repaints after initial styling. These are mock counts, not in-game CPU, memory or FPS measurements.

Full Lua syntax, regression and one-folder package checks run through `python3 scripts/package.py`. The ZIP includes the MIT license and runtime files, with development files excluded. No in-game visual, client-specific or taint verification is claimed.

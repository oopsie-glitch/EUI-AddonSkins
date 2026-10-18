# RestedXP arrow option

Untagged branch: `skin/restedxp-arrow-toggle`, based on stable v1.5.1. No release tag or platform upload.

## Settings

- Rename the existing addon options category to **EUI AddonSkins**.
- Add **RestedXP > Skin navigation arrow**, enabled by default to retain the released appearance.
- Save the choice in `EUIAddonSkinsDB.rxp.arrow`. An explicit false persists; existing Details settings and other saved data remain unchanged.
- Keep all Details controls, their callbacks, the existing panel entry points and `/euidetails` shortcut. The internal `DetailsSettings.lua` filename is retained for compatibility; it now contains both sections.
- The panel registers on modern Settings and the legacy Interface Options API even when the target addons are absent. A saved choice applies when the skin activates later.

## Arrow restoration

Turning the option off restores the captured native texture anchors, tint and label font/colour, retaining the current label point size. RestedXP's own `UpdateVisuals` selects its current theme artwork. Reset the full native texture coordinates and keep the current native bearing, including wrong-continent handling. Frame position/size, dragging, text content, visibility and the native DrawArrow/OnUpdate function are unchanged.

Only arrow visuals are refreshed by the setting. Combat changes wait for PLAYER_REGEN_ENABLED and update the arrow without a guide traversal. Repeated unchanged settings do nothing. The toggle adds no extra arrow frames, textures, polling, global hooks or native action replacements.

## Verification

`python3 scripts/package.py` passes Lua syntax, all 21 regression suites and the existing 39-file installation package checks. Expanded RXP tests cover saved-off startup, repeated on/off restoration, native setup/theme changes, current scale/bearing, label size preservation, combat deferral and native handler/return preservation. Twenty toggle cycles allocate no UI objects, scan no guide and schedule no refresh in the mock.

`tests/settings_spec.lua` covers both settings registration APIs, one category registration, checkbox wiring/state refresh, persistence across simulated loads, missing targets and separation of the Details and RXP settings callbacks. Existing Details tests remain unchanged and pass. Automated mocks do not establish actual in-game rendering or taint behaviour.

## Confirmation textures

The same alpha also opts RestedXP settings confirmations and validation errors
into `ns.StyleTextureDialog` in Menus.lua. This reusable helper changes native
background/border/button artwork only. It never changes dialog fonts, text
colours, actions, hit areas or layout. Native artwork is restored on hide and on
fresh acquisition before another addon uses AceConfig's shared popup. Layers
are reused; protected dialogs and changes during combat are skipped. Other
integrations are unaffected unless explicitly opted in.

This covers the Preview Frame Positions and Apply/reload confirmations. Separate
Blizzard StaticPopup dialogs and feedback/export windows are not opted in by this
change. Their coverage remains separate from AceConfig's shared confirmation.
Automated tests cover ownership routing after native callbacks, fonts/actions,
reopening, allocation stability, disabled skins and combat/protected guards.
Actual WoW rendering and taint behaviour have not been verified in this environment.

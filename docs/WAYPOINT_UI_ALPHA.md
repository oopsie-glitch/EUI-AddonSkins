# Waypoint UI alpha

Branch: `skin/waypoint-ui-initial`. Untagged alpha.1 based on main 1.5.2. No CurseForge or Wago publication.

## Coverage

Inspected Adaptvx/Waypoint-UI at `c3fdd2077debfde6d0dd768a4a7513e6ede0358e`. No EllesmereUI registration/integration was found in its current source. The existing ElvUI check concerns settings-canvas anchoring.

- Settings use the existing EUI settings canvas, neutral theme fonts, flat controls and panels, sidebar selection accents, clean checkbox indicators, compact slider/scrollbar artwork, native inputs, prompts and selection menus.
- Native UIKit controls are usually Frames, not Blizzard Buttons/Sliders. Their own click, keyboard/binding capture, hover, disabled, check, scroll, value, focus, placeholder and menu data/callback handling remain unchanged.
- Waypoint footer information, distance and arrival text use EUI fonts while preserving semantic colours. Direction arrows, beams, context icons, map/minimap pins, navigation calculations, world placement and animations remain native. Colour-input fills, images, caret and placeholder artwork remain native.
- No navigation profile or saved setting is overwritten. No third-party code, art or libraries are bundled.

## Renderer integration

Use public EUI skin primitives plus addon-local hooks on native instances. Only native texture wrappers used for styled chrome are suppressed; their parent frames and interactive children remain present. Native typography resets are repaired on the affected text wrapper. The adapter does not replace UIKit, AceGUI, native event scripts or factories.

Initial discovery follows the addon's logical UIKit child lists. Deferred settings construction is observed after the completed root render through its three known build containers. Completed tab renders discover changed children; unchanged warm tabs return from the cached count check. Menu row construction and prompt button-pool renders discover only their changed local subtrees. Hover/check/value callbacks repaint a single control.

No added OnUpdate, polling, UIParent scan, navigation/quest-data traversal or recurring full settings scan. Theme changes and combat recovery invalidate discovery once; protected/forbidden/disabled paths are gated.

## Verification

`python3 scripts/package.py` validates syntax, all 23 regression suites, catalogs, all client manifests, unchanged runtime version and the 40-file single-folder ZIP with the exact MIT license. The new fixture exercises deferred UIKit construction, native returns/actions, custom checks/ranges/scrolling, input/caret/placeholder and colour semantics, selection/menu/prompt pooling, local font repair, HUD semantic colours, warm reuse and combat/protected/disabled guards.

Mock benchmark: 1,000 warm settings/tab/hover/check/menu cycles add zero UI objects, hooks, font writes or hierarchy walks. This is simulated, not an in-game CPU/FPS measurement. Rendering, actual taint behaviour and in-game appearance remain unverified.

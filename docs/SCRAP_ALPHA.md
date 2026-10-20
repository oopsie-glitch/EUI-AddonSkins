# Scrap alpha

Branch: `skin/scrap-initial`. Untagged; no CurseForge or Wago publication. Runtime remains at main's 1.5.2 until release integration.

## Coverage

- Scrap 12.1.8: merchant junk button and owned right-click menu; visualizer shell, tabs, scrolling item rows and actions; General, Filters, Help and Credits settings; owned tutorial popouts.
- Matte surfaces, readable theme fonts, active-tab accents and neutral options text, compact checks, sliders/numeric inputs, close buttons and scrollbar.
- Preserve native selling, repairs, drag classification, junk-learning state, item-quality colours, selection/stripes, tooltip callbacks, thresholds, menu actions, window geometry and module loading.
- Hooks are installed after native OnLoad construction so Scrap's own SetScript calls cannot replace them.
- No skin OnUpdate, polling, inventory enumeration, forced addon loads, global frame scan or Sushi factory replacement. Warm merchant/list updates use cached rows. Options paint the completed current Sushi Children list rather than scanning frame hierarchies.
- Shared Sushi widgets receive reversible local styling. OnReset restores native textures, fonts, geometry and backdrops even after disabling the skin. A fresh acquisition callback table gets one cleanup callback. External dropdowns are styled only while parented to Scrap's merchant button.

## Verification

`python3 scripts/package.py` validates Lua syntax, all 23 regression suites, target catalogs/client TOCs and the 40-file single-folder ZIP with the exact MIT license. New tests cover missing and late modules, pre-OnLoad activation/native script replacement, merchant actions/geometry, quality-coloured and newly created rows, tabs, compact controls, threshold/expand/menu semantics, Sushi cleanup/foreign reuse, themes, combat and disabled skins.

Mock stress checks: 1,000 bag/list updates cause no hierarchy reads, font writes, UI objects or hooks; 100 unchanged options updates create no UI objects/hooks; 40 pooled checkbox reacquisitions create no additional UI objects/hooks. These are simulated counts, not in-game CPU, memory or FPS measurements. Actual WoW appearance and taint behaviour cannot be established by mocks.

Inspected Jaliborc/Scrap at `c768db5539b2cd52c01c89af46b4562bbd169a31` and its pinned Sushi/Poncho public widget lifecycles. Scrap source/assets and Sushi/Poncho library code remain external and are not bundled. The older reference skin was reviewed for historical coverage; its per-frame merchant styling loop was not adopted. All implementation here is original project code using EllesmereUI's public API.

## Alpha.2 refinements

- Show the full merchant logo with a 3px inset instead of applying an item-icon crop. Clean the Options/Help popup labels while restoring their original decorative markup on pool reset.
- Use neutral text throughout interface options, including headings and theme/state refreshes.
- Theme only CustomTutorials.frames[Scrap.Tutorials]: remove portrait/native framing, style close/previous/next controls, and preserve instructional images, text markup, native sizing/anchors, page state, save progress and callout animation. Bind completed module methods, with a generation guard for repeated pages.
- Additional regression checks cover image preservation during shell stripping, menu text updates/restoration, neutral headings, padded logo geometry and 100 warm tutorial triggers without new scans/fonts/objects/hooks.

# HekiLight alpha

Branch: `skin/hekilight-initial`. Replaces the Hekili adapter in this test build. Original Hekili work remains preserved on `skin/hekili-initial`. Neither branch is tagged or published to CurseForge/Wago.

## Scope

- Targets HekiLight 0.7.0 (Retail Interface 120105), inspected at upstream commit `6228df5c4a1ca095b1646b33e5fd40da312a15fc`.
- HekiLight uses its own native Settings canvas and `HekiLightST` slot registry, not Hekili's named displays or AceConfig. The adapter follows these actual interfaces.
- Clean compact checkboxes and radio choices, matte section/action buttons, readable theme fonts, accent section labels, sliders/scrollbar and owned legacy dropdowns.
- Existing EUI styling of the surrounding Blizzard Settings window is retained. The skin does not modify other addons' settings or the global Settings sidebar.
- Main recommendation slots and the separate proc-alert slot use the public EUI icon-border API. Preserve spell textures/crops, range tints, glows, visibility, scale, spacing, position and drag handlers.
- HUD keybind typeface follows the theme; native custom size, outline, colour and anchors remain configurable. A local font setter hook handles native settings changes without touching the suggestion update path.
- No additional polling, OnUpdate, rotation/Refresh callback, global frame enumeration or shared Ace hooks. Completed native settings construction handles either initialization order.
- Cache owned containers. Reopening Settings checks child counts; action-created rows are styled through a coalesced parent-local callback. Ordinary sliders and checkboxes never trigger a full refresh.

## Validation

`python3 scripts/package.py` checks Lua syntax, all 23 regression suites, loader/catalog/client TOC consistency and the 40-file install ZIP with the exact MIT LICENSE. Fixtures cover initialization before/after public-state population, native reset/colour/slider/checkbox/section/menu actions, dynamic rows, HUD/proc semantics, keybind customization, warm reuse, theme updates, combat deferral and disabled skins.

Mock stress checks: 1,000 native suggestion updates cause no skin hierarchy reads, font writes, UI objects or hooks; 100 repeated Settings opens/control changes cause no hierarchy reads, new UI objects or new hooks. Native HekiLight polling and its expanded ignored-spells ticker are unchanged.

These are simulated counts, not real WoW CPU, memory or FPS measurements. No WoW client is available for an actual updated screenshot, appearance or taint verification. No upstream source/assets or third-party skin implementations are bundled.

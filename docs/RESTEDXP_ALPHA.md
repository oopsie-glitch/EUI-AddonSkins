# RestedXP refinement

Untagged branch: `skin/restedxp-refinement`, based on stable v1.5.0. Keep it separate from the Gargul branch until release integration. No tag, main update or CurseForge/Wago upload is part of this work.

## Changes

- One flat, public-API background per guide/step/title surface. Retain the main guide header accent; remove repeated accent strips from step cards and auxiliary windows. Preserve native background opacity and hide-background settings; Active Items follows the Active Targets body opacity while retaining its independent hide-background option.
- Move the legacy guide header out of its native nine-unit overlap with the scrolling list. Remove the guide logo/class badge and center the title; replace the footer cog artwork and retain native dragging, sizing and menu actions.
- Repaint native guide completion checkboxes with compact accent marks, preserving checked/disabled visibility and skip actions. Keep native quest text colours, links, values and guide selection.
- Style the independent Active Items frame/title without traversing or changing secure item buttons. Crop their existing icon textures outside combat; retain attributes, cooldowns, actions and dimensions.
- Style RestedXP AceConfig options after its completed `FeedGroup`/`Open` calls, filtered to its registered application and subpanels. Include selected tabs, headings, buttons, keybindings, checkboxes, dropdowns/pullouts, sliders, numeric inputs and options scrollbars. Guide updates do not repaint options.
- Only addon-owned visual layers enter the public EllesmereUI primitive registry. Snapshot and restore native pooled widget visuals on hide/disable; dropdown pullouts also restore on release/foreign reuse. No native option handlers, values, callbacks, hit rectangles or slider ranges are replaced. Keep colour swatches, semantic description colours and options-page branding native.
- Guide control/scroll bursts repaint their own guide root through the existing queue; item-frame updates repaint only their known visuals. No global AceGUI creation hooks, polling or OnUpdate callbacks.

## Source review

Reviewed RestedXP v4.11.23 (`41fc6f6fc96b4b9cf2bd4c396634afa5e836b9aa`), matching the screenshots: `SettingsPanel.lua`, `GuideWindow.lua`, `ActiveItemFrame.lua`, and its bundled AceConfigDialog/AceGUI widget implementations. No upstream code or assets are bundled or copied.

- https://github.com/RestedXP/RXPGuides/tree/v4.11.23

## Verification

`python3 scripts/package.py` validates Lua syntax, all 20 regression suites, manifests/version consistency and the 38-file, single-folder installation ZIP including MIT LICENSE.

`tests/rxp_options_spec.lua` exercises native actions/returns, dropdown cover/arrow clicks, pooled widget/popup restoration and foreign reuse, unchanged input geometry/values, semantic colours/branding, repeated hook/layer reuse, guide checkbox actions, item-frame separation, live accents, disabled state and combat deferral. In its mock, 25 warm page callbacks create no additional visual layers, rewrite no unchanged fonts and perform no guide hierarchy scans. These are simulated operation counts, not measured WoW CPU, memory or FPS improvements.

Existing collection/features tests continue checking optional targets, both guide generations, session-only themes, preserved settings/return values, secure children, background opacity/visibility and warm scrollbar reuse. The flat guide panels replace the previous textured shells; opacity/theme assertions now exercise that public Panel path.

No actual WoW client is available. Rendering, pixel alignment, first-use timing and live taint behaviour are not established by these tests.

## Title, opacity and performance follow-up

- Re-measure the localized auxiliary title after applying the skin font and clear stale FontString width constraints. Cache measurements by text/font/size/flags, restore sufficient header/container width after native visual redraws, and repair on show without waiting for a click. No hard-coded English replacement titles.
- Legacy Active Items hard-codes background alpha to 0.4. Its visual layer now follows the stored native Active Targets alpha, including later colour/opacity updates. Native settings and independently hidden backgrounds remain intact.
- Remove both guide header logos and their class badges. Center legacy text with equal margins; V2 centering reserves symmetric space for the existing settings/guide-selection buttons and survives native layout resets. Options branding remains unchanged.
- Neutral options labels now use explicit opaque white/gray text rather than inheriting very low native alpha. Disabled controls remain disabled and visibly gray; semantic description/swatch/menu colours retain native alpha. Avoid unchanged colour writes.
- Remove the guide-wide hook from `targeting:UpdateTargetFrame`: native secure-row data/geometry updates require no skin scan. Creation/background/visual hooks still cover styling, deferred in combat.
- Route target background/visual updates only to known target visuals. Known V2 backdrop updates synchronize their own layers; new controls still queue one discovery pass. Existing V2 guide getters no longer queue refreshes, and layout bursts scan only that guide window.
- Avoid duplicate AceConfig Open traversal after FeedGroup already styled the root. Repaint the soft-border cache on theme refresh rather than on each guide update. No shared Lua helpers or unrelated skins were changed.

### Simulated performance evidence

The same mock harness was run against the preceding alpha (`91eb2c8`) and this follow-up:

| Operation | Before | After |
| --- | --- | --- |
| 100 target-list callbacks in one burst | 1 guide scan | 0 guide scans |
| 100 known V2 backdrop callbacks in one burst | 1 guide scan | 0 guide scans |

Additional regression checks verify 100 target-background callbacks perform zero guide scans, allocate no new layers and rewrite/remeasure no unchanged title fonts. Reading the existing V2 window 100 times performs zero scans; 100 layout callbacks coalesce to one V2-window scan. Newly created V2 controls retain one discovery pass. All existing optional/loading/theme/opacity, pooled ownership, native action and combat checks continue passing.

These are traversal/write/allocation counts from mocks. They do not establish actual WoW CPU time, memory consumption, FPS or live first-login font rendering. Full guide reconstruction remains event driven and may still incur RestedXP's own native layout cost.

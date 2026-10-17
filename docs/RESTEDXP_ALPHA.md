# RestedXP refinement

Untagged branch: `skin/restedxp-refinement`, based on stable v1.5.0. Keep it separate from the Gargul branch until release integration. No tag, main update or CurseForge/Wago upload is part of this work.

## Changes

- One flat, public-API background per guide/step/title surface. Retain the main guide header accent; remove repeated accent strips from step cards and auxiliary windows. Preserve native background opacity and hide-background settings.
- Move the legacy guide header out of its native nine-unit overlap with the scrolling list. Keep the compact contained logo, replace the footer cog artwork and retain native dragging, sizing and menu actions.
- Repaint native guide completion checkboxes with compact accent marks, preserving checked/disabled visibility and skip actions. Keep native quest text colours, links, values and guide selection.
- Style the independent Active Items frame/title without traversing or changing secure item buttons. Crop their existing icon textures outside combat; retain attributes, cooldowns, actions and dimensions.
- Style RestedXP AceConfig options after its completed `FeedGroup`/`Open` calls, filtered to its registered application and subpanels. Include selected tabs, headings, buttons, keybindings, checkboxes, dropdowns/pullouts, sliders, numeric inputs and options scrollbars. Guide updates do not repaint options.
- Only addon-owned visual layers enter the public EllesmereUI primitive registry. Snapshot and restore native pooled widget visuals on hide/disable; dropdown pullouts also restore on release/foreign reuse. No native option handlers, values, callbacks, hit rectangles or slider ranges are replaced. Keep colour swatches, semantic description colours and branding native.
- Guide control/scroll bursts repaint their own guide root through the existing queue; item-frame updates repaint only their known visuals. No global AceGUI creation hooks, polling or OnUpdate callbacks.

## Source review

Reviewed RestedXP v4.11.23 (`41fc6f6fc96b4b9cf2bd4c396634afa5e836b9aa`), matching the screenshots: `SettingsPanel.lua`, `GuideWindow.lua`, `ActiveItemFrame.lua`, and its bundled AceConfigDialog/AceGUI widget implementations. No upstream code or assets are bundled or copied.

- https://github.com/RestedXP/RXPGuides/tree/v4.11.23

## Verification

`python3 scripts/package.py` validates Lua syntax, all 20 regression suites, manifests/version consistency and the 38-file, single-folder installation ZIP including MIT LICENSE.

`tests/rxp_options_spec.lua` exercises native actions/returns, dropdown cover/arrow clicks, pooled widget/popup restoration and foreign reuse, unchanged input geometry/values, semantic colours/branding, repeated hook/layer reuse, guide checkbox actions, item-frame separation, live accents, disabled state and combat deferral. In its mock, 25 warm page callbacks create no additional visual layers, rewrite no unchanged fonts and perform no guide hierarchy scans. These are simulated operation counts, not measured WoW CPU, memory or FPS improvements.

Existing collection/features tests continue checking optional targets, both guide generations, session-only themes, preserved settings/return values, secure children, background opacity/visibility and warm scrollbar reuse. The flat guide panels replace the previous textured shells; opacity/theme assertions now exercise that public Panel path.

No actual WoW client is available. Rendering, pixel alignment, first-use timing and live taint behaviour are not established by these tests.

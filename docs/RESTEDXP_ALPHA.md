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

`python3 scripts/package.py` validates Lua syntax, all 20 regression suites, manifests/version consistency and the 39-file, single-folder installation ZIP including MIT LICENSE.

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

## Navigation arrow

- Retain the initial shallow chevron proportions with a new original 256×256 RGBA texture (`Media/NavigationChevronSmooth.tga`), drawn from simple geometry by `scripts/build_navigation_chevron.py`. This avoids magnifying the installed 30-pixel image; no third-party artwork is bundled. The live accent tint remains unchanged. A baked black outline is approximately 0.95 UI units thick at the default arrow size; its black pixels stay black under accent tinting. Its sides and ends are straight with mitered joins, using narrow distance-based edge coverage to soften rotation aliasing without rounding the polygon or blurring its solid interior. It shares the native texture/rotation, adding no UI objects or callbacks.
- Enlarge only the artwork by 10% around the native rotation center, retaining the 22:12 shallow footprint and original 0.1–0.9 texture crop. Preserve the configured frame/hit area and label geometry. A guarded size-change hook retains the multiplier when RestedXP changes its arrow size; no per-frame styling is added.
- Use the public font preference for the existing step/distance label, preserving native text, inline quest colours and configured font size. No background panel or extra arrow frames/textures are created.
- Reapply after native `arrowFrame:UpdateVisuals` and `SetupArrow`, or a full theme refresh; defer combat work through the existing dirty flag. RestedXP retains its direction/rotation, distance, wrong-continent/visibility logic, size, position, dragging and OnUpdate callback. No setter hooks are added to rotation or distance updates.
- Regression checks cover high-resolution texture/crop selection, exact 10% artwork enlargement at native sizes, native setup return values, rotation and text ownership, native scale/drag actions, theme restoration/accent changes, disabled styling and combat deferral. One hundred mocked direction ticks perform no additional texture/font writes, allocate no visuals and queue no skin refresh.

## Button-state regression

- Native button font objects can replace a styled label after AceGUI changes enable/disable state or the pointer presses/enters/leaves it. Track those local events and the widget's `SetDisabled` completion (including an already-enabled button), repainting only the existing label. Enabled labels are opaque light text; disabled labels remain readable gray. Native enabled state, input actions and method return values are unchanged.
- Keep label callbacks separate from the existing hover-layer callback, register them once, and gate by active skin, RestedXP ownership and combat state. Hidden/released or foreign reused widgets retain native colours. Apply the same handling to keybinding and input accept buttons.
- The old fixture did not model native button font-object resets after a click. The expanded regression fails against the preceding alpha, covers a click refreshing neighbouring controls, real enable/disable transitions and repeated `SetDisabled(false)`, hover/press resets alongside the hover visual, native return values, callback reuse, combat deferral, disabled skins and foreign widget reuse. One hundred simulated state updates create no visual objects, perform no guide scans and queue no page refresh.

## Preview/page-rebuild layering follow-up

`Preview Frame Positions` invokes an AceConfig confirmation whose accept/cancel callbacks reopen the app. AceGUI's Open releases the old children, then reacquires and reparents pooled controls. The options painter previously placed each owned background below its native host only at creation. Later hierarchy changes could leave that background above the host's label: changing text colour alone does not repair that ordering.

Recheck the existing background level on each paint and synchronize it after its host's `SetParent`/`SetFrameLevel`, only while active and outside combat. Lower the owned background rather than raising or reparenting native controls. No new objects, polling or whole-page refresh is needed for a hierarchy update; hidden/foreign-reused controls and disabled skins remain inactive.

The regression fixture now models mutable frame levels and pooled reparenting instead of returning a constant level for every frame. It fails against the preceding alpha when the background covers an enabled, correctly coloured label. Ten simulated release/reparent/reopen cycles preserve background order, objects and hook identities. Direct level/parent changes, native geometry, disabled skins and combat-deferred synchronization are checked. These are mocked rendering-order checks; an actual WoW client remains unavailable.

### Rotation edge refinement

The straight chevron uses the same polygon, 22:12 footprint, 10% artwork multiplier and black outline centreline. Its alpha edge and accent-to-black transition now have a narrow smooth coverage band sized for the displayed arrow, replacing antialiasing limited to one texel of the 256-pixel source. Solid interior pixels remain crisp and opaque. The texture stays 256×256 and uses the same native rotation and update path; no new frames, callbacks or per-frame computation.

Synthetic texture samples at multiple sizes/directions were compared locally. They are image resampling previews, not WoW renders. GPU filtering and effective UI scale still affect the final edges; perfect uniformity at every rotation is not established without the client.

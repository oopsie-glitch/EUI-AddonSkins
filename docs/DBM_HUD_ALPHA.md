# DBM HUD alpha

Branch: `skin/dbm-refinement`. This untagged test build does not publish to CurseForge or Wago. TOC/Core versions remain at the stable base, `1.4.2`; identify the build by its branch and commit.

## Included

- Translucent dark timer panels with one-pixel EUI accent outlines and inset, accent-bordered square spell icons.
- Names above thin colored progress strips, separate countdowns and mechanic symbols on the right. Native mechanic colors and urgency updates remain intact.
- Native stack anchors, configured sizes, icon visibility and countdown behavior; rendered rows have a small visual inset.
- Move-mode aura previews with thin dispel-colored edges, EUI text and an accent selection outline.
- Retail AuraUtil color support removes the remaining ornate preview borders. Standalone native dispel glyphs sit inside the top-right corner; colorblind abbreviations remain intact.
- Smaller inset stack counts, subtle text shadows, a tighter one-pixel selection outline and dark neutral timer icon edges.
- Existing accessible live aura regions receive square icons and EUI text on DBM settings/anchor refreshes. Their native dispel borders remain intact.

Timer styling follows creation, pooled reuse, `ApplyStyle` and `SetIcon`. No countdown/OnUpdate hook, aura polling or saved-setting changes are added. Ordinary insecure timers can be styled during combat; aura and broader refreshes defer until combat ends. Existing EUI DBM toggle and theme callbacks apply.

## Scope and limitations

This is the Bars/HUD pass. DBM's options interface and a broader GUI performance review are separate work. Existing interface styling is retained.

Protected, forbidden, masked and secret controls are skipped as appropriate. Retail private aura containers remain Blizzard-managed. Newly pooled live aura buttons are not guaranteed styling until a supported DBM refresh; move-mode previews have direct lifecycle hooks. No global frame-creation interception is used.

Reviewed DBM upstream `master` tree `d1b3a3fca2652a8eac018f6460216f438a1a1d4e`, particularly `DBM-StatusBarTimers/DBT.lua` and `DBM-Core/modules/AuraTracking.lua`. Older builds without aura tracking still receive timer styling through DBT.

## Validation

`python3 scripts/package.py` runs Lua syntax validation, all regression suites and the single-folder archive checks. The HUD fixture covers late/core-only loading, inherited timer methods, pooled reuse, native return values/colors, icon visibility, theme changes, combat, disabled skins and restricted controls. A simulated 1,000 countdown ticks create no additional skin objects, hooks, font writes or hierarchy reads.

These are mocked checks, not in-game profiling or visual verification. No FPS or live-client performance claim is made.

Alpha.2 extends the fixture with Retail-only colors (legacy global absent), contained dispel glyphs, preview object reuse, hidden dispel glyphs, text padding and selection geometry. Timer backgrounds are slightly more opaque for contrast against the world.

Alpha.3 replaces the additive variance gradient with a subtle flat charcoal band. DBM still controls its timing range, width, direction and visibility. Normal and special warnings use the EUI font while retaining native size, colors, positions and animation. Plain DBM inline spell icons are cropped; raid markers, custom crops and secret text are left intact. Tests cover variance geometry/visibility, warning settings refreshes, preserved text and native returns, combat, disabled skins and hook reuse.

Alpha.4 softens fill colors with one cached neutral tint anchored to each native fill texture, below text and mechanic overlays. It follows native color/value changes without a countdown callback. Rendered bars are inset by one pixel at top/bottom while native stack frames and saved size/spacing values remain unchanged. Locked icons follow the inset height; insecure mechanic symbols are smaller, with consistent spacing outside the four-symbol stacked mode. Labels/countdowns have consistent padding that retains DBM's text offsets. Warning text gains a subtle shadow. Regression checks cover normal/large sizes, repeated paint without cumulative shrinking, text offsets, stacked symbols, native color changes and reuse of the tint.

Alpha.5 adopts the panel concept: a dark row with subtle accent edges, a spell icon on the left, a label above a thin native progress strip, a separate larger countdown and native mechanic textures on the right. Four-symbol mode uses a compact two-by-two group. Native row frames, stack anchors, event handlers and saved settings are preserved. Panels adapt to normal/enlarged row sizes; unusually narrow or short rows use a single-line fallback. Opposing progress-strip anchors follow native frame resizing during enlargement without an animation hook. Variance width is scaled to the strip so it retains the same time proportion. Only lifecycle/theme refreshes update the layout; no countdown hook or new polling is added.

Alpha.5 tests additionally cover panel bounds, normal/enlarged typography, opposing width anchors during simulated enlargement, left/right icon visibility, compact fallback, semantic symbol groups, variance proportions and object reuse. Actual client rendering, drag behavior and animation remain unverified by the mocked environment.

Alpha.6 is appearance-only: the top edge retains a faint live accent, while side/bottom edges use a subdued neutral color. Panel backgrounds are neutral charcoal. Each timer size reserves the configured mechanic-symbol capacity, keeping progress strips, labels and countdowns aligned even when individual timers have fewer icons. No changes to native row positioning, spacing, sizes or movement settings are introduced in this pass. Regression checks cover icon-count-independent alignment, preserved native stack anchors and neutral edges across accent changes.

Alpha.7 improves readability: brighter unfilled tracks have thin outlines that show their full length, the cached fill tint is lighter, and panels are brighter and more translucent. Full two-pixel accent borders return around panels, with accent edges around spell icons. Internal horizontal padding and countdown reservations are tighter. Native mechanic symbols appear only on enlarged rows; small timers keep their spell icons and reclaim the right-hand space. Alpha changes preserve native shown states and restore the mechanic textures when enlarged. No saved settings, native stack positioning or row spacing are changed. Regressions cover full track edges, accent refreshes, enlarged-only mechanic symbols and small/large transitions.

Alpha.8 reduces panel borders to one pixel, softens the track outline, increases the countdown's inner right padding, and insets each spell icon so its own accent border no longer touches the panel border. A cached multiplicative vertical shade gives the filled portion subtle depth, below text and track edges. Modern and legacy gradient APIs are supported, with a plain shading fallback; no new countdown callback is installed. Tests cover icon clearance, one-pixel borders, countdown padding, shade reuse and all three gradient paths. The user's left group is DBM's Huge Bars and the right group is Small Bars; enlarged-only mechanic symbols are retained. Native stack anchors, row spacing and settings remain unchanged.

Alpha.9 applies the supplied measured concept proportions to Huge Bars, including the 56.1%-wide track, contained spell icon, fixed countdown and separate mechanic compartment. It retains EUI's selected accent and native DBM formatting/colors/settings. Small Bars keep the compact styling. See [the measured layout](DBM_CONCEPT_LAYOUT.md) for the geometry, scale handling, compact fallback and explicit differences from the approximate screenshot specification.

Install the test ZIP's `EUIAddonSkins` folder in `Interface/AddOns`, replacing the existing folder. DBM and EllesmereUI remain separate requirements. Do not install this alongside another copy of EUI AddonSkins.

Alpha.10 centers Huge Bar names in a fixed upper text band so inline warning artwork does not determine the name's top anchor. Small Bar names are centered above their progress strip rather than against the top edge. Both two-line layouts use a progress-strip height of 25% of configured row height (Huge Bars snap to physical pixels); the Small Bar six-unit ceiling is removed. Native text, inline tags, settings, stack geometry and timer updates remain unchanged. Tests cover text-band alignment, preserved inline text, repeated styling, and strip growth at multiple normal/huge heights. Client glyph rendering remains unverified.

Alpha.11 sizes the Huge Bar mechanic grid by visible symbols rather than configured capacity. A single symbol uses the full 37.5%-of-height target, subject to compartment width, and remains centered even when it occupies a later native slot. Multiple visible symbols share the same compartment without shifting the strip/countdown. Timer panel and spell-icon borders now resolve the Blizzard Skins+ custom accent through the existing accent helper; aura semantic colors and DBM progress colors remain unchanged. Regression coverage includes sparse four-slot layouts, multi-symbol sizing, both timer sizes and live custom/global accent transitions. No countdown hooks or public release tags are added.

Alpha.12 makes timer panel and spell-icon accent edges follow Blizzard Skins+ Show accent bar, including live off/on changes. Huge Bars without visible right-side mechanic indicators reclaim that compartment for wider name/progress regions and a right-aligned countdown. Existing creation/style/icon callbacks restore the compartment when indicators return; compact fallback likewise reserves only actual mechanic symbols. No new polling or countdown work is added. Regression tests cover hidden indicators despite configured capacity, symbol reappearance, unchanged layout for one versus multiple symbols, both timer sizes, retained fill/backgrounds and live border visibility restoration.

Alpha.13 replaces the rectangular timer-panel accent outline with the supplied open-bracket design: full left/bottom edges, a short top-left return and a short bottom-right rise. It reuses the same four textures, keeps spell-icon borders square, and retains Blizzard Skins+ accent color/visibility. Returns scale with the panel height and snap to the existing border pixel grid. No text, fill, timer, stack or preview behavior changes. Tests cover normal/huge geometry, pixel snapping, theme/visibility and object reuse. Retail's default DBM demo uses Blizzard Encounter Timeline; Move me still previews native DBT bars. The default test action is unchanged.

Alpha.14 restores alpha.12's full rectangular timer-panel borders after the bracket experiment. Blizzard Skins+ accent color/visibility, adaptive mechanic compartments, text alignment and proportional progress height remain unchanged.

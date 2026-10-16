# DBM HUD alpha

Branch: `skin/dbm-refinement`. This untagged test build does not publish to CurseForge or Wago. TOC/Core versions remain at the stable base, `1.4.2`; identify the build by its branch and commit.

## Included

- Flat timer fills and dark backgrounds, retaining DBM's mechanic colors and urgency updates.
- A thin EUI accent line below each timer, square icons and EUI fonts.
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

Install the test ZIP's `EUIAddonSkins` folder in `Interface/AddOns`, replacing the existing folder. DBM and EllesmereUI remain separate requirements. Do not install this alongside another copy of EUI AddonSkins.

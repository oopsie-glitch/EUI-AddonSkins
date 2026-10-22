# Pawn alpha

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

Branch: `skin/pawn-initial`. Untagged test build based on v1.5.2.

## Coverage

- Main window, active tabs, scale selector, weights, comparison, gems, options, help and about pages.
- Compact accent checkboxes and radio buttons with native hit areas and exclusive selection unchanged.
- Readable enabled/disabled controls, flat inputs, scrollbars and import/export/name-confirmation dialogs.
- Character, inspect and socketing launchers, including buttons created after loading the collection.
- Existing item images remain visible and square. Native scale colours, rarity/score/difference colours, swatch values, winner/upgrade indicators and selection visibility are preserved.

Enable Pawn's skin in EllesmereUI's Blizzard Skins+ third-party skin list. Install Pawn separately.

## Lifecycle and performance

Reviewed Pawn 2.13.18, upstream tree `a5d4d29bc630d6aea87278770a71164f3a15d563` from https://github.com/VgerMods/Pawn. Original adapter; no external addon code or assets bundled.

Static controls are cached per theme generation. Pawn recreates its native scale/comparison/gem rows on rebuilds and leaves older rows hidden. The adapter styles the current named rows after completed UI functions instead of traversing historical children. Dynamic rows reuse native highlights and fonts; the skin creates no canvases or setter hooks on them. Weight-row font resets are repaired locally while retaining native semantic greys. No scoring, tooltip parsing, bag/equipment events, global factories, recursive scroll callbacks or polling are hooked.

Native shared tooltips, upgrade advisor callouts/arrows, calculation data, item-link/cursor/drag handling, input validation and profile/settings data remain controlled by Pawn. Window and launcher positions/sizes are preserved; only tab-to-tab spacing is adjusted to prevent overlapping flat backgrounds.

## Validation

`python3 scripts/package.py` passes Lua syntax checks, all 23 regression suites, manifest/version/path checks and one-folder ZIP inspection. MIT LICENSE is included; development files are excluded.

Targeted mocked checks cover native actions and returns, check state/hit-area geometry, score/swatch colours, item textures and drag callbacks, import/export text and cancel paths, selection, new/rebuilt rows, historical-row exclusion, lazy buttons, themes, combat deferral and disabled/missing targets.

In 1,000 simulated warm opens/same-tab switches, additional hierarchy reads, font writes, UI objects and hooks are zero. Constructing 300 new native mock rows adds only the 900 objects requested by the fixture's native constructors: zero skin-created objects/hooks. Repeated theme refreshes add no objects/hooks. These operation counts are from mocks, not game CPU/FPS measurements.

No WoW client is available here; in-game appearance and taint safety are not established by automated tests. Runtime version remains 1.5.2 until release integration. ZIP filenames identify alpha builds.

This ZIP excludes other unmerged task alphas. The branch has no release tag and publishes to neither CurseForge nor Wago.

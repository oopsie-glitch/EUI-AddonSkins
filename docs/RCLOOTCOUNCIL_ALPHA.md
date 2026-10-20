# RCLootCouncil alpha

Branch: `skin/rclootcouncil-initial`. Based on stable 1.5.2; no release tag or platform upload. The test ZIP name identifies this alpha; runtime metadata stays at the stable base until release integration.

## Styling

- Matte, soft-edged window bodies and separate accent-coloured title labels.
- Loot responses, voting, session setup, history, version checker and trade windows use the current RCFrame factory.
- Square item icons retain native selection, awarded, corruption and desaturation states.
- Clean buttons, compact checks, inputs, scroll thumbs and owned MSA context menus.
- RCLootCouncil's completed AceConfig pages and import/export windows receive scoped styling. Shared widgets restore their native cosmetics when released; matte fills are same-frame background textures, with isolated glyph layers where needed, instead of persistent skin registrations on pooled buttons.

Minimising, dragging, saved scale/position, row dimensions, item links, response colours, voting rules, notes, trade actions, timeout values and native countdown updates remain controlled by RCLootCouncil. Texture-only dice/pass/note controls keep their recognisable native icons. AceConfig confirmations receive texture-only styling; their native fonts and callbacks are preserved. Shared game tooltips and LibDialog confirmation windows retain their existing styling in this alpha.

## Lifecycle and performance

The integration observes the current UI factory's completed `Embed` step and existing modules' completed window/entry/cell methods. It does not replace constructors, AceGUI factories, callbacks or update scripts. Construction bursts receive one queued final discovery pass; warm windows use child/region counts and theme generations. New table-cell controls are discovered locally, not by repeatedly scanning all windows or player data. Checkbox state setters repaint their own marks only.

There is no polling, OnUpdate skin callback, UIParent scan, forced addon loading or additional dependency. Cosmetic mutations defer during combat; protected/forbidden frames and tooltip contents are skipped. Native returns and action handlers are preserved.

## Source review and checks

Reviewed RCLootCouncil 3.24.0 at `ba8a53ae96903cc5fda083f5d3f497cde3e8f55c`, including UI factories, voting, loot-entry pools, history, trade/session/version windows, options, MSA menus and shared dialog handling. That upstream targets Retail. Compatibility with historical Forever/Classic variants is not established; a missing current UI registry API leaves the adapter inactive.

The older AddOnSkins reference uses different frame names and fixed control counts. This is an original adapter, with no reference code, upstream runtime code, libraries or assets bundled. EllesmereUI and RCLootCouncil remain separately installed dependencies/integrations.

`python3 scripts/package.py` validates Lua syntax, all 23 regression suites, catalogs, TOC paths/version consistency and the one-folder archive with the exact MIT license. RCLootCouncil fixtures cover dynamic loot/vote actions, native timers, semantic colours, minimising, protected frames, pooled options restoration/reacquisition, foreign widgets, menus, themes, combat and disabled skins.

Mock measurements: 100 warm window opens produced zero recursive child reads, added UI objects, font writes or duplicate hooks. 200 checkbox state setter calls produced zero recursive child reads or added UI objects. Repeated completed-page feeds reuse decoration and hooks. These checks do not measure actual WoW CPU/FPS, visual appearance, protected execution or raid behaviour. No in-game validation is claimed.

## Alpha.2 refinements

- Replace child-frame panel fills with theme-coloured, same-frame background textures. AceGUI frame-level repairs can no longer lift these fills over native labels. Loot History table bodies inherit the cohesive main surface instead of separate opaque blocks.
- Reflect actual action-button enable state with readable light labels and muted disabled labels. Native colour/font resets and hover/press/enable transitions repair only the affected active label, with no page scan.
- Target the actual InlineGroup border (`content:GetParent()`), dropdown template regions, native scroll-arrow globals and history export selector. Dropdown backgrounds live behind their original text and fit the clickable cover's bounds. Pullouts are styled only for active RCLootCouncil owners and restore on hide or foreign reuse.
- Improve empty checkbox visibility and provide slim scroll tracks/grips with themed arrows. Keep native thumb dimensions, slider values, arrow actions, meaningful dropdown colours and checkbox states.
- Opt into the existing texture-only AceConfig confirmation helper after completed native widget actions. Confirmation text/fonts, sizing, acceptance/cancellation and keyboard behaviour remain native.
- Clean up on AceGUI Release even for stock Button/InlineGroup widgets without an OnRelease method, including while the skin is disabled. No AceGUI factory or callback is replaced.

Added regressions for the screenshot failures: dark enabled labels, native label resets, frame-level/reparent changes, actual InlineGroup/Dropdown/scrollbar structures, quality colours, thumb hit dimensions, popup ownership/restoration, confirmation routing and disabled release of a widget without OnRelease. One hundred button state changes plus native colour resets perform no recursive child reads or UI-object creation in the mock.

## Alpha.3 refinements

- Give standalone window bodies a restrained two-part centre lift: theme panel colour plus 0.10 at 24% peak opacity, fading to transparent at the outer edges. Titles, settings pages and controls retain their existing tones. The two cached background textures live on minimisable content, with no new frames or update scripts.
- Centre each compact checkbox in the native 24px visual slot and add a six-unit label gap. Local label/image setters and mouse press/release hooks maintain the gap; optional checkbox images, the native right text anchor, click area, values and disabled colours are preserved. Native region anchors restore on pool release.
- Regression fixtures cover the gradient endpoints and reuse, compact-square placement, label/image updates, pressed text, native click state changes, unchanged hit dimensions and restored anchors. All checks remain mocked; no new in-game validation is claimed.

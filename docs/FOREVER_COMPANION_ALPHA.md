# Forever Companion alpha

Branch: `skin/forever-companion-refresh`, based on v1.5.1. Untagged; no CurseForge or Wago publication.

## Appearance

- Reusable charcoal canvases with a soft centre highlight behind window content and native insets. The talent-tree window keeps its illustrated backgrounds; Rotation gets a calmer reading surface.
- Remove window-top accent lines. Use accent feedback on selected Market/Profession modes and options headings, with neutral separators and section bands.
- Map native plain gold labels to near-white, preserving item quality, recipe difficulty, talent ranks, inline spell links, status tags and native disabled/dim states.
- Use flat inset accent checkbox markers without replacing native checked visibility, values or actions. Clean modern/legacy dropdown arrows and bind both shapes to scoped popup styling with a nearly opaque charcoal menu surface.
- Thin square talent frames follow native learned/unlearned border colours. Preserve artwork, desaturation, rank text, tooltip/click handlers and tree positions.

## Refresh and performance

Style completed visible pages synchronously and discover lazy pages through the addon's public open/render methods. Scope virtual-list layout/refresh work to active rows. Retain a coalesced subtree fallback for older list implementations. Combine overlapping queued parent/child requests, cancel queued controls covered by a completed scan, skip warmed hidden subtrees and exclude mouse-disabled decorative layers.

Cache public font outputs while detecting native font resets and invalidating on theme changes. Reuse canvases, talent edges and checkbox markers; unchanged marker styling is skipped. Defer skin scans and factory decoration during combat, preserving factory returns and native callbacks. Existing external launchers, auction footer and side-tab geometry remain supported. No shared runtime code or saved-variable schema changes.

## Verification

`python3 scripts/package.py` passes Lua syntax, all regression suites, manifests, versions, MIT license and the single-folder 39-file runtime ZIP checks.

Mocked regression coverage includes lazy page styling before timers, native factory nil/multiple returns, repeated navigation, semantic colours, native checkbox clicks and replacement markers, both dropdown shapes/owners, font reset recursion, active pooled rows, hidden subtrees, decoration reuse, disabled skins, combat deferral, late factories and overlapping scan requests.

Simulated measurements: 100 warmed page visits cause zero public font writes and no new canvases; 100 active-list layout callbacks cause zero owner-container scans. These are mock results, not in-game CPU/FPS measurements. Actual rendering, frame time and taint behaviour remain unverified.

Sources: the user-supplied ForeverCompanion ZIP, particularly Compat.lua, Options.lua, Bislist.lua, TalentFrame.lua, Rotation.lua, Loot.lua, Professions.lua, Market.lua and Tour.lua. The exact Retail fork source was not supplied. Missing Retail icons are deliberately untouched. No third-party source or assets are bundled.

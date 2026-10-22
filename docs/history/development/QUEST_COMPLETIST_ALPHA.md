# Quest Completist alpha

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

Branch: `skin/questcompletist-initial`. Untagged; no CurseForge or Wago publication. Runtime remains at main's 1.5.2 until release integration.

## Coverage

- Attached Quest Completist 113.9, including its Retail and Camelot manifests.
- Native EUI shell without the portrait, top accent stripe or heavy outline; compact outer bounds around the existing controls. Readable theme fonts, flat category/filter buttons, search field, close controls, slim accent scrollbar and subtle quest-row hover.
- Options filters receive the clean checkbox treatment, preserving their native checked state, disabled state, scripts and hit areas. Options headings remain neutral.
- Owned category dropdown and submenus use the collection's existing owner-scoped menu adapter, including pooled restoration. The dropdown is discovered after native creation; the skin never opens it itself.
- Named quest/map/alert tooltips receive texture-only panel styling. Native fonts, inline icons, progress bars, quest/faction artwork and meaningful completion/status colours remain unchanged. Shared GameTooltip and map pins are not modified.

## Performance and verification

No skin OnUpdate, polling, database iteration, UIParent scan, global frame-creation replacement, forced addon load or full-window recursive scan. The target reuses 16 quest rows; the skin does not hook list/scroll/filter updates. Initial options construction is observed after the native handler. Further option discovery depends on changed child/region counts or a theme refresh.

`python3 scripts/package.py` checks Lua syntax, all 23 regression suites, catalogs/client manifests and the 40-file single-folder archive with the exact MIT license. The new fixture covers native search/clear/filter/menu/scroll/click behaviour, semantic colours/icons, lazy and new controls, missing/protected frames, theme updates, disabled skins and combat deferral. It models HookScript independently of SetScript, as the native options handler replaces its own OnShow callback after construction.

Mock benchmark: 1,000 repeated list/scroll/window/options cycles produce zero additional skin UI objects, hooks, font writes or hierarchy reads after setup. This is simulated, not an in-game CPU/FPS measurement. Actual WoW appearance and taint behaviour are not established by automated tests.

Frame discovery follows Quest Completist's lifecycle. Styling uses EllesmereUI's public skin API and the collection utilities.

Input archive SHA-256: `1c1c486c8fb4c5a143f7e2481cd6e541c8ba84cbe65c36d25764da7bfdbf2796`.


## Alpha.2 refinements

- Keep the public checkbox styling with a fixed 14px square fill/hover and four explicit 1px edges. Suppress only the newly created decorative border host; preserve native children, hit areas, state textures and labels.
- Hide SearchBoxTemplate's redundant Instructions label. Quest Completist's native editable placeholder, query, focus, typing and clear actions remain unchanged.
- Restore a separate, unmasked 32px square copy of the original icon, inset 12px from the left and 10px from the top. The original circular portrait/mask stay hidden.
- Regression checks cover all four edges, native child preservation, duplicate-label suppression after native refresh, typed/placeholder/clear text, icon crop/containment, theme updates and warm reuse.
